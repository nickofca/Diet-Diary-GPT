provider "aws" {
  region = var.region
}

#########################
# DynamoDB Tables Setup
#########################

resource "aws_dynamodb_table" "diet_goals" {
  name         = "${var.namespace}-DietGoals"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user"
  range_key    = "date"

  attribute {
    name = "user"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  tags = {
    Name = "${var.namespace}-DietGoals"
  }
}

resource "aws_dynamodb_table" "meal_logs" {
  name         = "${var.namespace}-MealLogs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user"
  range_key    = "date"

  attribute {
    name = "user"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  tags = {
    Name = "${var.namespace}-MealLogs"
  }
}

resource "aws_dynamodb_table" "valid_users" {
  name         = "${var.namespace}-ValidUsers"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user"

  attribute {
    name = "user"
    type = "S"
  }

  tags = {
    Name = "${var.namespace}-ValidUsers"
  }
}

##############################
# IAM Role and Policy for Lambda
##############################

resource "aws_iam_role" "lambda_role" {
  name = "${var.namespace}-diet_tracker_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.namespace}-diet_tracker_lambda_policy"
  description = "Policy for Lambda to access DynamoDB and CloudWatch logs"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ],
        Effect   = "Allow",
        Resource = [
          aws_dynamodb_table.diet_goals.arn,
          aws_dynamodb_table.meal_logs.arn,
          aws_dynamodb_table.valid_users.arn
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

#########################
# Lambda Function Setup
#########################

resource "aws_lambda_function" "diet_tracker_lambda" {
  filename         = "lambda.zip"
  function_name    = "${var.namespace}-diet_tracker_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("lambda.zip")
  timeout          = 10

  environment {
    variables = {
      GOALS_TABLE_NAME       = aws_dynamodb_table.diet_goals.name
      MEALS_TABLE_NAME       = aws_dynamodb_table.meal_logs.name
      VALID_USERS_TABLE_NAME = aws_dynamodb_table.valid_users.name
    }
  }
}

#################################
# API Gateway REST API Setup
#################################

resource "aws_api_gateway_rest_api" "diet_tracker_api" {
  name        = "${var.namespace}-DietTrackerAPI"
  description = "API for diet tracking application"
}

resource "aws_api_gateway_resource" "set_goals_resource" {
  rest_api_id = aws_api_gateway_rest_api.diet_tracker_api.id
  parent_id   = aws_api_gateway_rest_api.diet_tracker_api.root_resource_id
  path_part   = "set-goals"
}

resource "aws_api_gateway_resource" "log_meal_resource" {
  rest_api_id = aws_api_gateway_rest_api.diet_tracker_api.id
  parent_id   = aws_api_gateway_rest_api.diet_tracker_api.root_resource_id
  path_part   = "log-meal"
}

resource "aws_api_gateway_resource" "track_macros_resource" {
  rest_api_id = aws_api_gateway_rest_api.diet_tracker_api.id
  parent_id   = aws_api_gateway_rest_api.diet_tracker_api.root_resource_id
  path_part   = "track-macros"
}

# /set-goals (POST)
resource "aws_api_gateway_method" "set_goals_post" {
  rest_api_id   = aws_api_gateway_rest_api.diet_tracker_api.id
  resource_id   = aws_api_gateway_resource.set_goals_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "set_goals_integration" {
  rest_api_id             = aws_api_gateway_rest_api.diet_tracker_api.id
  resource_id             = aws_api_gateway_resource.set_goals_resource.id
  http_method             = aws_api_gateway_method.set_goals_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.diet_tracker_lambda.invoke_arn
}

# /log-meal (POST)
resource "aws_api_gateway_method" "log_meal_post" {
  rest_api_id   = aws_api_gateway_rest_api.diet_tracker_api.id
  resource_id   = aws_api_gateway_resource.log_meal_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "log_meal_integration" {
  rest_api_id             = aws_api_gateway_rest_api.diet_tracker_api.id
  resource_id             = aws_api_gateway_resource.log_meal_resource.id
  http_method             = aws_api_gateway_method.log_meal_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.diet_tracker_lambda.invoke_arn
}

# /track-macros (GET)
resource "aws_api_gateway_method" "track_macros_get" {
  rest_api_id   = aws_api_gateway_rest_api.diet_tracker_api.id
  resource_id   = aws_api_gateway_resource.track_macros_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "track_macros_integration" {
  rest_api_id             = aws_api_gateway_rest_api.diet_tracker_api.id
  resource_id             = aws_api_gateway_resource.track_macros_resource.id
  http_method             = aws_api_gateway_method.track_macros_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.diet_tracker_lambda.invoke_arn
}

#########################
# API Gateway Deployment
#########################

resource "aws_api_gateway_deployment" "diet_tracker_deployment" {
  depends_on = [
    aws_api_gateway_integration.set_goals_integration,
    aws_api_gateway_integration.log_meal_integration,
    aws_api_gateway_integration.track_macros_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.diet_tracker_api.id
  stage_name  = "prod"
}

#################################
# Lambda Permission for API Gateway
#################################

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.diet_tracker_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.diet_tracker_api.execution_arn}/*/*"
}

#########################
# Generate the Support Bash Script from Template
#########################

resource "local_file" "add_valid_user_script" {
  filename        = "${path.module}/add_valid_user.sh"
  file_permission = "0755"
  content         = templatefile("${path.module}/templates/add_valid_user.tftpl", {
    valid_users_table = aws_dynamodb_table.valid_users.name
  })
}