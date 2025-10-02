#!/bin/bash
# Deploy basic cluster setup to homelab nodes
# Usage: ./deploy-cluster.sh [options]
#
# Options:
#   --tags TAGS       Run only tasks with specific tags (e.g., --tags config,system)
#   --skip-tags TAGS  Skip tasks with specific tags (e.g., --skip-tags cargo)
#   --check           Run in check mode (dry-run)
#   --help            Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY="${SCRIPT_DIR}/inventory-homelab.ini"
PLAYBOOK="${SCRIPT_DIR}/install-cluster.yml"

# Default options
ANSIBLE_OPTS=""
TAGS=""
SKIP_TAGS=""
CHECK_MODE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tags)
            TAGS="$2"
            shift 2
            ;;
        --skip-tags)
            SKIP_TAGS="$2"
            shift 2
            ;;
        --check)
            CHECK_MODE="--check"
            shift
            ;;
        --help)
            echo "Deploy basic cluster setup to homelab nodes"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --tags TAGS       Run only tasks with specific tags"
            echo "                    Available tags: config, system, tools, dev, hardware"
            echo "                    Example: --tags config,system"
            echo "  --skip-tags TAGS  Skip tasks with specific tags"
            echo "                    Example: --skip-tags cargo (skip slow cargo builds)"
            echo "  --check           Run in check mode (dry-run)"
            echo "  --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                              # Full deployment"
            echo "  $0 --tags system                # Only system tasks"
            echo "  $0 --skip-tags cargo            # Skip cargo package compilation"
            echo "  $0 --tags config,tools --check  # Dry-run config and tools"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build ansible command
if [ -n "$TAGS" ]; then
    ANSIBLE_OPTS="$ANSIBLE_OPTS --tags $TAGS"
fi

if [ -n "$SKIP_TAGS" ]; then
    ANSIBLE_OPTS="$ANSIBLE_OPTS --skip-tags $SKIP_TAGS"
fi

if [ -n "$CHECK_MODE" ]; then
    ANSIBLE_OPTS="$ANSIBLE_OPTS $CHECK_MODE"
fi

# Check if inventory exists
if [ ! -f "$INVENTORY" ]; then
    echo "Error: Inventory file not found: $INVENTORY"
    exit 1
fi

# Check if playbook exists
if [ ! -f "$PLAYBOOK" ]; then
    echo "Error: Playbook not found: $PLAYBOOK"
    exit 1
fi

echo "========================================="
echo "Homelab Cluster Deployment"
echo "========================================="
echo "Inventory: $INVENTORY"
echo "Playbook:  $PLAYBOOK"
[ -n "$ANSIBLE_OPTS" ] && echo "Options:   $ANSIBLE_OPTS"
echo "========================================="
echo ""

# Run ansible playbook
ansible-playbook -i "$INVENTORY" "$PLAYBOOK" $ANSIBLE_OPTS

echo ""
echo "========================================="
echo "Deployment complete!"
echo "========================================="
