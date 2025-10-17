#!/bin/bash

# ==============================================================================
# create_sonic_vm.sh
#
# Creates and starts a SONiC virtual switch using virt-install by importing
# a pre-existing qcow2 disk image.
#
# The disk image path is an optional argument. If not provided, it defaults
# to the value of DEFAULT_DISK_IMAGE.
#
# Usage (with default image):
#   sudo ./create_sonic_vm.sh
#
# Usage (with a custom image path):
#   sudo ./create_sonic_vm.sh /path/to/your-image.qcow2
# ==============================================================================

# --- VM Configuration ---
VM_NAME="sonic-vm"
RAM_MB="4096"        # Memory in Megabytes (4GB is recommended for SONiC)
VCPUS="2"            # Number of virtual CPUs
BRIDGE_IF="br0"      # The host bridge for the VM's management interface
DEFAULT_DISK_IMAGE="/var/lib/libvirt/images/sonic-vs.qcow2"

# --- Argument Handling ---
# Use the first command-line argument ($1) as the disk image path.
# If no argument is provided, use the DEFAULT_DISK_IMAGE value.
DISK_IMAGE="${1:-$DEFAULT_DISK_IMAGE}"

# --- Pre-flight Checks ---

# 1. Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run with sudo or as root."
  exit 1
fi

# 2. Check if the disk image file actually exists
if [ ! -f "$DISK_IMAGE" ]; then
    echo "❌ Error: Disk image not found at '$DISK_IMAGE'"
    exit 1
fi

echo "▶️  Using disk image: $DISK_IMAGE"
echo "▶️  Starting installation for VM: $VM_NAME..."

# --- Main virt-install Command ---

sudo virt-install \
  --name "$VM_NAME" \
  --ram "$RAM_MB" \
  --vcpus "$VCPUS" \
  --disk path="$DISK_IMAGE",format=qcow2 \
  --import \
  --os-variant generic \
  --network bridge="$BRIDGE_IF",model=virtio \
  --graphics none \
  --noautoconsole

# --- Command Explanation ---
# --name:         A unique name for the virtual machine.
# --ram:          The amount of memory allocated to the VM.
# --vcpus:        The number of virtual CPUs for the VM.
# --disk:         Specifies the path to the existing qcow2 disk image.
# --import:       Crucial for using a pre-existing disk. It tells virt-install to skip the OS installation phase.
# --os-variant:   Helps libvirt optimize the VM configuration for a generic Linux guest.
# --network:      Connects the VM's network card to the specified host bridge for LAN access.
# --graphics none: Disables graphical output, as we will use the serial console for management.
# --noautoconsole: Prevents virt-install from automatically connecting to the console after creation.

echo "✅ VM '$VM_NAME' has been created successfully."
echo "You can now manage it using 'virsh' commands."
echo ""

# ==============================================================================
# Post-Installation Management with virsh
#
# The following commands are kept here for your reference.
# ==============================================================================

# List all defined VMs (both running and shut off):
# sudo virsh list --all

# Connect to the VM's console (to log in and configure SONiC):
# To exit the console, press Ctrl + ]
# sudo virsh console sonic-vm

# Gracefully shut down the VM:
# sudo virsh shutdown sonic-vm

# Forcefully stop the VM (equivalent to pulling the power plug):
# sudo virsh destroy sonic-vm

# Delete the VM definition from libvirt (this does NOT delete the qcow2 disk image file):
# sudo virsh undefine sonic-vm
