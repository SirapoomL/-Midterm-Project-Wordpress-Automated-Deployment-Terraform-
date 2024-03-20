variable "region" {
  description = "AWS Region"
  type        = string
}

variable "availability_zone" {
  description = "AWS Availability Zone"
  type        = string
}

variable "ami" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "bucket_name" {
  description = "S3 Bucket name for WordPress media files"
  type        = string
}

variable "database_name" {
  description = "MariaDB database name"
  type        = string
}

variable "database_user" {
  description = "MariaDB database user"
  type        = string
}

variable "database_pass" {
  description = "MariaDB database password"
  type        = string
}

variable "admin_user" {
  description = "WordPress admin username"
  type        = string
}

variable "admin_pass" {
  description = "WordPress admin password"
  type        = string
}