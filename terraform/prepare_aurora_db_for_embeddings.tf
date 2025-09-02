# --- Create vector extension ---
resource "null_resource" "create_vector_extension" {
  provisioner "local-exec" {
    command = <<EOT
      aws rds-data execute-statement --region ${var.region} --resource-arn ${aws_rds_cluster.kb_db_aurora.arn} --secret-arn ${aws_secretsmanager_secret.kb_db_aurora_secret.arn} --database ${aws_rds_cluster.kb_db_aurora.database_name} --sql "CREATE EXTENSION IF NOT EXISTS vector;"
    EOT
  }

  depends_on = [
    aws_rds_cluster.kb_db_aurora,
    aws_secretsmanager_secret_version.kb_db_aurora_secret_version
  ]
}
# --- Create embeddings table ---
resource "null_resource" "create_embeddings_table_rds" {
  provisioner "local-exec" {
    command = <<EOT
      aws rds-data execute-statement --region ${var.region} --resource-arn ${aws_rds_cluster.kb_db_aurora.arn} --secret-arn ${aws_secretsmanager_secret.kb_db_aurora_secret.arn} --database ${aws_rds_cluster.kb_db_aurora.database_name} --sql "CREATE TABLE IF NOT EXISTS embeddings (id UUID PRIMARY KEY, text TEXT, metadata JSONB, vector vector(1024));"
    EOT
  }

  depends_on = [
    aws_rds_cluster.kb_db_aurora,
    aws_secretsmanager_secret_version.kb_db_aurora_secret_version
  ]
}

# Create indexes
resource "null_resource" "create_text_index_on_embeddings_table" {
  provisioner "local-exec" {
    command = <<EOT
      aws rds-data execute-statement --region ${var.region} --resource-arn ${aws_rds_cluster.kb_db_aurora.arn} --secret-arn ${aws_secretsmanager_secret.kb_db_aurora_secret.arn} --database ${aws_rds_cluster.kb_db_aurora.database_name} --sql "CREATE INDEX ON embeddings USING gin (to_tsvector('simple', text));"
    EOT
  }

  depends_on = [
    aws_rds_cluster.kb_db_aurora,
    aws_secretsmanager_secret_version.kb_db_aurora_secret_version
  ]
}

resource "null_resource" "create_vector_index_on_embeddings_table" {
  provisioner "local-exec" {
    command = <<EOT
      aws rds-data execute-statement --region ${var.region} --resource-arn ${aws_rds_cluster.kb_db_aurora.arn} --secret-arn ${aws_secretsmanager_secret.kb_db_aurora_secret.arn} --database ${aws_rds_cluster.kb_db_aurora.database_name} --sql "CREATE INDEX ON embeddings USING hnsw (vector vector_cosine_ops);"
    EOT
  }

  depends_on = [
    aws_rds_cluster.kb_db_aurora,
    aws_secretsmanager_secret_version.kb_db_aurora_secret_version
  ]
}