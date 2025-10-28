# WireGuard VPN Server Configuration
# Deploys WireGuard VPN on monolith.metatao.net for remote access to homelab

# Install WireGuard and Docker on monolith
resource "null_resource" "install_wireguard_dependencies" {
  count = var.wireguard_enabled ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Installing WireGuard and Docker dependencies..."

      # Update package lists
      sudo apt-get update

      # Install WireGuard kernel module and tools
      if ! command -v wg &> /dev/null; then
        echo "Installing WireGuard..."
        sudo apt-get install -y wireguard
      else
        echo "WireGuard is already installed"
      fi

      # Install Docker if not present
      if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt-get install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Add current user to docker group
        sudo usermod -aG docker $USER

        echo "Docker installed successfully"
      else
        echo "Docker is already installed"
      fi

      # Enable IP forwarding for VPN routing
      echo "Enabling IP forwarding..."
      sudo sysctl -w net.ipv4.ip_forward=1
      sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

      echo "Dependencies installation complete"
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

# Deploy wg-easy Docker container for WireGuard management
resource "null_resource" "deploy_wg_easy" {
  count = var.wireguard_enabled ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Deploying wg-easy WireGuard management container..."

      # Stop and remove existing container if present
      docker stop wg-easy 2>/dev/null || true
      docker rm wg-easy 2>/dev/null || true

      # Create directory for WireGuard configuration persistence
      mkdir -p ~/.wg-easy

      # Generate bcrypt password hash
      # If no password is set, use "changeme" as default
      PASSWORD_TO_HASH="${var.wireguard_ui_password}"
      if [ -z "$PASSWORD_TO_HASH" ]; then
        PASSWORD_TO_HASH="changeme"
      fi

      # Generate bcrypt hash using wg-easy's built-in tool
      PASSWORD_HASH=$(docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$PASSWORD_TO_HASH" | cut -d"'" -f2)

      # Deploy wg-easy container
      docker run -d \
        --name=wg-easy \
        --cap-add=NET_ADMIN \
        --cap-add=SYS_MODULE \
        --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
        --sysctl="net.ipv4.ip_forward=1" \
        -e WG_HOST=${var.wireguard_public_endpoint} \
        -e PASSWORD_HASH="$$PASSWORD_HASH" \
        -e WG_PORT=${var.wireguard_port} \
        -e WG_DEFAULT_ADDRESS=${var.wireguard_vpn_network} \
        -e WG_DEFAULT_DNS=${var.wireguard_dns_server} \
        -e WG_ALLOWED_IPS=${var.wireguard_allowed_ips} \
        -e WG_PERSISTENT_KEEPALIVE=25 \
        -v ~/.wg-easy:/etc/wireguard \
        -p ${var.wireguard_port}:${var.wireguard_port}/udp \
        -p ${var.wireguard_ui_port}:51821/tcp \
        --restart unless-stopped \
        ghcr.io/wg-easy/wg-easy

      echo "wg-easy container deployed successfully"

      # Wait for container to be fully started
      sleep 5

      # Check container status
      docker ps | grep wg-easy
    EOT
  }

  depends_on = [null_resource.install_wireguard_dependencies]

  triggers = {
    config_hash = md5(jsonencode({
      port              = var.wireguard_port
      ui_port           = var.wireguard_ui_port
      vpn_network       = var.wireguard_vpn_network
      allowed_ips       = var.wireguard_allowed_ips
      dns_server        = var.wireguard_dns_server
      public_endpoint   = var.wireguard_public_endpoint
      password_checksum = md5(var.wireguard_ui_password)
    }))
  }
}

# Configure firewall rules for WireGuard
resource "null_resource" "configure_firewall" {
  count = var.wireguard_enabled ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Configuring firewall rules for WireGuard..."

      # Allow WireGuard port through UFW if UFW is active
      if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
        echo "Configuring UFW firewall..."
        sudo ufw allow ${var.wireguard_port}/udp comment 'WireGuard VPN'
        sudo ufw allow ${var.wireguard_ui_port}/tcp comment 'WireGuard UI'
      else
        echo "UFW is not active or not installed, skipping firewall configuration"
      fi

      echo "Firewall configuration complete"
    EOT
  }

  depends_on = [null_resource.deploy_wg_easy]

  triggers = {
    ports = "${var.wireguard_port},${var.wireguard_ui_port}"
  }
}

# Output local variables for reference
locals {
  wireguard_server_ip      = "10.8.0.1"
  wireguard_ui_url_local   = "http://localhost:${var.wireguard_ui_port}"
  wireguard_endpoint       = "${var.wireguard_public_endpoint}:${var.wireguard_port}"
  wireguard_config_dir     = "~/.wg-easy"
  wireguard_container_name = "wg-easy"
}
