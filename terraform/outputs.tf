########################################
# Outputs
########################################
output "alb_dns_name" { value = aws_lb.this.dns_name }
output "chatbot_url" { value = "https://${var.chatbot_subdomain}.${var.root_domain}" }
output "ecs_cluster_name" { value = aws_ecs_cluster.this.name }
output "ecs_service_name" { value = aws_ecs_service.chatbot.name }
output "ecs_task_definition_arn" { value = aws_ecs_task_definition.chatbot.arn }
output "bedrock_agent_id" { value = aws_bedrockagent_agent.this.id }
output "bedrock_knowledge_base_id" { value = aws_bedrockagent_knowledge_base.this.id }
output "rds_cluster_endpoint" { value = aws_rds_cluster.kb_db_aurora.endpoint }
output "rds_cluster_id" { value = aws_rds_cluster.kb_db_aurora.id }
output "s3_voice_bucket_name" { value = aws_s3_bucket.voice.bucket }