import time
import os
import tempfile
import json
import urllib.request
from ratelimit import limits, sleep_and_retry
from langchain_community.chat_models.bedrock import BedrockChat
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
import boto3
import streamlit as st
from audio_recorder_streamlit import audio_recorder
from io import BytesIO
# ---------------------------------------------
# Configuration (via .env or ECS Task env vars)
# ---------------------------------------------
S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME", "bedrock-agent-chatbot-voice-text-conversations")
MODEL_ID = os.getenv("MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0")
KNOWLEDGE_BASE_ID = os.getenv("KNOWLEDGE_BASE_ID", "")
AGENT_ID = os.getenv("AGENT_ID", "")
AGENT_ALIAS = os.getenv("AGENT_ALIAS", "")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

# ------------
# AWS Clients
# ------------
session = boto3.Session(region_name=AWS_REGION)
bedrock_client = session.client("bedrock-runtime")
kbs_client = session.client("bedrock-agent-runtime")
agent_client = session.client("bedrock-agent-runtime")
transcribe_client = session.client("transcribe")
polly_client = session.client("polly")
s3_client = session.client("s3")

# Rate limiting configuration
CALLS_PER_MINUTE = 100
PERIOD = 60

# Initialize LLM
llm = BedrockChat(
    client=bedrock_client,
    model_id=MODEL_ID,
    model_kwargs={
        "max_tokens": 100,
        "temperature": 0.9
    }
)

@sleep_and_retry
@limits(calls=CALLS_PER_MINUTE, period=PERIOD)
def rate_limited_invoke_agent(agent_client, **kwargs):
    return agent_client.invoke_agent(**kwargs)

def query_knowledge_base(question):
    try:
        response = kbs_client.retrieve(
            knowledgeBaseId=KNOWLEDGE_BASE_ID,
            retrievalQuery={"text": question}
        )
        
        if response.get("retrievalResults"):
            return response["retrievalResults"][0]["content"]
        else:
            return "No relevant information found in the knowledge base."
    except Exception as e:
        return f"Error retrieving knowledge: {str(e)}"

def invoke_bedrock_agent(question):
    try:
        response = rate_limited_invoke_agent(
            agent_client,
            agentAliasId=AGENT_ALIAS,
            agentId=AGENT_ID,
            sessionId="user-session-1",
            inputText=question,
            enableTrace=True,
            endSession=False
        )
        
        output = ""
        for event in response.get("completion", []):
            if "chunk" in event:
                output += event["chunk"].get("bytes", b"").decode()
        return output
    except Exception as e:
        return f"Error invoking agent: {str(e)}"

def my_chatbot(language, freeform_text, use_agent, conversation_history):
    if use_agent:
        return invoke_bedrock_agent(freeform_text)
    
    knowledge_base_response = query_knowledge_base(freeform_text)
    
    context = "\n".join([f"Human: {h}\nAI: {a}" for h, a in conversation_history])
    
    prompt = PromptTemplate(
        input_variables=["language", "context", "freeform_text", "knowledge_base"],
        template="""You are a chatbot. You are in {language}.

Previous conversation:
{context}

The user asked: {freeform_text}

Here is relevant information:

{knowledge_base}

Provide a concise and relevant response:"""
    )
    
    bedrock_chain = LLMChain(llm=llm, prompt=prompt)
    return bedrock_chain.run({
        'language': language, 
        'context': context,
        'freeform_text': freeform_text, 
        'knowledge_base': knowledge_base_response
    })

def transcribe_audio(audio_file_path):
    job_name = f"transcribe_job_{int(time.time())}"
    s3_audio_uri = f"s3://{S3_BUCKET_NAME}/{os.path.basename(audio_file_path)}"
    
    # Upload audio file to S3
    s3_client.upload_file(audio_file_path, S3_BUCKET_NAME, os.path.basename(audio_file_path))
    
    # Start transcription job
    transcribe_client.start_transcription_job(
        TranscriptionJobName=job_name,
        Media={'MediaFileUri': s3_audio_uri},
        MediaFormat='mp3',
        LanguageCode='en-US'
    )
    
    # Wait for the transcription job to complete
    while True:
        status = transcribe_client.get_transcription_job(TranscriptionJobName=job_name)
        if status['TranscriptionJob']['TranscriptionJobStatus'] in ['COMPLETED', 'FAILED']:
            break
        time.sleep(1)
    
    if status['TranscriptionJob']['TranscriptionJobStatus'] == 'COMPLETED':
        result = transcribe_client.get_transcription_job(TranscriptionJobName=job_name)
        transcript_uri = result['TranscriptionJob']['Transcript']['TranscriptFileUri']
        
        # Download the transcript directly from the provided URI
        with urllib.request.urlopen(transcript_uri) as response:
            transcript_json = json.loads(response.read())
            transcript = transcript_json['results']['transcripts'][0]['transcript']
        
        return transcript
    else:
        return "Transcription failed"

def text_to_speech(text, language):
    response = polly_client.synthesize_speech(
        Text=text,
        OutputFormat='mp3',
        VoiceId='Joanna' if language == 'english' else 'Celine'
    )
    
    if "AudioStream" in response:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as temp_audio:
            temp_audio.write(response['AudioStream'].read())
            temp_audio_path = temp_audio.name
        
        return temp_audio_path
    else:
        return None

# ----------------------
# Initialisation Session
# ----------------------
if "conversation_history" not in st.session_state:
    st.session_state.conversation_history = []

if "voice_input" not in st.session_state:
    st.session_state.voice_input = None

if "last_ai_response" not in st.session_state:
    st.session_state.last_ai_response = None

if "is_listening" not in st.session_state:
    st.session_state.is_listening = False

# -------------
# STREAMLIT UI
# -------------
st.title("Bedrock AI Chatbot (Agent + RAG)")

# Sidebar
st.sidebar.image("crayon-logo.png", width=300)
language = st.sidebar.selectbox("Select Language", ["english", "french"])
use_agent = st.sidebar.checkbox("Use Bedrock Agent for Reasoning")

# History
for idx, (human, ai) in enumerate(st.session_state.conversation_history):
    with st.chat_message("human"):
        st.write(human)

    with st.chat_message("ai"):
        st.write(ai)
        # Listen button disabled if currently listening
        if st.button("🔊 Listen", key=f"listen_{idx}", disabled=st.session_state.is_listening):
            st.session_state.is_listening = True
            audio_bytes = text_to_speech(ai, language)
            st.audio(audio_bytes, format="audio/mp3", autoplay=True)
            st.session_state.is_listening = False

# ----------------------
# VOICE INPUT
# ----------------------
st.write("🎙️ Record your voice:")
audio_bytes = audio_recorder(
    text="",
    recording_color="#e74c3c",
    neutral_color="#10a37f",
    icon_size="42px"
)

if audio_bytes:
    with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as temp_audio:
        temp_audio.write(audio_bytes)
        temp_audio_path = temp_audio.name

    transcript = transcribe_audio(temp_audio_path)
    if transcript != "Transcription failed":
        st.write(f"📝 Transcription: {transcript}")
        # Send automatically
        st.session_state.voice_input = transcript
    else:
        st.error("❌ Failed to transcribe audio. Please try again.")

# ----------------------
# TEXT INPUT
# ----------------------
text_input = st.chat_input("Type your message here...", disabled=st.session_state.is_listening)

# Fusion des inputs
user_input = None
if text_input:
    user_input = text_input
elif st.session_state.voice_input:
    user_input = st.session_state.voice_input
    st.session_state.voice_input = None

# ----------------------
# Processing User Request
# ----------------------
if user_input:
    st.session_state.conversation_history.append((user_input, ""))

    with st.chat_message("human"):
        st.write(user_input)

    with st.chat_message("ai"):
        with st.spinner("Thinking..."):
            ai_response = my_chatbot(language, user_input, use_agent, st.session_state.conversation_history)
            st.write(ai_response)

        st.session_state.conversation_history[-1] = (user_input, ai_response)
        st.session_state.last_ai_response = ai_response

# -------------------------------
# Listen button for last response
# -------------------------------
if st.session_state.last_ai_response:
    if  st.button("🔊 Listen", key="listen_last", disabled=st.session_state.is_listening):
        st.session_state.is_listening = True
        audio_bytes = text_to_speech(st.session_state.last_ai_response, language)
        st.audio(audio_bytes, format="audio/mp3", autoplay=True)
        st.session_state.is_listening = False

# -------------------
# Additional Options
# -------------------
if  st.sidebar.button("Clear Conversation"):
    st.session_state.conversation_history = []
    st.session_state.last_ai_response = None
    st.rerun()