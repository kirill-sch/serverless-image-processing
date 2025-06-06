variable "region" {
  type        = string
  description = "AWS region to deploy resources in"
}
variable "project_name" {
  type        = string
  description = "Name that all resources will get"
}
variable "lambda_runtime" {
  type = string
}
variable "lambda_timeout" {
  type = string
}
variable "lambda_memory" {
  type = string
}
variable "lambda_tracing_config" {
  type = string
}