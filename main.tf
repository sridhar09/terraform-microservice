# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY TWO MICROSERVICES: FRONTEND AND BACKEND
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>3.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-2"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE FRONTEND
# ---------------------------------------------------------------------------------------------------------------------

module "base-network" {
  source = "./base-network"
  prefix = var.prefix
}

module "frontend" {
  source = "./microservice"

  name                  = "frontend"
  min_size              = 1
  max_size              = 2
  key_name              = var.key_name
  user_data_script      = file("user-data/user-data-frontend.sh")
  server_text           = var.frontend_server_text
  prefix                = var.prefix
  is_internal_alb       = false

  # Pass an output from the backend module to the frontend module. This is the URL of the backend microservice, which
  # the frontend will use for "service calls"
  backend_url = module.backend.url
  subnet_ids  = module.base-network.private_subnet_ids
  vpc_id      = module.base-network.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE BACKEND
# ---------------------------------------------------------------------------------------------------------------------

module "backend" {
  source = "./microservice"

  name                  = "backend"
  min_size              = 1
  max_size              = 3
  key_name              = var.key_name
  user_data_script      = file("user-data/user-data-backend.sh")
  server_text           = var.backend_server_text
  prefix                = var.prefix
  is_internal_alb       = true
  subnet_ids            = module.base-network.private_subnet_ids
  vpc_id                = module.base-network.vpc_id
}