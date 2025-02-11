from langchain.chains import LLMChain
from langchain.llms.bedrock import Bedrock
from langchain.prompts import PromptTemplate
import boto3
import os
import streamlit as st

# Ensure AWS credentials are correctly set up
session = boto3.Session(profile_name="maziadi")
bedrock_client = session.client("bedrock-runtime", region_name="us-east-1")
kb_client = session.client("bedrock-agent-runtime", region_name="us-east-1")  # Knowledge Base Client

# Bedrock Model & Knowledge Base Config
MODEL_ID = "anthropic.claude-v2"
KNOWLEDGE_BASE_ID = "RR9ZKRQOR1"
AGENT_ID = "your-agent-id"  # not required if only retrieve but required for Reasonning

# Initialize LLM
llm = Bedrock(
    model_id=MODEL_ID,
    client=bedrock_client,
    model_kwargs={"max_tokens_to_sample": 2000, "temperature": 0.9}
)

# Function to Query Bedrock Knowledge Base
def query_knowledge_base(language, question):
    """
    Queries the AWS Bedrock Knowledge Base for a relevant response.
    """
    print(f"Querying Knowledge Base ID: {KNOWLEDGE_BASE_ID} with question: {question}")

    response = kb_client.retrieve(
        knowledgeBaseId=KNOWLEDGE_BASE_ID,
        retrievalQuery={"text": question}  # ✅ Convert question to a dictionary
    )

    if response.get("retrievalResults"):
        knowledge_data = response["retrievalResults"][0]["content"]
    else:
        knowledge_data = "No relevant information found in the knowledge base."

    return knowledge_data

# Function to Generate Response Using Bedrock LLM + Knowledge Base
def my_chatbot(language, freeform_text):
    # First, query the knowledge base
    knowledge_base_response = query_knowledge_base(language, freeform_text)

    # Now, pass the knowledge to the LLM for response generation
    prompt = PromptTemplate(
        input_variables=["language", "freeform_text", "knowledge_base"],
        template="You are a chatbot. You are in {language}.\n\n"
                 "The user has asked: {freeform_text}\n\n"
                 "Here is relevant information from the knowledge base:\n\n"
                 "{knowledge_base}"
    )

    bedrock_chain = LLMChain(llm=llm, prompt=prompt)

    response = bedrock_chain.run({'language': language, 'freeform_text': freeform_text, 'knowledge_base': knowledge_base_response})
    return response

# Streamlit UI
st.title("Bedrock Knowledge Base Chatbot")

# Sidebar for User Input
language = st.sidebar.selectbox("Select Language", ["english", "french"])
freeform_text = st.sidebar.text_area(label="What is your question?", max_chars=200)

# Display chatbot response
if freeform_text:
    with st.chat_message("user"):
        st.write(freeform_text)
    
    response = my_chatbot(language, freeform_text)

    with st.chat_message("assistant"):
        st.write(response)
