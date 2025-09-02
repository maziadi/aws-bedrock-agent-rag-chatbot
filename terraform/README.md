# Terraform Deploymnt

![Architecure_overview](images/AWS_Bedrock_chatbot_infrastructure.png)

## 📦 Prerequisites

Before deploying, ensure you have:

1. **Terraform ≥ 1.6.0**
2. **AWS CLI configured** with credentials and access
3. A **Route53 Hosted Zone** for your domain
4. Existing **ACM certificates** for:

   * wildcard `*.your-domain.com` or `chatbot.your-domain.com`
   * `authentication.chatbot.your-domain.com`
5. An **ECR container image** for the chatbot application (see the application section for Dockerization & push to AWS ECR)
6. Do not forget to change the name of the 2 S3 buckets that will be used to store knowledge-base data and users voice inputs

---

## ⚙️ Key Variables

| Variable                               | Default                                          | Description                                            |
| -------------------------------------- | ------------------------------------------------ | ------------------------------------------------------ |
| `region`                               | `us-east-1`                                      | AWS region                                             |
| `environment`                          | `prod`                                           | Environment name                                       |
| `root_domain`                          | `crayon-poc.org`                                 | Root domain for Route53                                |
| `hosted_zone_id`                       | `Z02917741R99X3VO1YC83`                          | Route53 hosted zone ID                                 |
| `chatbot_subdomain`                    | `chatbot`                                        | Subdomain for chatbot                                  |
| `existing_acm_cert_arn`                | (ARN)                                            | ACM cert for chatbot domain                            |
| `existing_authentication_acm_cert_arn` | (ARN)                                            | ACM cert for Cognito auth domain                       |
| `container_image`                      | ECR URI                                          | Chatbot container image                                |
| `bedrock_model_id`                     | `anthropic.claude-v2`                            | Bedrock model for inference                            |
| `bedrock_foundation_model`             | `anthropic.claude-3-haiku`                       | Bedrock foundation model                               |
| `voice_bucket_name`                    | `bedrock-agent-chatbot-voice-text-conversations` | S3 bucket for voice inputs                             |
| `desired_count`                        | `1`                                              | ECS desired task count                                 |
| `instance_type`                        | `t3.small`                                       | EC2 instance type for ECS                              |
| `db_username`                          | `postgres`                                       | Aurora DB username                                     |
| `db_password`                          | `Managed by Secret Manager`                      | Aurora DB password (use Secrets Manager in production) |

## 🛠️ Deployment

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review and customize variables

Update `variables` in `main.tf` or create a `terraform.tfvars` file:

```hcl
region          = "us-east-1"
environment     = "prod"
root_domain     = "mydomain.com"
hosted_zone_id  = "Z1234567890"
container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-chatbot:latest"
```
### 3. Apply the configuration

```bash
terraform apply
```
## 🌐 DNS & Endpoints

* **Chatbot Web App:**
  `https://chatbot.<root_domain>` → routed via ALB → ECS Streamlit app

* **Authentication Domain (Cognito):**
  `https://authentication.chatbot.<root_domain>`

## 🔐 Authentication Flow

1. User accesses `chatbot.<root_domain>`
2. ALB redirects to Cognito authentication
3. Cognito validates login → issues tokens
4. Authenticated traffic forwarded to ECS task

## 📚 Knowledge Base Setup

* Upload documents (to be used for the RAG) to S3 bucket: `crayon-knowledge-base-data` # it is important to change the name of this bucket for your case
* Aurora PostgreSQL cluster stores embeddings
* Vector indexes (`hnsw`) and text search indexes are automatically created
* Bedrock Knowledge Base links S3 + Aurora
* Bedrock Agent is associated with the KB

## ⚡ Bedrock Agent Action Groups

* Includes a Lambda-based action group `lambda_function.py`
* Lambda executes API requests defined by an **OpenAPI schema**
* Example: Inventory management API (`/GetProductsInventory`, `/RestockProduct`)