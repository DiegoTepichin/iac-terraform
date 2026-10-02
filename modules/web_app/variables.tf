variable "environment" {
  description = "Environment name (dev, staging, prod). Used in resource names."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC that hosts the load balancer and instances."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the Application Load Balancer (at least two AZs)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "An Application Load Balancer requires subnets in at least two availability zones."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where the Auto Scaling Group launches instances."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 1
    error_message = "At least one private subnet is required."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the application instances."
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Initial number of instances in the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "cpu_target_percent" {
  description = "Average CPU utilization the target tracking policy keeps the group at."
  type        = number
  default     = 60

  validation {
    condition     = var.cpu_target_percent > 0 && var.cpu_target_percent <= 100
    error_message = "cpu_target_percent must be between 1 and 100."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size must be at least 8 GiB (Ubuntu AMI minimum)."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable 1-minute CloudWatch metrics on instances (billed separately)."
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Prevent the load balancer from being deleted while this is true."
  type        = bool
  default     = false
}
