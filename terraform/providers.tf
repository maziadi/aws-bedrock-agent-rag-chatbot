########################################
# Providers & Default Tags
########################################
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "bedrock-rag-chatbot"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}