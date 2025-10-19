#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}MySQL Active-Active Cleanup Script${NC}"
echo -e "${RED}========================================${NC}\n"

echo -e "${YELLOW}⚠️  WARNING: This will destroy ALL resources!${NC}\n"
echo "This includes:"
echo "  - Both RDS instances in us-east-1 and us-west-2"
echo "  - All VPC resources (subnets, route tables, security groups)"
echo "  - VPC peering connection"
echo "  - ALL DATA (no final snapshots by default)"
echo ""

read -p "Are you absolutely sure you want to continue? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${GREEN}Cleanup cancelled${NC}"
    exit 0
fi

echo ""
read -p "Type 'DELETE' in all caps to proceed: " CONFIRM2

if [ "$CONFIRM2" != "DELETE" ]; then
    echo -e "${GREEN}Cleanup cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting cleanup...${NC}\n"

# Check if in scripts directory
if [ -d "../modules" ]; then
    cd ..
fi

# Optional: Create final snapshots
read -p "Do you want to create final snapshots before deletion? (y/n): " SNAPSHOT

if [ "$SNAPSHOT" = "y" ] || [ "$SNAPSHOT" = "Y" ]; then
    echo -e "${YELLOW}Updating configuration to enable final snapshots...${NC}"
    
    # Temporarily set skip_final_snapshot to false
    sed -i.bak 's/skip_final_snapshot *= *true/skip_final_snapshot = false/' terraform.tfvars
    
    terraform apply -auto-approve
    
    echo -e "${GREEN}✓ Configuration updated${NC}\n"
fi

# Show current resources
echo -e "${YELLOW}Current resources:${NC}"
terraform state list

echo ""
read -p "Press Enter to start destruction..."

# Run terraform destroy
echo -e "${YELLOW}Running terraform destroy...${NC}\n"

terraform destroy

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Cleanup Complete!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    echo "All resources have been destroyed:"
    echo "  ✓ RDS instances deleted"
    echo "  ✓ VPCs removed"
    echo "  ✓ VPC peering terminated"
    echo "  ✓ Security groups deleted"
    echo "  ✓ All networking cleaned up"
    echo ""
    
    if [ "$SNAPSHOT" = "y" ] || [ "$SNAPSHOT" = "Y" ]; then
        echo -e "${BLUE}Final snapshots were created:${NC}"
        aws rds describe-db-snapshots \
          --query 'DBSnapshots[?contains(DBSnapshotIdentifier, `mysql-active`)].{ID:DBSnapshotIdentifier,Created:SnapshotCreateTime,Status:Status}' \
          --output table
    fi
    
    # Restore terraform.tfvars if we modified it
    if [ -f "terraform.tfvars.bak" ]; then
        mv terraform.tfvars.bak terraform.tfvars
    fi
    
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Cleanup Failed${NC}"
    echo -e "${RED}========================================${NC}\n"
    
    echo "Some resources may not have been deleted."
    echo "You may need to manually delete resources in AWS Console."
    echo ""
    echo "To retry:"
    echo "  terraform destroy"
    
    exit 1
fi
