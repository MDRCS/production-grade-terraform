variable "prefix" {
  default = "raad"
}

variable "project" {
  default = "django-rest-api"
}

variable "contact" {
  default = "elrahali.md@gmail.com"
}

variable "db_username" {
  description = "Username For the RDS postgres instance."
}

variable "db_password" {
  description = "Password For the RDS postgres instance."
}

variable "bastion_key_name" {
  default     = "rest-api-devops-bastion"
  description = "my local machine ssh key pair stored under this name to connect to Bastion server and access to private subnets resources as postgres db etc."
}

variable "ecr_image_api" {
  description = "ECR image for API"
  default     = "900424598669.dkr.ecr.us-east-1.amazonaws.com/django-rest-api:latest"
}

variable "ecr_image_proxy" {
  description = "ECR image for proxy"
  default     = "900424598669.dkr.ecr.us-east-1.amazonaws.com/nginx-proxy:latest"
}

variable "django_secret_key" {
  description = "Secret Key For Django app" # set in GitLab CI Variables
}

variable "dns_zone_name" {
  description = "Domain Name"
  default     = "django-rest-api.com" # should be registered in route53 or other dns providers
}

variable "subdomain" {
  description = "Subdomain per environment"
  type        = map(string)
  default = {
    prod    = "api"
    staging = "api.staging"
    dev     = "api.dev"
  }
}
