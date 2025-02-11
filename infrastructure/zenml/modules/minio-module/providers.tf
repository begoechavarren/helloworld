# defining the providers required by the mlflow module
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.3"
    }
    minio = {
      source  = "aminueza/minio"
      version = "1.10.0"
    }
  }
  required_version = ">= 0.14.8"
}

