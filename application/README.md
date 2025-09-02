# Application & Dockerization

This repository contains a Python-based chatbot application that leverages AWS Bedrock services, AWS Transcribe, AWS Polly, and several other tools to provide a rich, interactive conversational experience. Users can interact with the chatbot via text or voice. The chatbot can retrieve contextual information from the knowledge-base, reason using a Bedrock agent, and even convert responses to speech for an immersive experience.

## The application components

The script: `application.py`
### Features

- **Multi-modal Interaction:** Users can communicate via text or voice.
- **Voice Transcription:** Convert recorded audio to text using AWS Transcribe.
- **Text-to-Speech (TTS):** Synthesize speech from text responses using AWS Polly.
- **Knowledge Base Integration:** Retrieve relevant context from a knowledge base.
- **Bedrock Agent:** Optionally invoke an AWS Bedrock agent for enhanced reasoning.
- **Rate Limiting:** Protects API calls from exceeding defined thresholds.
- **Streamlit Interface:** A user-friendly web UI for interactive conversations.

### Application Overview

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

### Code analysis

1. **Frontend (Streamlit UI)**

   * Displays chat history (human + AI messages).
   * Accepts both **typed text** and **recorded audio**.
   * Provides playback of AI responses via Polly.

2. **Backend Logic**

   * **Knowledge Base Querying**: Retrieves context-relevant documents from Bedrock Knowledge Base.
   * **Agent Invocation**: Calls Bedrock Agent for advanced reasoning if enabled.
   * **LLM Response Generation**: Falls back to LLM with prompt + retrieved context.

3. **AWS Services**

   * **Amazon Bedrock**: Core LLM + Agents.
   * **Amazon S3**: Temporary storage of audio recordings.
   * **Amazon Transcribe**: Converts speech to text.
   * **Amazon Polly**: Converts text responses into natural speech.

#### ⚙️ Configuration

The app relies on environment variables (`.env` file or ECS task environment):

| Variable            | Description                                         | Default Value                                    |
| ------------------- | --------------------------------------------------- | ------------------------------------------------ |
| `S3_BUCKET_NAME`    | S3 bucket for storing audio files for transcription | `bedrock-agent-chatbot-voice-text-conversations` |
| `MODEL_ID`          | Bedrock model ID (Claude v2 by default)             | `anthropic.claude-v2`                            |
| `KNOWLEDGE_BASE_ID` | Bedrock Knowledge Base ID                           | *empty*                                          |
| `AGENT_ID`          | Bedrock Agent ID                                    | *empty*                                          |
| `AGENT_ALIAS`       | Bedrock Agent Alias                                 | *empty*                                          |
| `AWS_REGION`        | AWS region                                          | `us-east-1`                                      |

---

#### 📜 Main Components

##### 1. **Rate-Limiting Decorator**

```python
@sleep_and_retry
@limits(calls=100, period=60)
```

Prevents exceeding API call limits when invoking Bedrock Agents.

---

##### 2. **Knowledge Base Query**

```python
def query_knowledge_base(question): ...
```

* Retrieves relevant context from Bedrock Knowledge Base.
* Returns best-matching document snippet or fallback message.

---

##### 3. **Agent Invocation**

```python
def invoke_bedrock_agent(question): ...
```

* Calls Bedrock Agent with conversation context.
* Streams agent’s output chunks into a single response string.

---

##### 4. **Custom Chatbot Logic**

```python
def my_chatbot(language, freeform_text, use_agent, conversation_history): ...
```

* If **Agent mode**: forwards request to Bedrock Agent.
* Else:

  * Queries Knowledge Base.
  * Builds a LangChain prompt template with conversation context.
  * Generates response with Bedrock LLM.

---

##### 5. **Speech-to-Text**

```python
def transcribe_audio(audio_file_path): ...
```

* Uploads audio to S3.
* Runs Amazon Transcribe job.
* Fetches transcription result from output URI.

---

##### 6. **Text-to-Speech**

```python
def text_to_speech(text, language): ...
```

* Uses Amazon Polly.
* Chooses **Joanna** (English) or **Celine** (French).
* Returns a temporary `.mp3` file path.

---

##### 7. **Streamlit Session State**

* `conversation_history`: Stores past chat turns.
* `voice_input`: Holds transcription from recorded audio.
* `last_ai_response`: Stores last AI response (for playback).
* `is_listening`: Ensures only one playback at a time.

---

##### 8. **Streamlit UI Flow**

* Sidebar: language selection + toggle Bedrock Agent.
* Chat messages: renders history with "Listen" buttons.
* Input:

  * Voice recording (transcribed with Transcribe).
  * Text input field.
* AI Processing:

  * Response generated via `my_chatbot()`.
  * Stored in conversation history.
* Output:

  * Displayed in chat.
  * Optional playback via Polly.

---

## Dockerization & tests

* Once the AWS Knowledge-Base & the Agent are set-up, the chatbot application can be tested locally in Docker.
* Below are the required files (docker-compose, Dockerfile, .env file)
* Make sure to update the .env file with your AWS Secrets having access to the required services like bedrock, polly, transcribe, s3, etc)
* command: ```docker-compose up --build```
* Connect after that to http://localhost:8501

docker-compose.yml:
```yaml
version: "3.9"

services:
  bedrock-rag-chatbot:
    build: .
    container_name: bedrock-rag-chatbot
    ports:
      - "8501:8501"
    env_file:
      - .env
    volumes:
      - .:/application
```

Dockerfile
```yaml
# Use a lightweight Python image
FROM python:3.11-slim

# Prevent Python from writing .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create a working directory
WORKDIR /app

# Install minimal system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the code
COPY . .

# Expose the Streamlit port
EXPOSE 8501

# Startup command
CMD ["streamlit", "run", "application.py", "--server.port=8501", "--server.address=0.0.0.0"]
```
.env :
```hcl
AWS_REGION="us-east-1"
S3_BUCKET_NAME="bedrock-agent-chatbot-voice-text-conversations" #change the name with the name of your bucket
MODEL_ID="anthropic.claude-v2"
KNOWLEDGE_BASE_ID="YOUR_KNOWLEDGE_BASE_ID"
AGENT_ID="YOUR_AGENT_ID"
AGENT_ALIAS="YOUR_AGENT_ALIAS"
AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
AWS_SESSION_TOKEN="YOUR_AWS_SESSION_TOKEN"
```
## Pushing Docker image to AWS ECR

```bash
1. Create your ECR Repository
2. aws ecr get-login-password --region YOUR_REGION | docker login --username AWS --password-stdin \
YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
3. docker build -t bedrock-rag-chatbot .
4. docker tag bedrock-rag-chatbot:latest YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/bedrock-rag-chatbot:latest
5. docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/bedrock-rag-chatbot:latest
```