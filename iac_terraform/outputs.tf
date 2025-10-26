output "nginx_status" {
  description = "Status of nginx installation on monolith"
  value       = "Nginx installation completed on monolith.metatao.net"
  depends_on  = [null_resource.install_nginx_monolith]
}

output "hello_world_namespace" {
  description = "Namespace where hello-world is deployed"
  value       = kubernetes_namespace.hello_world.metadata[0].name
}

output "hello_world_deployment_name" {
  description = "Name of the hello-world deployment"
  value       = kubernetes_deployment.hello_world.metadata[0].name
}

output "hello_world_service_name" {
  description = "Name of the hello-world service"
  value       = kubernetes_service.hello_world.metadata[0].name
}

output "hello_world_service_type" {
  description = "Type of the hello-world service"
  value       = kubernetes_service.hello_world.spec[0].type
}
