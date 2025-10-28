terraform {
  required_version = ">= 1.6.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# OpenTofu is compatible with Terraform configurations
# This configuration works with both OpenTofu and Terraform

# Provider for Kubernetes cluster
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Install nginx on monolith (local desktop)
resource "null_resource" "install_nginx_monolith" {
  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v nginx &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y nginx
        sudo systemctl enable nginx
        sudo systemctl start nginx
      else
        echo "nginx is already installed"
      fi
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

# Create namespace for hello world application
resource "kubernetes_namespace" "hello_world" {
  metadata {
    name = "hello-world"
    labels = {
      name        = "hello-world"
      environment = "homelab"
    }
  }
}

# Deploy hello world application to Kubernetes cluster
resource "kubernetes_deployment" "hello_world" {
  metadata {
    name      = "hello-world"
    namespace = kubernetes_namespace.hello_world.metadata[0].name
    labels = {
      app = "hello-world"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "hello-world"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-world"
        }
      }

      spec {
        container {
          name  = "hello-world"
          image = "hashicorp/http-echo:latest"

          port {
            container_port = 5678
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.hello_world]
}

# Create service for hello world application
resource "kubernetes_service" "hello_world" {
  metadata {
    name      = "hello-world"
    namespace = kubernetes_namespace.hello_world.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.hello_world.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 5678
      protocol    = "TCP"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.hello_world]
}
