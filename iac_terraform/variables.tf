variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "hello_world_replicas" {
  description = "Number of replicas for hello world deployment"
  type        = number
  default     = 2
}

variable "hello_world_namespace" {
  description = "Kubernetes namespace for hello world application"
  type        = string
  default     = "hello-world"
}

variable "hello_world_image" {
  description = "Container image for hello world application"
  type        = string
  default     = "hashicorp/http-echo:latest"
}
