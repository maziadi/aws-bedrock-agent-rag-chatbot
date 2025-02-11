# aws-bedrock-agent-rag-chatbot

This AWS Proof of Concept (PoC) demonstrates the implementation of a Bedrock-powered chatbot agent integrated with a Knowledge Base using Retrieval-Augmented Generation (RAG). The solution leverages **Amazon Bedrock** for natural language understanding and contextual responses while enhancing accuracy through the RAG approach.  

To provide an interactive interface, the PoC utilizes **Streamlit**, enabling a lightweight, locally hosted web UI for seamless interaction with the Bedrock Agent and its Knowledge Base. This UI allows users to input queries, retrieve relevant information, and receive AI-driven responses in real time.  

Before running the application, ensure that all necessary dependencies are installed, including:  
- **AWS credentials and IAM roles** with appropriate permissions  
- Required **Python modules** and dependencies (as specified in `requirements.txt`)  
- Proper configuration of the **Knowledge Base** within AWS Bedrock  

Once the setup is complete, launch the Streamlit application with the following command:  

```bash
python -m streamlit run script.py
```  

This will initialize the chatbot interface (http://localhost:8501), allowing users to test and interact with the Bedrock-powered system efficiently.

## AWS RAG/KnowledgeBase

![RAG in Action](images/rag_diagram.png)

AWS Retrieval-Augmented Generation (RAG) enhances large language model (LLM) responses by integrating external knowledge retrieval. The process consists of two main workflows: Data Ingestion and Text Generation. In the Data Ingestion Workflow, raw data from various sources is chunked, processed through an embeddings model, and stored in a vector database for efficient retrieval. During the Text Generation Workflow, when a user inputs a query, the system generates an embedding, performs semantic search to fetch relevant context, and augments the prompt before passing it to the LLM. This approach ensures responses are more accurate, contextual, and grounded in the latest knowledge base, making AWS RAG ideal for enterprise chatbot agents, knowledge management, and intelligent search applications.

## Knowledge Base data

script: generate_kb_data.py

The ECommerce company has a list of 30 products. Each product has Product Id, Product Name, Type, Color, Weight, Size, Company, Price

The file products_inventory.json contains the inventory of some products. This inventory will be used for the Bedrock Agent Action Groups (/GetProductsInventory) inside the related lambda function.

## Bedrock Agent orhcestration

![Bedrock Agent orchestration](images/agent_orchestration.gif)

Agents orchestrate and analyze the task and break it down into the correct logical sequence using the FM’s reasoning abilities. Agents automatically call the necessary APIs to transact with the company systems and processes to fulfill the request, determining along the way if they can proceed or if they need to gather more information.