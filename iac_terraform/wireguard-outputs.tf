# WireGuard VPN Server Outputs

output "wireguard_enabled" {
  description = "Whether WireGuard VPN is enabled"
  value       = var.wireguard_enabled
}

output "wireguard_server_endpoint" {
  description = "WireGuard server public endpoint"
  value       = var.wireguard_enabled ? "${var.wireguard_public_endpoint}:${var.wireguard_port}" : "WireGuard is disabled"
}

output "wireguard_public_ip" {
  description = "WireGuard server public IP address"
  value       = var.wireguard_enabled ? var.wireguard_public_ip : "WireGuard is disabled"
}

output "wireguard_ui_url" {
  description = "wg-easy web UI URL (local access)"
  value       = var.wireguard_enabled ? "http://localhost:${var.wireguard_ui_port}" : "WireGuard is disabled"
}

output "wireguard_ui_password" {
  description = "wg-easy web UI password (sensitive)"
  value       = var.wireguard_enabled ? (var.wireguard_ui_password != "" ? "Set via TF_VAR_wireguard_ui_password" : "changeme (PLEASE CHANGE THIS!)") : "WireGuard is disabled"
  sensitive   = true
}

output "wireguard_vpn_network" {
  description = "VPN tunnel network prefix"
  value       = var.wireguard_enabled ? var.wireguard_vpn_network : "WireGuard is disabled"
}

output "wireguard_allowed_networks" {
  description = "Networks accessible via VPN"
  value       = var.wireguard_enabled ? var.wireguard_allowed_ips : "WireGuard is disabled"
}

output "wireguard_dns_server" {
  description = "DNS server for VPN clients"
  value       = var.wireguard_enabled ? var.wireguard_dns_server : "WireGuard is disabled"
}

output "wireguard_container_name" {
  description = "Docker container name"
  value       = var.wireguard_enabled ? local.wireguard_container_name : "WireGuard is disabled"
}

output "wireguard_config_directory" {
  description = "WireGuard configuration directory"
  value       = var.wireguard_enabled ? local.wireguard_config_dir : "WireGuard is disabled"
}

output "wireguard_next_steps" {
  description = "Next steps after deployment"
  sensitive   = true
  value = var.wireguard_enabled ? join("\n", [
    "",
    "WireGuard VPN Server deployed successfully!",
    "",
    "Next Steps:",
    "1. Configure OpenWrt Port Forwarding:",
    "   - Login to OpenWrt at 10.22.6.1",
    "   - Navigate to Network > Firewall > Port Forwards",
    "   - Add rule: External Port ${var.wireguard_port} (UDP) -> Internal IP (monolith) Port ${var.wireguard_port}",
    "",
    "2. Access wg-easy Web UI:",
    "   - URL: http://localhost:${var.wireguard_ui_port}",
    "   - Password: ${var.wireguard_ui_password != "" ? "Your configured password" : "changeme"}",
    "",
    "3. Create VPN Clients:",
    "   - Click 'New Client' in the web UI",
    "   - Enter client name (e.g., 'iPhone', 'Laptop')",
    "   - Download QR code (mobile) or .conf file (desktop)",
    "",
    "4. Configure Clients:",
    "   - iOS: Install WireGuard app, scan QR code",
    "   - Laptop: Install WireGuard, import .conf file",
    "",
    "5. Test Connection:",
    "   - Connect via WireGuard client",
    "   - Test access to homelab: ping 10.22.6.1",
    "   - Verify DNS: nslookup homelab.metatao.net",
    "",
    "Public Endpoint: ${var.wireguard_public_endpoint}:${var.wireguard_port}",
    "Accessible Networks: ${var.wireguard_allowed_ips}",
    ""
  ]) : "WireGuard is disabled"
}
