########################################
# CloudWatch Logs
########################################
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/bedrock-rag-chatbot"
  retention_in_days = 30
}

#############################################
# CloudWatch Logs Metric Filter (App Errors)
#############################################
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "app-errors"
  log_group_name = aws_cloudwatch_log_group.app.name

  # Correction: use " instead of |
  pattern = "\"ERROR\" \"Exception\""

  metric_transformation {
    name      = "AppErrorCount"
    namespace = "BedrockApp"
    value     = "1"
  }
}

#############################################
# CloudWatch Dashboard (Overview)
#############################################
resource "aws_cloudwatch_dashboard" "genai_infra_overview" {
  dashboard_name = "GenAI_Infrastructure_Overview"

  dashboard_body = jsonencode(
    {
    "widgets": [
        {
            "type": "text",
            "x": 0,
            "y": 0,
            "width": 18,
            "height": 2,
            "properties": {
                "markdown": "## GenAI Infrastructure Overview\nThis dashboard shows ECS, ALB, Cognito, RDS, and custom app metrics.",
                "background": "solid"
            }
        },
        # ECS CPUUtilization
        {
            "type": "metric",
            "x": 12,
            "y": 2,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ECS", "CPUUtilization", "ClusterName", "${aws_ecs_cluster.this.name}", "ServiceName", "${aws_ecs_service.chatbot.name}" ]
                ],
                "period": 300,
                "region": "${var.region}",
                "stat": "Average",
                "title": "ECS Service CPU Utilization"
            }
        },
	    # ECS MemoryUtilization
        {
            "type": "metric",
            "x": 12,
            "y": 8,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ECS", "MemoryUtilization", "ClusterName", "${aws_ecs_cluster.this.name}", "ServiceName", "${aws_ecs_service.chatbot.name}" ]
                ],
                "period": 300,
                "region": "${var.region}",
                "stat": "Average",
                "title": "ECS Service Memory Utilization"
            }
        },
        # ALB Request Count
        {
            "type": "metric",
            "x": 6,
            "y": 14,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${aws_lb.this.arn_suffix}" ]
                ],
                "period": 300,
                "region": "${var.region}",
                "stat": "Sum",
                "title": "ALB Request Count"
            }
        },
        # ALB Target Response Time
        {
            "type": "metric",
            "x": 0,
            "y": 14,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${aws_lb_target_group.this.arn_suffix}", "LoadBalancer", "${aws_lb.this.arn_suffix}" ]
                ],
                "period": 300,
                "region": "${var.region}",
                "stat": "Average",
                "title": "ALB Target Response Time"
            }
        },
        # RDS Aurora DB Connections
        {
            "type": "metric",
            "x": 12,
            "y": 14,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", "${aws_rds_cluster.kb_db_aurora.id}" ]
                ],
                "period": 300,
                "region": "${var.region}",
                "stat": "Average",
                "title": "Aurora DB Connections"
            }
        },
        # Cognito Sign-In Successes
        {
            "type": "metric",
            "x": 0,
            "y": 8,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/Cognito", "SignInSuccesses", "UserPool", "${aws_cognito_user_pool.chatbot_authentication.id}", "UserPoolClient", "${aws_cognito_user_pool_client.chatbot_authentication_client.id}" ]
                ],
                "region": "${var.region}",
                "title": "Cognito Sign-In Successes"
            }
        },
        # Cognito Token Refreshes
        {
            "type": "metric",
            "x": 6,
            "y": 8,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Cognito", "TokenRefreshSuccesses", "UserPool", "${aws_cognito_user_pool.chatbot_authentication.id}", "UserPoolClient", "${aws_cognito_user_pool_client.chatbot_authentication_client.id}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Cognito Tokens Refresh",
                "period": 300,
                "stat": "Average"
            }
        },
        # Bedrock Invocations
        {
            "type": "metric",
            "x": 0,
            "y": 2,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/Bedrock", "Invocations" ]
                ],
                "region": "${var.region}",
                "title": "Bedrock Invocations"
            }
        },
        # Bedrock OutputTokenCount
        {
            "type": "metric",
            "x": 6,
            "y": 2,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/Bedrock", "OutputTokenCount" ]
                ],
                "region": "${var.region}",
                "title": "Bedrock OutputTokenCount"
            }
        }
      ]
    }
  )
}