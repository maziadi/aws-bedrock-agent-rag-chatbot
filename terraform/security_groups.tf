
########################################
# Security Groups
########################################

# ALB
resource "aws_security_group" "alb" {
  name        = "alb-sg-${var.environment}"
  description = "ALB SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "HTTPS"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# ECS
resource "aws_security_group" "ecs_instances" {
  name        = "ecs-ec2-sg-${var.environment}"
  description = "ECS container instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 8501
    to_port         = 8501
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "From ALB to Streamlit"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


# Aurora serverless
resource "aws_security_group" "kb_db_aurora_sg" {
  name   = "kb-db-aurora-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ limit to your private network
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}