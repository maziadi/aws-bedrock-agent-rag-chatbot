#######################################
# Knowledge Base
#######################################
resource "aws_bedrockagent_knowledge_base" "this" {
  name        = "rag-kb"
  description = "Knowledge Base for RAG"
  role_arn    = aws_iam_role.kb_role.arn

  storage_configuration {
    type = "RDS"
    rds_configuration {
      resource_arn          = aws_rds_cluster.kb_db_aurora.arn
      database_name         = "kbdb"
      table_name            = "embeddings"
      credentials_secret_arn = aws_secretsmanager_secret.kb_db_aurora_secret.arn

      field_mapping {
        primary_key_field = "id"
        metadata_field    = "metadata"
        text_field        = "text"
        vector_field      = "vector"
      }
    }
  }

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v2:0"
    }
  }
}

# Knowledge base Data source S3 
resource "aws_bedrockagent_data_source" "chatbot_kb_s3" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  name              = "s3-datasource"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.kb_data.arn
    }
  }
}