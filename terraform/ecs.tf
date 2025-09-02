########################################
# ECS cluster (EC2 capacity, host mode)
########################################
resource "aws_ecs_cluster" "this" {
  name = "chatbot-cluster-${var.environment}"
}

# ECS-optimized AMI for Amazon Linux 2
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "ecsInstanceProfile-${var.environment}"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "ecs-ec2-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.instance_type
  iam_instance_profile { name = aws_iam_instance_profile.ecs.name }
  vpc_security_group_ids = [aws_security_group.ecs_instances.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
    systemctl enable --now ecs
  EOF
  )
}

resource "aws_autoscaling_group" "ecs" {
  name                      = "ecs-asg-${var.environment}"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_count
  vpc_zone_identifier       = data.aws_subnets.default_public_subnets.ids
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

   tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
   }
}

########################################
# ECS Task Definition (EC2, host network)
########################################
resource "aws_ecs_task_definition" "chatbot" {
  family                   = "bedrock-rag-chatbot"
  network_mode             = "host"
  requires_compatibilities = ["EC2"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true
      portMappings = [
        { containerPort = 8501, hostPort = 8501, protocol = "tcp" }
      ]
      environment = [
        { name = "MODEL_ID", value = var.bedrock_model_id },
        { name = "KNOWLEDGE_BASE_ID", value = coalesce(var.bedrock_kb_id, aws_bedrockagent_knowledge_base.this.id) },
        { name = "AGENT_ID", value = coalesce(var.bedrock_agent_id, aws_bedrockagent_agent.this.id) },
        { name = "AGENT_ALIAS", value = coalesce(var.bedrock_agent_alias_id, "") },
        { name = "S3_BUCKET_NAME", value = var.voice_bucket_name },
        { name = "AWS_REGION", value = var.region }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "app"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8501/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])
}

########################################
# ECS Service (EC2 launch type, ALB target group)
########################################
resource "aws_ecs_service" "chatbot" {
  name            = "chatbot-svc-${var.environment}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.chatbot.arn
  desired_count   = var.desired_count
  launch_type     = "EC2"
  force_new_deployment = true

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "app"
    container_port   = 8501
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [aws_lb_listener.https]
}