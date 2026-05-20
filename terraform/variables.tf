variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "devops-assignment-vpc"
}

variable "subnet_name" {
  description = "Private subnet name"
  type        = string
  default     = "private-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for private subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "api_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "worker_machine_type" {
  type    = string
  default = "e2-small"
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH to API gateway (admin IP)"
  type        = string
  default     = "0.0.0.0/32"
}

variable "repo_url" {
  description = "Public Git repo URL that contains this project code. Set before apply."
  type        = string
}

variable "repo_branch" {
  description = "Branch in repo to clone"
  type        = string
  default     = "main"
}

variable "api_private_ip" {
  description = "Static private IP for API instance"
  type        = string
  default     = "10.10.0.10"
}

variable "python_worker_ip" {
  description = "Static private IP for Python worker"
  type        = string
  default     = "10.10.0.11"
}

variable "ts_worker_ip" {
  description = "Static private IP for TypeScript worker"
  type        = string
  default     = "10.10.0.12"
}

variable "model_worker_ip" {
  description = "Static private IP for Model worker"
  type        = string
  default     = "10.10.0.13"
}
