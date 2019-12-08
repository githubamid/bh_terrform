variable "region" {
  description = "Please enter AWS Region to deply Bastion Host"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "Enter Instance Type"
  type        = string
  default     = "t2.micro"
}

variable "allow_ports" {
  description = "List of open ports"
  type        = list
  default     = ["22"]
}

variable "key_pair" {
  description = "Enter key pair name"
  type        = string
  default     = "chef_key"
}
