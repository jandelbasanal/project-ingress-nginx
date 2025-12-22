variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "cluster_name" {
  type    = string
  default = "demo-cluster"
}

variable "state_bucket" {
  type    = string
  default = ""
}

variable "dynamodb_table" {
  type    = string
  default = ""
}
