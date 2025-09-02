#######################################
# RDS Aurora PostgreSQL Serverless v2
#######################################
resource "aws_db_subnet_group" "kb_db_aurora_subnet_group" {
  name       = "kb-db-aurora-subnet-group"
  subnet_ids = data.aws_subnets.default_private_subnets.ids
}

resource "aws_rds_cluster" "kb_db_aurora" {
  cluster_identifier      = "kb-rds-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "15.10" # version >= 15.4 otherwise 'hnsw' method won't work for the vector index creation
  database_name           = "kbdb"
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.kb_db_aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.kb_db_aurora_sg.id]
  storage_encrypted       = true
  skip_final_snapshot     = true
  # Data API v2 activation
  enable_http_endpoint = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }
}

resource "aws_rds_cluster_instance" "kb_db_aurora_instance" {
  identifier         = "kb-rds-aurora-instance"
  cluster_identifier = aws_rds_cluster.kb_db_aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.kb_db_aurora.engine
  engine_version     = aws_rds_cluster.kb_db_aurora.engine_version
}