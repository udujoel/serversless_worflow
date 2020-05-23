provider "aws" {
  region  = "us-east-1"
  profile = "personal"
}

terraform {
  backend "s3" {
    bucket  = "udemy-ft-state"
    key     = "keys_rotation.tfstate"
    region  = "us-east-1"
    profile = "personal"
  }
}

data "archive_file" "get_expired_keys_archive" {
  type        = "zip"
  source_file = "../lambda/get_expired_users.py"
  output_path = "../lambda/get_expired_users.zip"
}

resource "aws_lambda_function" "get_expired_users_lambda" {
  filename         = "../lambda/get_expired_users.zip"
  function_name    = "GetExpiredKeys"
  role             = aws_iam_role.get_expired_users_role.arn
  handler          = "get_expired_users.get_expired_keys"
  timeout          = 120
  source_code_hash = data.archive_file.get_expired_keys_archive.output_base64sha256

  runtime = "python3.8"
}

resource "aws_cloudwatch_log_group" "get_expired_users_log_group" {
  name              = "/aws/lambda/GetExpiredKeys"
  retention_in_days = 1
}

resource "aws_iam_role" "get_expired_users_role" {
  name = "Lambda-GetExpiredKeys"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": "131232"
        }
    ]
}
  EOF
}

resource "aws_iam_policy" "get_expired_users_policy" {
  name        = "GetExpiredKeys"
  path        = "/"
  description = "Iam policy for lambda GetExpiredKeys"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogSteam",
                "logs:PutLogsEvent"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "iam:ListUsers",
                "iam:GetUser",
                "iam:ListAccessKeys"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "get_expired_users_attach" {
  role       = aws_iam_role.get_expired_users_role.name
  policy_arn = aws_iam_policy.get_expired_users_policy.arn
}

# Step function
resource "aws_iam_role" "iam_for_sfn" {
  name = "iam_for_sfn"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "step_function_policy" {
  name        = "step_function_policy"
  path        = "/"
  description = "IAM policy for step function"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "${aws_lambda_function.get_expired_users_lambda.arn}"
            ]
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "step_function_attachment" { 
  role = aws_iam_role.iam_for_sfn.name
  policy_arn = aws_iam_policy.step_function_policy.arn
}

resource "aws_sfn_state_machine" "state_machine" {
  name     = "KeysRotation"
  role_arn = aws_iam_role.iam_for_sfn.arn

  definition = templatefile("./function_definition.tmpl", {
    get_epired_keys = aws_lambda_function.get_expired_users_lambda.arn
  })
}
