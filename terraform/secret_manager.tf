#######################################
# Secrets Manager pour DB credentials
#######################################
resource "aws_secretsmanager_secret" "kb_db_aurora_secret" {
  name        = "kb-rds-aurora-credentials"
  description = "Credentials for Aurora Serverless PostgreSQL used by Bedrock KB"
}

resource "aws_secretsmanager_secret_version" "kb_db_aurora_secret_version" {
  secret_id     = aws_secretsmanager_secret.kb_db_aurora_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}