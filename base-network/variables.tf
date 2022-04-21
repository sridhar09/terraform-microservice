# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "prefix" {
  description = "Prefix for all resources"
}

variable "vpc_cidr" {
  default = "10.0.0.0/24"
}

variable "public_subnets_cidr" {
  type = list(string)
  default = ["10.0.0.0/26","10.0.0.64/26"]
}

variable "availability_zones" {
  type = list(string)
  default = ["eu-west-2a","eu-west-2b"]
}

variable "private_subnets_cidr" {
  type = list(string)
  default = ["10.0.0.128/26","10.0.0.192/26"]
}