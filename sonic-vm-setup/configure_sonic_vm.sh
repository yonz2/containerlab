#!/bin/bash

# ==============================================================================
# configure_sonic_vm.sh
#
# This script performs the initial configuration of a fresh SONiC VM from the
# host machine. It handles SSH key setup, DNS configuration, Git installation,
# repository cloning, and Docker image deployment.
#
# Prerequisites:
#   1. The SONiC VM must be running and accessible by name from the host.
#   2. The local files specified in the 'Local File Paths' section must exist
#      at the correct relative paths to this script.
#
# Usage:
#   ./configure_sonic_vm.sh
#
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
VM_USER="admin"
VM_HOST="sonic-vm"
GIT_REPO_URL="https://github.com/yonz2/sonic-wan.git"

# --- Local File Paths ---
SSH_KEY_PUB="${HOME}/.ssh/id_ed25519.pub"
DNS_SCRIPT="dns-config.sh"
ZEROTIER_IMAGE_PATH="../containers/zerotier/zerotier.tar.gz"
WIREGUARD_IMAGE_PATH="../containers/wireguard/wireguard.tar.gz"

# --- Remote Paths (on the VM) ---
REMOTE_REPO_DIR="/home/${VM_USER}/sonic-wan"
REMOTE_IMAGE_DIR="${REMOTE_REPO_DIR}/container-images"

# --- Pre-flight Checks ---
echo "▶️  Performing pre-flight checks..."
for f in "$SSH_KEY_PUB" "$DNS_SCRIPT" "$ZEROTIER_IMAGE_PATH" "$WIREGUARD_IMAGE_PATH"; do
    if [ ! -f "$f" ]; then
        echo "❌ Error: Required local file not found: $f"
        exit 1
    fi
done
echo "✅ All required local files found."
echo ""


# === 1. Enable SSH Access via Public Key ===
echo "▶️  Step 1: Enabling passwordless SSH access..."
echo "    You will be prompted for the '${VM_USER}' password for the VM."
ssh-copy-id -i "$SSH_KEY_PUB" "${VM_USER}@${VM_HOST}"
echo "✅ SSH public key has been transferred."
echo ""


# === 2. Transfer and Run DNS Configuration Script ===
echo "▶️  Step 2: Configuring DNS on the VM..."
scp "$DNS_SCRIPT" "${VM_USER}@${VM_HOST}:/tmp/"
ssh "${VM_USER}@${VM_HOST}" "sudo /tmp/${DNS_SCRIPT} && rm /tmp/${DNS_SCRIPT}"
echo "✅ DNS configuration script executed and cleaned up."
echo ""


# === 3. Install Git ===
echo "▶️  Step 3: Installing Git on the VM..."
ssh "${VM_USER}@${VM_HOST}" "sudo apt-get update && sudo apt-get install git -y"
echo "✅ Git has been installed."
echo ""


# === 4. Clone the Git Repository ===
echo "▶️  Step 4: Cloning the 'sonic-wan' repository..."
ssh "${VM_USER}@${VM_HOST}" "git clone '$GIT_REPO_URL' '$REMOTE_REPO_DIR'"
echo "✅ Repository cloned to '${REMOTE_REPO_DIR}'."
echo ""


# === 5. Transfer Docker Container Images ===
echo "▶️  Step 5: Transferring Docker images..."
# Ensure the target directory exists on the remote machine
ssh "${VM_USER}@${VM_HOST}" "mkdir -p '$REMOTE_IMAGE_DIR'"
scp "$ZEROTIER_IMAGE_PATH" "$WIREGUARD_IMAGE_PATH" "${VM_USER}@${VM_HOST}:${REMOTE_IMAGE_DIR}/"
echo "✅ Docker images transferred successfully."
echo ""


# === 6. Load Docker Images and Clean Up ===
echo "▶️  Step 6: Loading images into Docker and cleaning up..."
# Define the remote commands in a 'here document' for clarity
ssh "${VM_USER}@${VM_HOST}" << 'END_OF_COMMANDS'
  set -e
  echo "  -> Loading ZeroTier image..."
  sudo docker load < /home/admin/sonic-wan/container-images/zerotier.tar.gz

  echo "  -> Loading WireGuard image..."
  sudo docker load < /home/admin/sonic-wan/container-images/wireguard.tar.gz

  echo "  -> Removing archive files..."
  rm /home/admin/sonic-wan/container-images/*.tar.gz
END_OF_COMMANDS
echo "✅ Docker images loaded and archives removed."
echo ""

echo "🎉 All configuration tasks completed successfully!"
