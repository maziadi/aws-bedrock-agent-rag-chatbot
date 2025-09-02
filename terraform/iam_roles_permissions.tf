#############################
# IAM Roles & Permissions
##############################

### ECS

resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecsInstanceRole-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume.json
}

data "aws_iam_policy_document" "ecs_instance_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ecs" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ecr" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

########################################
# IAM: Task Execution Role & Task Role
########################################
resource "aws_iam_role" "task_execution" {
  name               = "ECSTaskExecutionRole_BedrockPOC"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role" "task_role" {
  name               = "ECSTaskRoleForBedrockPOC"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Execution role: pull image, write logs, get secrets
resource "aws_iam_role_policy_attachment" "exec_logs" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role inline policy (Bedrock, S3, Transcribe, Polly, Logs)
resource "aws_iam_policy" "task_policy" {
  name        = "ECSTaskPolicy_BedrockPOC"
  description = "Permissions for Bedrock agent, S3 voice bucket, Transcribe, Polly"
  policy      = data.aws_iam_policy_document.task_policy_doc.json
}

data "aws_iam_policy_document" "task_policy_doc" {
  statement {
    sid    = "BedrockInvoke"
    effect = "Allow"
    actions = [
      "bedrock:InvokeAgent",
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [
      "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent/${var.bedrock_agent_id != null ? var.bedrock_agent_id : "*"}",
      "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent-alias/${var.bedrock_agent_id != null && var.bedrock_agent_alias_id != null ? var.bedrock_agent_id : "*"}/${var.bedrock_agent_alias_id != null ? var.bedrock_agent_alias_id : "*"}",
      "*" # For InvokeModel on FM endpoints
    ]
  }

  statement {
    sid    = "S3VoiceBucket"
    effect = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.voice_bucket_name}",
      "arn:aws:s3:::${var.voice_bucket_name}/*"
    ]
  }

  statement {
    sid    = "Transcribe"
    effect = "Allow"
    actions = [
      "transcribe:StartTranscriptionJob",
      "transcribe:GetTranscriptionJob",
      "transcribe:ListTranscriptionJobs",
      "transcribe:StartStreamTranscription",
      "transcribe:StartCallAnalyticsStreamTranscription"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Polly"
    effect = "Allow"
    actions = ["polly:SynthesizeSpeech", "polly:DescribeVoices"]
    resources = ["*"]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "task_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}

# IAM Role pour Bedrock Agent
#######################################
resource "aws_iam_role" "bedrock_agent_role" {
  name = "bedrock-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_agent_policy" {
  role = aws_iam_role.bedrock_agent_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = aws_bedrockagent_knowledge_base.this.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.kb_data.arn,
          "${aws_s3_bucket.kb_data.arn}/*"
        ]
      }
    ]
  })
}


#######################################
# IAM Role pour Knowledge Base
#######################################
resource "aws_iam_role" "kb_role" {
  name = "bedrock-knowledge-base-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "kb_role_policy" {
  role = aws_iam_role.kb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "S3ReadKB"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.kb_data.arn,
          "${aws_s3_bucket.kb_data.arn}/*"
        ]
      },
      {
        Sid = "RDSDataAPI"
        Effect = "Allow"
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction"
        ]
        Resource = [
          aws_rds_cluster.kb_db_aurora.arn,
          # eventually the secret ARN if Data API requires it
        ]
      },
      {
        Sid = "RDSDescribe"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances"
        ]
        Resource = [
          aws_rds_cluster.kb_db_aurora.arn
        ]
      },
      {
        Sid = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.kb_db_aurora_secret.arn
        ]
      },
      {
        Sid = "BedrockInvokeEmbed"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v2:*"

        ]
      }
    ]
  })
}


### Lambda & Bedrock
resource "aws_iam_policy" "lambda_policy" {
  name        = "chatbot-lambda-policy"
  description = "Policy pour la fonction Lambda du chatbot"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "logs:*"
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action   = "bedrock:InvokeAgent"
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_permission" "allow_bedrock_invoke_restricted" {
  statement_id  = "AllowBedrockInvokeFromAgent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.action_group_lambda.function_name
  principal     = "bedrock.amazonaws.com"
  # restrict the call to the agent's ARN (or to the action resource's ARN if necessary)
  source_arn    = aws_bedrockagent_agent.this.agent_arn
}