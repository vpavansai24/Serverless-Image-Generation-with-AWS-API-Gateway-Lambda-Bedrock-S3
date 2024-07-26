provider "aws" {
  region = "us-east-1"  # Change to your desired AWS region
}

# Define the S3 bucket
resource "aws_s3_bucket" "image_bucket" {
  bucket = "image-generation-2024-07-25"
}

# Create IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
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
      "Sid": ""
    }
  ]
}
EOF
}

# Create IAM Policy for Bedrock and CLoudWatch Logs Access
resource "aws_iam_policy" "bedrock_policy" {
  name        = "lambda_bedrock_policy"
  path        = "/"
  description = "IAM policy for Lambda access to Bedrock, CloudWatch Logs, and specific S3 bucket"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
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
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "${aws_s3_bucket.image_bucket.arn}/*",
          "${aws_s3_bucket.image_bucket.arn}"
        ],
        "Effect": "Allow"
      }
  ]
}
EOF
}

# Attach Policy to IAM Role
resource "aws_iam_role_policy_attachment" "role_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.bedrock_policy.arn
}

# Package Lambda function code
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

# Create Lambda Function
resource "aws_lambda_function" "example_lambda" {
  function_name = var.lambda_function_name
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  filename      = "lambda_function_payload.zip"
  handler       = "lambda_function.lambda_handler"
  timeout          = 60  # Timeout set to 60 seconds (1 minute)
  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.image_bucket.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.role_policy_attach,
    data.archive_file.lambda
  ]
}

