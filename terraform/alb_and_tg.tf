###########################################
# ALB + TG (instance mode) + HTTPS listener
###########################################
resource "aws_lb" "this" {
  name               = "chatbot-alb-${var.environment}"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default_public_subnets.ids
  idle_timeout       = 120
}

resource "aws_lb_target_group" "this" {
  name        = "chatbot-tg-${var.environment}"
  port        = 8501
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"   # because ECS task uses network_mode = host.

  health_check {
    path                = "/"
    port                = "8501"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
}

# HTTP Listener with Cognito authentication
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.existing_acm_cert_arn

  # 1 Authentification via Cognito
  default_action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.chatbot_authentication.arn
      user_pool_client_id = aws_cognito_user_pool_client.chatbot_authentication_client.id
      user_pool_domain    = aws_cognito_user_pool_domain.chatbot_authentication_domain.domain

      on_unauthenticated_request = "authenticate"
      scope                      = "openid email phone"
      session_cookie_name        = "AWSELBAuthSession"
    }
  }

  # 2 Redirection to Target Group after authentication
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  # Cognito user pool domain and Route53 record must be ready before modifying the listener
  depends_on = [
    aws_cognito_user_pool_domain.chatbot_authentication_domain,
    aws_route53_record.cognito_authentication_domain
  ]

}
