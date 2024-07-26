variable "myregion" {
  description = "The AWS Region to deploy resources in"
  type = string
  default = "us-east-1"
}

variable "lambda_function_name" {
  description = "The Name of the AWS Lambda Function"
  type = string
  default = "imageGeneratorv2"
}

variable "api_name" {
  description = "The Name of the API"
  type = string
  default = "imageGeneratorAPI"
}

variable "endpoint_path" {
  description = "The Get Endpoint Path"
  type = string
  default = "generate"
}