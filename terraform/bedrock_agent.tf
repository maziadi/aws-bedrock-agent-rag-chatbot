#######################################
# Bedrock Agent
#######################################
resource "aws_bedrockagent_agent" "this" {
  agent_name                  = "rag-chatbot-agent"
  instruction                 = "You are a helpful assistant for RAG over enterprise docs."
  foundation_model            = var.bedrock_foundation_model
  idle_session_ttl_in_seconds = 300
  agent_resource_role_arn     = aws_iam_role.bedrock_agent_role.arn
}

# Attach KB to the Agent
resource "aws_bedrockagent_agent_knowledge_base_association" "chatbot_agent_kb" {
  agent_id             = aws_bedrockagent_agent.this.id
  knowledge_base_id    = aws_bedrockagent_knowledge_base.this.id
  description          = "Attach KB to chatbot agent"
  knowledge_base_state = "ENABLED"
}

# Bedrock Agent Action Groups (Lambda Function + OpenAPI Schema)

resource "aws_lambda_function" "action_group_lambda" {
  function_name = "chatbot-action-group-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  filename         = "lambda_function_payload.zip"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}
resource "aws_iam_role" "lambda_role" {
  name = "chatbot-action-group-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_bedrockagent_agent_action_group" "chatbot_action_group" {
  action_group_name = "chatbot-action-group"
  agent_id          = aws_bedrockagent_agent.this.id
  agent_version     = "DRAFT"
  skip_resource_in_use_check = true

  action_group_executor {
    lambda = aws_lambda_function.action_group_lambda.arn
  }

  api_schema {
    payload = jsonencode({
    "openapi": "3.0.0",
	 "info": {
        "title": "Bytes Commerce",
        "version": "1.0.0",
        "description": "APIs for managing product inventory"
    },
    "paths": {
        "/GetProductsInventory": {
            "get": {
				"summary": "Gets products inventory",
                "description": "Gets all product inventory",
                "operationId": "getProductsInventory",
                "parameters": [],
                "responses": {
                    "200": {
                        "description": "Returns inventory of all products",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "productId": {
                                                "type": "string",
                                                "description": "Product Id"
                                            },
                                            "productName": {
                                                "type": "string",
                                                "description": "Product Name"
                                            },
                                            "quantity": {
                                                "type": "number",
                                                "description": "Product quantity"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
           },
          "/RestockProduct": {
             "post": {
				        "summary": "Creates a Product Restock Order",
                "description": "Creates a Product Restock Order",
                "operationId": "RestockProduct",
                "requestBody": {
                    "required": true,
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "required": ["productId", "quantity"],
                                "properties": {
                                    "productId": {
                                        "type": "string",
                                        "description": "Product Id"
                                    },
                                    "quantity": {
                                        "type": "number",
                                        "description": "Quantity"
                                    }
                                }
                            }
                        }
                    }
                },
                 "responses": {
                    "200": {
                        "description": "Returns the status of product restock order",
                        "content": {
                            "application/json": {
                                "schema": {
                                   "type": "object",
                                    "properties": {
                                        "status": {
                                            "type": "string",
                                            "description": "Status of the product restock order - Success or Failure"
                                        }
                                }
                            }
                        }
                    }
                 }
              }
            }
	      }
        }
    } 
   )
  }
}