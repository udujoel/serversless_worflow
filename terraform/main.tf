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

# General resource
resource "aws_sns_topic" "admin_sns_topic" {
  name = "admin_notification"
}

# Lambda GetExpiredKeys
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
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "iam:ListUsers",
                "iam:GetUser",
                "iam:ListAccessKeys",
                "iam:ListUserTags"
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

# Lambda PoceedExpiredKeys
data "archive_file" "process_expired_keys_archive" {
  type        = "zip"
  source_file = "../lambda/process_expired_keys.py"
  output_path = "../lambda/process_expired_keys.zip"
}

resource "aws_lambda_function" "process_expired_keys_lambda" {
  filename         = "../lambda/process_expired_keys.zip"
  function_name    = "PoceedExpiredKeys"
  role             = aws_iam_role.process_expired_keys_role.arn
  handler          = "process_expired_keys.lambda_handler"
  timeout          = 120
  source_code_hash = data.archive_file.process_expired_keys_archive.output_base64sha256

  runtime = "python3.8"
}

resource "aws_cloudwatch_log_group" "process_expired_keys_log_group" {
  name              = "/aws/lambda/PoceedExpiredKeys"
  retention_in_days = 1
}

resource "aws_iam_role" "process_expired_keys_role" {
  name = "Lambda-PoceedExpiredKeys"

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

resource "aws_iam_policy" "process_expired_keys_policy" {
  name        = "PoceedExpiredKeys"
  path        = "/"
  description = "Iam policy for lambda PoceedExpiredKeys"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "iam:UpdateAccessKey"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "process_expired_keys_attach" {
  role       = aws_iam_role.process_expired_keys_role.name
  policy_arn = aws_iam_policy.process_expired_keys_policy.arn
}

# Lambda NotifyServiceOwners
data "archive_file" "notify_service_user_owner_archive" {
  type        = "zip"
  source_file = "../lambda/notify_service_user_owner.py"
  output_path = "../lambda/notify_service_user_owner.zip"
}

resource "aws_lambda_function" "notify_service_user_owner_lambda" {
  filename         = "../lambda/notify_service_user_owner.zip"
  function_name    = "NotifyServiceOwners"
  role             = aws_iam_role.notify_service_user_owner_role.arn
  handler          = "notify_service_user_owner.lambda_handler"
  timeout          = 120
  source_code_hash = data.archive_file.notify_service_user_owner_archive.output_base64sha256

  runtime = "python3.8"
}

resource "aws_cloudwatch_log_group" "notify_service_user_owner_log_group" {
  name              = "/aws/lambda/NotifyServiceOwners"
  retention_in_days = 1
}

resource "aws_iam_role" "notify_service_user_owner_role" {
  name = "Lambda-NotifyServiceOwners"

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

resource "aws_iam_policy" "notify_service_user_owner_policy" {
  name        = "NotifyServiceOwners"
  path        = "/"
  description = "Iam policy for lambda NotifyServiceOwners"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ssm:*",
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "notify_service_user_owner_attach" {
  role       = aws_iam_role.notify_service_user_owner_role.name
  policy_arn = aws_iam_policy.notify_service_user_owner_policy.arn
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
                "${aws_lambda_function.get_expired_users_lambda.arn}",
                "${aws_lambda_function.process_expired_keys_lambda.arn}",
                "${aws_lambda_function.notify_service_user_owner_lambda.arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "${aws_sns_topic.admin_sns_topic.arn}"
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "step_function_attachment" {
  role       = aws_iam_role.iam_for_sfn.name
  policy_arn = aws_iam_policy.step_function_policy.arn
}

resource "aws_sfn_state_machine" "state_machine" {
  name     = "KeysRotation"
  role_arn = aws_iam_role.iam_for_sfn.arn

  definition = templatefile("./function_definition.tmpl", {
    get_expired_users         = aws_lambda_function.get_expired_users_lambda.arn
    process_expired_keys      = aws_lambda_function.process_expired_keys_lambda.arn
    notify_service_user_owner = aws_lambda_function.notify_service_user_owner_lambda.arn
    admin_sns_topic           = aws_sns_topic.admin_sns_topic.arn
  })
}

resource "aws_cloudwatch_event_rule" "KeysRotationDaily" {
  name        = "KeysRotationDaily"
  description = "Execute KeysRotationD step function daily"

  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "KeysRotationDailyTarget" {
  rule     = aws_cloudwatch_event_rule.KeysRotationDaily.name
  arn      = aws_sfn_state_machine.state_machine.id
  role_arn = aws_iam_role.cwe_role.arn
}

resource "aws_iam_role" "cwe_role" {
  name = "CWE-KeysRotation"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": "131232"
        }
    ]
}
  EOF
}

resource "aws_iam_policy" "cwe_policy" {
  name        = "CWE-KeysRotationPolicy"
  path        = "/"
  description = "Iam policy for lambda PoceedExpiredKeys"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "states:StartExecution"
            ],
            "Resource": [
                "${aws_sfn_state_machine.state_machine.id}"
            ]
        }
    ]
}
  EOF
}
