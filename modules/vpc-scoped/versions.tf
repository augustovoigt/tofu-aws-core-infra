terraform {
  required_version = "~> 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.0"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.0"
    }
  }
}