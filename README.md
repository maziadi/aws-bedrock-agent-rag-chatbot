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

This will initialize the chatbot interface, allowing users to test and interact with the Bedrock-powered system efficiently.

## AWS RAG/KnowledgeBase

![RAG in Action](images/rag_diagram.png)

AWS Retrieval-Augmented Generation (RAG) enhances large language model (LLM) responses by integrating external knowledge retrieval. The process consists of two main workflows: Data Ingestion and Text Generation. In the Data Ingestion Workflow, raw data from various sources is chunked, processed through an embeddings model, and stored in a vector database for efficient retrieval. During the Text Generation Workflow, when a user inputs a query, the system generates an embedding, performs semantic search to fetch relevant context, and augments the prompt before passing it to the LLM. This approach ensures responses are more accurate, contextual, and grounded in the latest knowledge base, making AWS RAG ideal for enterprise chatbot agents, knowledge management, and intelligent search applications.

## Knowledge Base data

script: generate_kb_data.py

Product Id ,Product Name ,Type        ,Color  ,Weight ,Size   ,Company       ,Price
         1 ,Laptop       ,Accessories ,Purple ,  0.71 ,Medium ,Innovatech    , 637.46
         2 ,Keyboard     ,Peripheral  ,Silver ,  4.85 ,Large  ,TechCorp      ,1040.42
         3 ,Smartphone   ,Accessories ,Blue   ,  4.46 ,Large  ,Innovatech    ,1560.65
         4 ,Mouse        ,Gadget      ,Blue   ,  2.73 ,Small  ,GizmoWorks    , 431.01
         5 ,Headphones   ,Peripheral  ,Yellow ,  3.24 ,Small  ,TechCorp      , 445.21
         6 ,Headphones   ,Electronics ,Black  ,  1.88 ,Small  ,Innovatech    , 918.11
         7 ,Camera       ,Peripheral  ,Silver ,  0.62 ,Medium ,GizmoWorks    ,  71.01
         8 ,Smartwatch   ,Peripheral  ,Silver ,  2.3  ,Small  ,FutureGadgets , 365.63
         9 ,Smartphone   ,Gadget      ,Red    ,  2.18 ,Medium ,TechCorp      ,1259.68
        10 ,Monitor      ,Peripheral  ,Blue   ,  4.76 ,Small  ,ElectroWorld  , 678.29
        11 ,Headphones   ,Electronics ,Red    ,  3.87 ,Medium ,ElectroWorld  ,  91.08
        12 ,Camera       ,Gadget      ,Purple ,  0.55 ,Medium ,GizmoWorks    , 141.94
        13 ,Keyboard     ,Gadget      ,Green  ,  1.14 ,Small  ,ElectroWorld  ,1214.66
        14 ,Keyboard     ,Electronics ,Red    ,  4.5  ,Medium ,TechCorp      ,1986.38
        15 ,Tablet       ,Accessories ,Red    ,  3.91 ,Large  ,TechCorp      ,1424.65
        16 ,Mouse        ,Gadget      ,White  ,  4.48 ,Small  ,TechCorp      , 101.15
        17 ,Smartwatch   ,Peripheral  ,Green  ,  1.17 ,Large  ,Innovatech    ,1604.75
        18 ,Keyboard     ,Electronics ,Green  ,  2.75 ,Medium ,TechCorp      ,1883.91
        19 ,Smartphone   ,Peripheral  ,White  ,  1.06 ,Medium ,FutureGadgets ,1753.38
        20 ,Tablet       ,Electronics ,Green  ,  1.26 ,Small  ,GizmoWorks    , 175.14
        21 ,Smartphone   ,Accessories ,White  ,  2.23 ,Small  ,ElectroWorld  ,1087.54
        22 ,Camera       ,Accessories ,Silver ,  4.94 ,Medium ,GizmoWorks    , 565.4
        23 ,Smartphone   ,Electronics ,Yellow ,  1.68 ,Small  ,FutureGadgets ,1583.0
        24 ,Tablet       ,Peripheral  ,Silver ,  2.51 ,Small  ,Innovatech    , 736.29
        25 ,Smartphone   ,Electronics ,Blue   ,  4.82 ,Large  ,Innovatech    ,1767.96
        26 ,Tablet       ,Gadget      ,Purple ,  3.18 ,Medium ,ElectroWorld  , 193.94
        27 ,Monitor      ,Peripheral  ,Blue   ,  0.94 ,Large  ,GizmoWorks    ,1989.49
        28 ,Laptop       ,Gadget      ,Pink   ,  0.72 ,Medium ,TechCorp      ,1924.99
        29 ,Smartphone   ,Peripheral  ,Purple ,  4.2  ,Small  ,ElectroWorld  ,  59.31
        30 ,Keyboard     ,Electronics ,Purple ,  4.62 ,Medium ,TechCorp      , 631.51

Inventory

response_data = [
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
		] 

## Bedrock Agent orhcestration

![Bedrock Agent orchestration](images/agent_orhcestration.gif)

Agents orchestrate and analyze the task and break it down into the correct logical sequence using the FM’s reasoning abilities. Agents automatically call the necessary APIs to transact with the company systems and processes to fulfill the request, determining along the way if they can proceed or if they need to gather more information.