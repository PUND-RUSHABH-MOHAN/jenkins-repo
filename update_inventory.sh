#!/bin/bash

set -e

# IMPORTANT: Use absolute paths
TERRAFORM_DIR="/home/ubuntu/terraform-aws-project/terraform"
INVENTORY_FILE="./inventory.ini"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "📝 Updating Ansible inventory from Terraform..."
echo "Terraform Directory: $TERRAFORM_DIR"
echo "Script Directory: $SCRIPT_DIR"
echo ""

# Change to terraform directory
cd "$TERRAFORM_DIR" || { echo "✗ Cannot find Terraform directory: $TERRAFORM_DIR"; exit 1; }

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "✗ Terraform state not found. Run 'terraform apply' first."
    exit 1
fi

# Get outputs from Terraform
echo "📦 Fetching Terraform outputs..."
echo ""

# Extract EC2 public IPs
WEB_IPS=$(terraform output -json ec2_public_ips 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")

if [ -z "$WEB_IPS" ]; then
    echo "✗ Error: Could not retrieve EC2 public IPs"
    echo "  Try running: terraform output -json ec2_public_ips"
    exit 1
fi

# Extract RDS details
RDS_HOST=$(terraform output -raw rds_address 2>/dev/null || echo "")
RDS_PORT=$(terraform output -raw rds_port 2>/dev/null || echo "3306")
DB_NAME=$(terraform output -raw db_name 2>/dev/null || echo "myappdb")

# Debug output
echo "Extracted values:"
COUNT=0
for ip in $WEB_IPS; do
    COUNT=$((COUNT + 1))
    echo "  Web Server $COUNT: $ip"
done
echo "  RDS Host: $RDS_HOST"
echo "  RDS Port: $RDS_PORT"
echo ""

# Validate all values
if [ -z "$RDS_HOST" ]; then
    echo "✗ Error: Could not get RDS address"
    exit 1
fi

# Create web_servers section
WEB_SERVERS_SECTION=""
COUNT=0
for ip in $WEB_IPS; do
    COUNT=$((COUNT + 1))
    WEB_SERVERS_SECTION+="web_server_$COUNT ansible_host=$ip ansible_user=ubuntu"$'\n'
done

# Go back to inventory directory
cd "$SCRIPT_DIR" || exit 1

# Create updated inventory file
cat > "$INVENTORY_FILE" << INVENTORY_EOF
# Ansible Inventory - Auto-generated from Terraform
# Generated: $(date)
# Source: Terraform State File
# DO NOT EDIT MANUALLY - This file is auto-generated

[web_servers]
$WEB_SERVERS_SECTION
[databases]
rds_mysql ansible_host=$RDS_HOST

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
db_name=$DB_NAME
db_user=admin
db_password=ChangeMe_123
db_host=$RDS_HOST
db_port=$RDS_PORT
INVENTORY_EOF

# Verify inventory was created
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "✗ Error: Failed to create inventory file: $INVENTORY_FILE"
    exit 1
fi

echo "✅ Inventory file updated: $INVENTORY_FILE"
echo ""
echo "📄 Web Servers in Inventory: $COUNT"
echo "✅ INVENTORY UPDATE COMPLETE!"
SCRIPT_EOF

chmod +x ~/terraform-aws-project/jenkins-ansible/inventory/update_inventory.sh

