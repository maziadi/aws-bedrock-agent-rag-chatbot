
########################################################
# Cognito: User Pool, App Client, Custom Domain, Route53
########################################################

resource "aws_cognito_user_pool" "chatbot_authentication" {
  name = "chatbot-authentication-${var.environment}"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length    = 8
    require_numbers   = true
    require_symbols   = false
    require_uppercase = false
    require_lowercase = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }
}

# Client App for OIDC (code flow)
resource "aws_cognito_user_pool_client" "chatbot_authentication_client" {
  name         = "chatbot-authentication-client-${var.environment}"
  user_pool_id = aws_cognito_user_pool.chatbot_authentication.id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["openid", "email", "phone"]
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers = ["COGNITO"]

  # ALB will redirect back here
  callback_urls = [
    "https://${var.chatbot_subdomain}.${var.root_domain}/oauth2/idpresponse"
  ]
  logout_urls = [
    "https://${var.chatbot_subdomain}.${var.root_domain}/"
  ]

  prevent_user_existence_errors = "ENABLED"
  generate_secret = true
}

# Custom domain for Cognito: authentication.chatbot.crayon-poc.org
resource "aws_cognito_user_pool_domain" "chatbot_authentication_domain" {
  domain = "authentication.${var.chatbot_subdomain}.${var.root_domain}"
  user_pool_id = aws_cognito_user_pool.chatbot_authentication.id

  # Use existing ACM certificate that covers authentication.chatbot.crayon-poc.org
  certificate_arn = var.existing_authentication_acm_cert_arn
}

# Route53 CNAME -> Cognito's cloudfront domain
resource "aws_route53_record" "cognito_authentication_domain" {
  zone_id = var.hosted_zone_id
  name    = "authentication.${var.chatbot_subdomain}.${var.root_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_cognito_user_pool_domain.chatbot_authentication_domain.cloudfront_distribution]
}