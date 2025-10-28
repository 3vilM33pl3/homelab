variable "wireguard_enabled" {
  description = "Enable WireGuard VPN server deployment"
  type        = bool
  default     = true
}

variable "wireguard_port" {
  description = "WireGuard VPN server listening port (UDP)"
  type        = number
  default     = 51820
}

variable "wireguard_ui_port" {
  description = "wg-easy web UI port (HTTP)"
  type        = number
  default     = 51821
}

variable "wireguard_ui_password" {
  description = "Password for wg-easy web UI access (set via TF_VAR_wireguard_ui_password)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "wireguard_vpn_network" {
  description = "VPN tunnel network prefix (clients will be assigned 10.8.0.x addresses)"
  type        = string
  default     = "10.8.0.x"
}

variable "wireguard_allowed_ips" {
  description = "Networks that VPN clients can access"
  type        = string
  default     = "10.22.6.0/24"
}

variable "wireguard_dns_server" {
  description = "DNS server for VPN clients"
  type        = string
  default     = "10.22.6.1"
}

variable "wireguard_public_endpoint" {
  description = "Public endpoint hostname for WireGuard (vpn.metatao.net)"
  type        = string
  default     = "vpn.metatao.net"
}

variable "wireguard_public_ip" {
  description = "Public IP address for WireGuard endpoint"
  type        = string
  default     = "95.141.20.76"
}
