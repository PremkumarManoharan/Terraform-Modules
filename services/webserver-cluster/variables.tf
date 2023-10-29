
variable "cluster_name" {
  description = "The name to be used for cluster resources"
  type = string
}
variable "custom_tags" {
  description = "The name to be used for cluster resources"
  type = map(string)
}

variable "enable_autoscaling" {
  description = "If set to true , enable auto scaling"
  type = bool
}

variable "ami" {
  description = "The AMI to run the clsuter"
  type = string
  default = "ami-0261755bbcb8c4a84"
}

variable "server_text" {
  description = "The text the web server should return"
  type = string
  default = "Hello, from Terraform infra"
}

variable "db_remote_address" {
  description = "The address of the s3 bucket for the database's remote state"
  type = string
}

variable "db_remote_port" {
  description = "The port for the database's remote state in s3"
  type = string
}

variable "instance_type" {
  description = "The type of the EC2 instance to run"
  type = string
}

variable "min_size" {
  description = "Minimum amount of Ec2 instance to run"
  type = number
}

variable "max_size" {
  description = "Maximum amount of Ec2 instance to run"
  type = number
}

locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips= ["0.0.0.0/0"]
  server_port = 8080
}