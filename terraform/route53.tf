#########################################
# Route53 record: chatbot.<domain> -> ALB
#########################################
resource "aws_route53_record" "chatbot_dns" {
  zone_id = var.hosted_zone_id
  name    = "${var.chatbot_subdomain}.${var.root_domain}"
  type    = "A"
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}