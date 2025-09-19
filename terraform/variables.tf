

########################################
# Variables
########################################
variable "region" { default = "us-east-1" }
variable "environment" { default = "prod" }

# DNS / Cert
variable "root_domain" {
  description = "Hosted zone domain (e.g., crayon-poc.org)"
  default     = "crayon-poc.org" # Change this to your domain
}
variable "hosted_zone_id" {
    description = "Route53 public hosted zone ID for root_domain"
    default     = "Z02917741R99X3VO1YC83" # here I'am using crayon-poc.org, use your own.
}
variable "chatbot_subdomain" { default = "chatbot" }

variable "existing_acm_cert_arn" {
  description = "ACM ARN certificate used for the domain (example: *.crayon-poc.org)"
  type        = string
  default = "arn:aws:acm:us-east-1:911167902567:certificate/4659a8bd-12ae-431c-90ad-8c905636a4de"
}

variable "existing_authentication_acm_cert_arn" {
  description = "ACM ARN certificate for Chatbot Authentication (authentication.chatbot.crayon-poc.org)"
  type        = string
  default = "arn:aws:acm:us-east-1:911167902567:certificate/e86ca6e6-3c39-45b0-a97d-4cf616c70ebf"
}

# ECR image
variable "container_image" {
    description = "Full ECR image URI incl. tag"
    default     = "911167902567.dkr.ecr.us-east-1.amazonaws.com/bedrock-rag-chatbot:latest" # Change to your own if needed
}

# Bedrock
variable "bedrock_model_id" { default = "anthropic.claude-3-haiku-20240307-v1:0" }

variable "bedrock_foundation_model" { default = "anthropic.claude-3-haiku-20240307-v1:0" }

variable "bedrock_agent_id" {
    description = "Agent ID to pass to app (if creating below, this is populated via output)"
    default = "AEYAFPF9DI"
}
variable "bedrock_agent_alias_id" {
    description = "Agent alias ID to pass to app (if creating below, this is populated via output)"
    default = "JVOTHTRXEL"
}
variable "bedrock_kb_id" {
    description = "Knowledge Base ID to pass to app (if creating below, this is populated via output)"
    default = "QJWNNZGHO2"
}

# S3 bucket for voice mp3 uploads used by Transcribe jobs in the app
variable "voice_bucket_name" { default = "bedrock-agent-chatbot-voice-text-conversations" }

# ECS capacity
variable "desired_count" { default = 1 }
variable "min_size" { default = 1 }
variable "max_size" { default = 1 }
variable "instance_type" { default = "t3.small" }

# RDS Aurora DB for Bedrock KB
variable "db_username" {
  default = "postgres"
}
variable "db_password" {
  default = "ChangeMe123!" # Change the DB Password once created in AWS Secret Manager
}