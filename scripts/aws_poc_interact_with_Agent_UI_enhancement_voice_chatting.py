import time
import os
import tempfile
import json
import urllib.request
from ratelimit import limits, sleep_and_retry
from langchain_community.llms import Bedrock
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
import boto3
import streamlit as st
from audio_recorder_streamlit import audio_recorder
import sounddevice as sd
import soundfile as sf

# Ensure AWS credentials are correctly set up
session = boto3.Session(profile_name="maziadi")
bedrock_client = session.client("bedrock-runtime", region_name="us-east-1")
kbs_client = session.client("bedrock-agent-runtime", region_name="us-east-1")
agent_client = session.client("bedrock-agent-runtime", region_name="us-east-1")
transcribe_client = session.client("transcribe", region_name="us-east-1")
polly_client = session.client("polly", region_name="us-east-1")
s3_client = session.client("s3", region_name="us-east-1")

# S3 bucket configuration
S3_BUCKET_NAME = "maziadi-bedrock-agent-chatbot-voice-text-conversations"

# Bedrock Model & Knowledge Base Config
MODEL_ID = "anthropic.claude-v2"
KNOWLEDGE_BASE_ID = "RR9ZKRQOR1"
AGENT_ID = "VURA79GVOW"
AGENT_ALIAS = "KPEQSPGXPP"

# Rate limiting configuration
CALLS_PER_MINUTE = 100
PERIOD = 60

# Initialize LLM
llm = Bedrock(
    model_id=MODEL_ID,
    client=bedrock_client,
    model_kwargs={"max_tokens_to_sample": 100, "temperature": 0.9}
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
        time.sleep(5)
    
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

# Streamlit UI
st.title("Bedrock AI Chatbot with Knowledge Base, Agent, and Voice Interaction")

# Initialize session state
if 'conversation_history' not in st.session_state:
    st.session_state.conversation_history = []

# Sidebar for User Input
language = st.sidebar.selectbox("Select Language", ["english", "french"])
use_agent = st.sidebar.checkbox("Use Bedrock Agent for Reasoning")

# Chat interface
st.write("Chat with the AI:")

# Display conversation history
for human, ai in st.session_state.conversation_history:
    with st.chat_message("human"):
        st.write(human)
    with st.chat_message("ai"):
        st.write(ai)
        
        # Add a button to play the AI response
        audio_file = text_to_speech(ai, language)
        if audio_file:
            st.audio(audio_file, format="audio/mp3")

# Voice input
st.write("Record your voice:")
audio_bytes = audio_recorder()
if audio_bytes:
    # Save audio to a temporary file
    with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as temp_audio:
        temp_audio.write(audio_bytes)
        temp_audio_path = temp_audio.name
    
    # Transcribe the audio
    transcript = transcribe_audio(temp_audio_path)
    
    if transcript != "Transcription failed":
        st.write(f"Transcription: {transcript}")
        user_input = transcript
    else:
        st.error("Failed to transcribe audio. Please try again.")
        user_input = None
else:
    # Text input as fallback
    user_input = st.chat_input("Type your message here...")

if user_input:
    # Add user message to conversation history
    st.session_state.conversation_history.append((user_input, ""))
    
    with st.chat_message("human"):
        st.write(user_input)

    with st.chat_message("ai"):
        with st.spinner('Thinking...'):
            ai_response = my_chatbot(language, user_input, use_agent, st.session_state.conversation_history)
            st.write(ai_response)
            
            # Convert AI response to speech
            audio_file = text_to_speech(ai_response, language)
            if audio_file:
                st.audio(audio_file, format="audio/mp3")
    
    # Update conversation history with AI response
    st.session_state.conversation_history[-1] = (user_input, ai_response)

# Add a rate limit information display
st.sidebar.info(f"Note: Requests are limited to {CALLS_PER_MINUTE} per minute to avoid throttling.")

# Option to clear conversation history
if st.sidebar.button("Clear Conversation"):
    st.session_state.conversation_history = []
    st.rerun()