# aws-bedrock-agent-rag-chatbot

This AWS Proof of Concept (PoC) demonstrates the implementation of a Bedrock-powered chatbot agent integrated with a Knowledge Base using Retrieval-Augmented Generation (RAG). The solution leverages **Amazon Bedrock** for natural language understanding and contextual responses while enhancing accuracy through the RAG approach.  

To provide an interactive interface, the PoC utilizes **Streamlit**, enabling a lightweight, locally hosted web UI for seamless interaction with the Bedrock Agent and its Knowledge Base. This UI allows users to input queries, retrieve relevant information, and receive AI-driven responses in real time.  

Before running the application, ensure that all necessary dependencies are installed, including:  
- **AWS credentials and IAM roles** with appropriate permissions  
- Required **Python modules** and dependencies (as specified in `requirements.txt`)  
- Proper configuration of the **Knowledge Base** within AWS Bedrock: [AWS documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-create.html)
- Proper configuration of **Bedrock Agent** with alias, previous knoweldge base and group actions (see related lambda function and openapi schema) [AWS documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-create.html) 

Once the setup is complete, launch the Streamlit application with the following command:  

```bash
python -m streamlit run aws_poc_interact_with_Agent_UI_enhancement_voice_chatting.py
```  

This will initialize the chatbot interface (http://localhost:8501), allowing users to test and interact with the Bedrock-powered system efficiently.

## AWS RAG/KnowledgeBase

![RAG in Action](images/rag_diagram.png)

AWS Retrieval-Augmented Generation (RAG) enhances large language model (LLM) responses by integrating external knowledge retrieval. The process consists of two main workflows: Data Ingestion and Text Generation. In the Data Ingestion Workflow, raw data from various sources is chunked, processed through an embeddings model, and stored in a vector database for efficient retrieval. During the Text Generation Workflow, when a user inputs a query, the system generates an embedding, performs semantic search to fetch relevant context, and augments the prompt before passing it to the LLM. This approach ensures responses are more accurate, contextual, and grounded in the latest knowledge base, making AWS RAG ideal for enterprise chatbot agents, knowledge management, and intelligent search applications.

## Knowledge Base data

script: `generate_kb_data.py`

The ECommerce company has a list of 30 products. Each product has Product Id, Product Name, Type, Color, Weight, Size, Company, Price

```

Product Id ,Product Name ,Type        ,Color  ,Weight ,Size   ,Company       ,Price
1          ,Laptop       ,Accessories ,Purple ,  0.71 ,Medium ,Innovatech    , 637.46
2	   ,Keyboard     ,Peripheral  ,Silver ,  4.85 ,Large  ,TechCorp      ,1040.42
3	   ,Smartphone   ,Accessories ,Blue   ,  4.46 ,Large  ,Innovatech    ,1560.65
4	   ,Mouse        ,Gadget      ,Blue   ,  2.73 ,Small  ,GizmoWorks    , 431.01
5	   ,Headphones   ,Peripheral  ,Yellow ,  3.24 ,Small  ,TechCorp      , 445.21
6	   ,Headphones   ,Electronics ,Black  ,  1.88 ,Small  ,Innovatech    , 918.11
7	   ,Camera       ,Peripheral  ,Silver ,  0.62 ,Medium ,GizmoWorks    ,  71.01
8 	   ,Smartwatch   ,Peripheral  ,Silver ,  2.3  ,Small  ,FutureGadgets , 365.63
9 	   ,Smartphone   ,Gadget      ,Red    ,  2.18 ,Medium ,TechCorp      ,1259.68
10 	   ,Monitor      ,Peripheral  ,Blue   ,  4.76 ,Small  ,ElectroWorld  , 678.29
11 	   ,Headphones   ,Electronics ,Red    ,  3.87 ,Medium ,ElectroWorld  ,  91.08
12 	   ,Camera       ,Gadget      ,Purple ,  0.55 ,Medium ,GizmoWorks    , 141.94
13 	   ,Keyboard     ,Gadget      ,Green  ,  1.14 ,Small  ,ElectroWorld  ,1214.66
14 	   ,Keyboard     ,Electronics ,Red    ,  4.5  ,Medium ,TechCorp      ,1986.38
15 	   ,Tablet       ,Accessories ,Red    ,  3.91 ,Large  ,TechCorp      ,1424.65
16 	   ,Mouse        ,Gadget      ,White  ,  4.48 ,Small  ,TechCorp      , 101.15
17 	   ,Smartwatch   ,Peripheral  ,Green  ,  1.17 ,Large  ,Innovatech    ,1604.75
18 	   ,Keyboard     ,Electronics ,Green  ,  2.75 ,Medium ,TechCorp      ,1883.91
19 	   ,Smartphone   ,Peripheral  ,White  ,  1.06 ,Medium ,FutureGadgets ,1753.38
20 	   ,Tablet       ,Electronics ,Green  ,  1.26 ,Small  ,GizmoWorks    , 175.14
21 	   ,Smartphone   ,Accessories ,White  ,  2.23 ,Small  ,ElectroWorld  ,1087.54
22 	   ,Camera       ,Accessories ,Silver ,  4.94 ,Medium ,GizmoWorks    , 565.4
23 	   ,Smartphone   ,Electronics ,Yellow ,  1.68 ,Small  ,FutureGadgets ,1583.0
24 	   ,Tablet       ,Peripheral  ,Silver ,  2.51 ,Small  ,Innovatech    , 736.29
25 	   ,Smartphone   ,Electronics ,Blue   ,  4.82 ,Large  ,Innovatech    ,1767.96
26 	   ,Tablet       ,Gadget      ,Purple ,  3.18 ,Medium ,ElectroWorld  , 193.94
27 	   ,Monitor      ,Peripheral  ,Blue   ,  0.94 ,Large  ,GizmoWorks    ,1989.49
28 	   ,Laptop       ,Gadget      ,Pink   ,  0.72 ,Medium ,TechCorp      ,1924.99
29 	   ,Smartphone   ,Peripheral  ,Purple ,  4.2  ,Small  ,ElectroWorld  ,  59.31
30 	   ,Keyboard     ,Electronics ,Purple ,  4.62 ,Medium ,TechCorp      , 631.51
```

The file `products_inventory.json` contains the inventory of some products. This inventory will be used for the Bedrock Agent Action Groups (`/GetProductsInventory`) inside the related lambda function.

```
                        {"Product Id": "1", "Product Name": "Laptop", "Quantity": 297},
			{"Product Id": "2", "Product Name": "Keyboard", "Quantity": 0},
			{"Product Id": "3", "Product Name": "Smartphone", "Quantity": 463},
			{"Product Id": "4", "Product Name": "Mouse", "Quantity": 904},
			{"Product Id": "5", "Product Name": "Headphones", "Quantity": 440},
			{"Product Id": "6", "Product Name": "Headphones", "Quantity": 608},
			{"Product Id": "7", "Product Name": "Camera", "Quantity": 0},
			{"Product Id": "8", "Product Name": "Smartwatch", "Quantity": 791},
			{"Product Id": "9", "Product Name": "Smartphone", "Quantity": 384},
			{"Product Id": "10", "Product Name": "Monitor", "Quantity": 707},
			{"Product Id": "11", "Product Name": "Headphones", "Quantity": 971},
			{"Product Id": "12", "Product Name": "Camera", "Quantity": 172},
			{"Product Id": "13", "Product Name": "Keyboard", "Quantity": 936},
			{"Product Id": "14", "Product Name": "Keyboard", "Quantity": 732},
			{"Product Id": "15", "Product Name": "Tablet", "Quantity": 0},
			{"Product Id": "16", "Product Name": "Mouse", "Quantity": 642},
			{"Product Id": "17", "Product Name": "Smartwatch", "Quantity": 31},
			{"Product Id": "18", "Product Name": "Keyboard    ", "Quantity": 674},
			{"Product Id": "19", "Product Name": "Smartphone", "Quantity": 203},
			{"Product Id": "20", "Product Name": "Tablet", "Quantity": 698}
```

## Bedrock Agent orchestration

![Bedrock Agent orchestration](images/agent_orchestration.gif)

Agents orchestrate and analyze the task and break it down into the correct logical sequence using the FM’s reasoning abilities. Agents automatically call the necessary APIs to transact with the company systems and processes to fulfill the request, determining along the way if they can proceed or if they need to gather more information.

# Bedrock AI Chatbot with Knowledge Base, Agent, and Voice Interaction

This repository contains a Python-based chatbot application that leverages AWS Bedrock services, AWS Transcribe, AWS Polly, and several other tools to provide a rich, interactive conversational experience. Users can interact with the chatbot via text or voice. The chatbot can retrieve contextual information from a knowledge base, reason using a Bedrock agent, and even convert responses to speech for an immersive experience.

```bash
python -m streamlit run scripts/aws_poc_interact_with_Agent_UI_enhancement_voice_chatting.py
```  
---

## Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Setup and Configuration](#setup-and-configuration)
- [Code Structure and Explanation](#code-structure-and-explanation)
  - [AWS Clients and Configuration](#aws-clients-and-configuration)
  - [Rate Limiting](#rate-limiting)
  - [Knowledge Base and Agent Integration](#knowledge-base-and-agent-integration)
  - [Chatbot Logic](#chatbot-logic)
  - [Audio Processing](#audio-processing)
  - [Streamlit User Interface](#streamlit-user-interface)
- [Running the Application](#running-the-application)
- [Demo: Screenshots](#demo-screenshots)
- [License](#license)

---

## Features

- **Multi-modal Interaction:** Users can communicate via text or voice.
- **Voice Transcription:** Convert recorded audio to text using AWS Transcribe.
- **Text-to-Speech (TTS):** Synthesize speech from text responses using AWS Polly.
- **Knowledge Base Integration:** Retrieve relevant context from a knowledge base.
- **Bedrock Agent:** Optionally invoke an AWS Bedrock agent for enhanced reasoning.
- **Rate Limiting:** Protects API calls from exceeding defined thresholds.
- **Streamlit Interface:** A user-friendly web UI for interactive conversations.

---

## Architecture Overview

The application is built on top of several AWS services and Python libraries:

- **AWS Bedrock Services:**  
  - **Bedrock LLM:** For generating responses with a language model.
  - **Bedrock Agent & Knowledge Base:** For reasoning and retrieval of contextual information.
- **AWS Transcribe:** To convert user voice input into text.
- **AWS Polly:** To generate audio (speech) from text responses.
- **S3:** For storing audio files required by AWS Transcribe.
- **Streamlit:** For building the interactive web UI.
- **Langchain:** To orchestrate prompt templates and chains for LLM interaction.
- **Rate Limit Decorators:** To prevent API throttling.

---

## Prerequisites

Before running the application, ensure you have:

- An AWS account with proper permissions for Bedrock, Transcribe, Polly, and S3.
- AWS credentials configured (e.g., using an AWS CLI profile).
- The necessary Python packages installed:
  - `boto3`
  - `streamlit`
  - `langchain`
  - `ratelimit`
  - `audio_recorder_streamlit`
  - `sounddevice`
  - `soundfile`
- A pre-configured S3 bucket for storing audio files.
- Bedrock model, knowledge base, and agent identifiers as provided by AWS.

---

## Setup and Configuration

1. **AWS Credentials:**  
   Ensure your AWS credentials are set up correctly. The script initializes a session using:
   ```python
   session = boto3.Session(profile_name="maziadi")
   ```
   Replace `"maziadi"` with your AWS profile name if different.

2. **S3 Bucket:**  
   Update the S3 bucket name if necessary:
   ```python
   S3_BUCKET_NAME = "maziadi-bedrock-agent-chatbot-voice-text-conversations"
   ```

3. **Bedrock Model & Agent IDs:**  
   Set the appropriate IDs for your Bedrock model, knowledge base, and agent:
   ```python
   MODEL_ID = "anthropic.claude-v2"
   KNOWLEDGE_BASE_ID = "RR9ZKRQOR1"
   AGENT_ID = "VURA79GVOW"
   AGENT_ALIAS = "KPEQSPGXPP"
   ```

4. **Rate Limiting Configuration:**  
   The application limits API calls to avoid throttling:
   ```python
   CALLS_PER_MINUTE = 100
   PERIOD = 60
   ```

---

## Code Structure and Explanation

The script is divided into several logical sections. Below is a breakdown of the key components:

### AWS Clients and Configuration

- **Session and Clients Initialization:**
  ```python
  session = boto3.Session(profile_name="maziadi")
  bedrock_client = session.client("bedrock-runtime", region_name="us-east-1")
  kbs_client = session.client("bedrock-agent-runtime", region_name="us-east-1")
  agent_client = session.client("bedrock-agent-runtime", region_name="us-east-1")
  transcribe_client = session.client("transcribe", region_name="us-east-1")
  polly_client = session.client("polly", region_name="us-east-1")
  s3_client = session.client("s3", region_name="us-east-1")
  ```
  These lines set up the required AWS clients for Bedrock, transcription, TTS, and S3 operations.

- **Bedrock LLM Initialization:**
  ```python
  llm = Bedrock(
      model_id=MODEL_ID,
      client=bedrock_client,
      model_kwargs={"max_tokens_to_sample": 100, "temperature": 0.9}
  )
  ```
  The LLM is configured with model parameters such as token limit and temperature.

### Rate Limiting

- **Decorator for API Calls:**
  ```python
  @sleep_and_retry
  @limits(calls=CALLS_PER_MINUTE, period=PERIOD)
  def rate_limited_invoke_agent(agent_client, **kwargs):
      return agent_client.invoke_agent(**kwargs)
  ```
  This ensures that the number of requests made to the Bedrock agent does not exceed the specified limit.

### Knowledge Base and Agent Integration

- **Querying the Knowledge Base:**
  ```python
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
  ```
  This function queries the configured knowledge base and returns the most relevant piece of content.

- **Invoking the Bedrock Agent:**
  ```python
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
  ```
  This function invokes the Bedrock agent (with rate limiting) and assembles the response from data chunks.

### Chatbot Logic

- **Main Chatbot Function:**
  ```python
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
  ```
  This function determines whether to use the Bedrock agent directly or to generate a response based on both a knowledge base lookup and a conversational context. It leverages a prompt template to structure the conversation.

### Audio Processing

- **Transcribing Audio:**
  ```python
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
  ```
  This function uploads the audio file to S3, starts an AWS Transcribe job, waits for its completion, and then retrieves the transcription.

- **Text-to-Speech Conversion:**
  ```python
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
  ```
  This function uses AWS Polly to synthesize speech from text. It chooses the voice based on the selected language and writes the audio output to a temporary file.

### Streamlit User Interface

- **Building the UI:**
  The application uses Streamlit to create an interactive web interface:
  - **Title and Sidebar Options:**  
    The UI allows users to select their language and whether to use the Bedrock agent for reasoning.
  - **Chat Display:**  
    The conversation history is displayed with messages from the human and AI. Each AI response includes an audio playback option.
  - **Voice Input:**  
    The UI provides an audio recorder (via `audio_recorder_streamlit`) that allows users to speak their input. The recorded audio is transcribed using AWS Transcribe.
  - **Text Input Fallback:**  
    If no audio is recorded, a text input box is provided.
  - **Conversation Management:**  
    Users can clear the conversation history from the sidebar.

The Streamlit code ties together all the functionalities:
```python
st.title("Bedrock AI Chatbot with Knowledge Base, Agent, and Voice Interaction")
# ... [UI code that manages conversation history, displays messages, handles audio recording and playback, etc.] ...
```

---

## Running the Application

1. **Install Dependencies:**
   Ensure all required packages are installed. For example:
   ```bash
   pip install boto3 streamlit langchain ratelimit audio_recorder_streamlit sounddevice soundfile
   ```

2. **Configure AWS Credentials:**  
   Verify that your AWS credentials (and the required permissions) are correctly set up.

3. **Run the Streamlit App:**
   ```bash
   python -m streamlit run aws-bedrock-agent-rag-chatbot/scripts/aws_poc_interact_with_Agent_UI_enhancement_voice_chatting.py
   ```
   
4. **Interact with the Chatbot:**  
   Open the provided URL (http://localhost:8501) in your browser, and start interacting with the chatbot either via text or by recording your voice.

---

## Demo: Screenshots

### Agent RAG - Knowledge-Base

![Agent Thinking](images/agent_thinking.png)

![Agent RAG](images/Agent_RAG_answer.png)

### Voice chatting - Agent Action Groups: Action 1: /GetProductsInventory

![Recording](images/recording.png)

![Agent action_groups and Voice chatting](images/chatbot_agent_RAG_Voice_chatting.png)

### Agent Action Groups: Action 2: /RestockProduct

![Agent action_groups_restock_product](images/agent_restock_product.png)

---

## License

This project is licensed under the [MIT License](LICENSE.md).

---

Feel free to explore, modify, and extend the functionalities as needed. Contributions and suggestions are welcome!

Happy Coding!
