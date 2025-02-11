import time
from ratelimit import limits, sleep_and_retry
from langchain_community.llms import Bedrock
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
import boto3
import streamlit as st

# Ensure AWS credentials are correctly set up
session = boto3.Session(profile_name="maziadi")
bedrock_client = session.client("bedrock-runtime", region_name="us-east-1")
kbs_client = session.client("bedrock-agent-runtime", region_name="us-east-1")
agent_client = session.client("bedrock-agent-runtime", region_name="us-east-1")

# Bedrock Model & Knowledge Base Config
MODEL_ID = "anthropic.claude-v2"
#MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1"

KNOWLEDGE_BASE_ID = "RR9ZKRQOR1"
AGENT_ID = "VURA79GVOW"
AGENT_ALIAS = "KPEQSPGXPP"

# Rate limiting configuration
CALLS_PER_MINUTE = 1000000
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

# Streamlit UI
st.title("Bedrock AI Chatbot with Knowledge Base & Agent")

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

# User input
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
    
    # Update conversation history with AI response
    st.session_state.conversation_history[-1] = (user_input, ai_response)

# Add a rate limit information display
st.sidebar.info(f"Note: Requests are limited to {CALLS_PER_MINUTE} per minute to avoid throttling.")

# Option to clear conversation history
if st.sidebar.button("Clear Conversation"):
    st.session_state.conversation_history = []
    st.rerun()