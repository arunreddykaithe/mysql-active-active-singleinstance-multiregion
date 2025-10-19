#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MySQL Active-Active Replication Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if terraform is available
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform not found${NC}"
    exit 1
fi

# Check if in scripts directory, if so go back to root
if [ -d "../modules" ]; then
    cd ..
fi

# Get outputs from Terraform
echo -e "${YELLOW}Getting configuration from Terraform...${NC}"

REGION1_ADDR=$(terraform output -raw region1_rds_address 2>/dev/null)
REGION2_ADDR=$(terraform output -raw region2_rds_address 2>/dev/null)
REGION1_PG=$(terraform output -raw region1_parameter_group 2>/dev/null)
REGION2_PG=$(terraform output -raw region2_parameter_group 2>/dev/null)
GROUP_UUID=$(terraform output -raw group_replication_uuid 2>/dev/null)

if [ -z "$REGION1_ADDR" ] || [ -z "$REGION2_ADDR" ]; then
    echo -e "${RED}Error: Could not get RDS endpoints from Terraform${NC}"
    echo "Make sure you've run 'terraform apply' first"
    exit 1
fi

echo -e "${GREEN}✓ Region 1: $REGION1_ADDR${NC}"
echo -e "${GREEN}✓ Region 2: $REGION2_ADDR${NC}"
echo -e "${GREEN}✓ Group UUID: $GROUP_UUID${NC}\n"

# Prompt for database password
read -sp "Enter RDS database password: " DB_PASSWORD
echo ""

if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}Error: Password cannot be empty${NC}"
    exit 1
fi

echo ""

# Prompt for replication user password
read -sp "Enter Group Replication user password (for rdsgrprepladmin): " REPL_PASSWORD
echo ""

if [ -z "$REPL_PASSWORD" ]; then
    echo -e "${RED}Error: Replication password cannot be empty${NC}"
    exit 1
fi

echo ""

# Step 1: Update Parameter Groups with group seeds (port 3306)
echo -e "${YELLOW}Step 1: Updating parameter groups with group seeds...${NC}"

echo "  Updating Region 1 parameter group..."
aws rds modify-db-parameter-group \
  --db-parameter-group-name "$REGION1_PG" \
  --parameters "ParameterName=group_replication_group_seeds,ParameterValue=${REGION1_ADDR}:3306\\,${REGION2_ADDR}:3306,ApplyMethod=immediate" \
  --region us-east-2 > /dev/null

echo "  Updating Region 2 parameter group..."
aws rds modify-db-parameter-group \
  --db-parameter-group-name "$REGION2_PG" \
  --parameters "ParameterName=group_replication_group_seeds,ParameterValue=${REGION1_ADDR}:3306\\,${REGION2_ADDR}:3306,ApplyMethod=immediate" \
  --region us-west-2 > /dev/null

echo -e "${GREEN}✓ Parameter groups updated${NC}\n"

# Step 2: Wait for parameter changes to take effect
echo -e "${YELLOW}Step 2: Waiting for parameter changes to propagate...${NC}"
echo "  ${YELLOW}This will take about 30 seconds...${NC}"
sleep 30
echo -e "${GREEN}✓ Parameters propagated${NC}\n"

# Step 3: Initialize Group Replication on Region 1
echo -e "${YELLOW}Step 3: Initializing Group Replication on Region 1...${NC}"

mysql -h "$REGION1_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED << EOF
CALL mysql.rds_set_configuration('binlog retention hours', 168);
CALL mysql.rds_group_replication_create_user('$REPL_PASSWORD');
CALL mysql.rds_group_replication_set_recovery_channel('$REPL_PASSWORD');
CALL mysql.rds_group_replication_start(1);
SELECT 'Group Replication initialized on Region 1' AS Status;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Region 1 initialized successfully${NC}\n"
else
    echo -e "${RED}✗ Failed to initialize Region 1${NC}"
    exit 1
fi

# Wait for Region 1 to stabilize
echo "  Waiting for Region 1 to stabilize..."
sleep 15

# Step 4: Join Region 2 to the group
echo -e "${YELLOW}Step 4: Joining Region 2 to the group...${NC}"

mysql -h "$REGION2_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED << EOF
CALL mysql.rds_set_configuration('binlog retention hours', 168);
CALL mysql.rds_group_replication_create_user('$REPL_PASSWORD');
CALL mysql.rds_group_replication_set_recovery_channel('$REPL_PASSWORD');
CALL mysql.rds_group_replication_start(0);
SELECT 'Region 2 joined Group Replication' AS Status;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Region 2 joined successfully${NC}\n"
else
    echo -e "${RED}✗ Failed to join Region 2${NC}"
    exit 1
fi

# Wait for replication to establish
echo "  Waiting for replication to establish..."
sleep 10

# Step 5: Verify cluster status
echo -e "${YELLOW}Step 5: Verifying cluster status...${NC}\n"

echo "Region 1 members:"
mysql -h "$REGION1_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED \
  -e "SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE FROM performance_schema.replication_group_members;" 2>/dev/null

echo ""
echo "Region 2 members:"
mysql -h "$REGION2_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED \
  -e "SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE FROM performance_schema.replication_group_members;" 2>/dev/null

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Testing replication...${NC}\n"

# Create test database and table
echo "Creating test database on Region 1..."
mysql -h "$REGION1_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED << EOF
CREATE DATABASE IF NOT EXISTS test_replication;
USE test_replication;
CREATE TABLE IF NOT EXISTS test_table (
  id INT AUTO_INCREMENT PRIMARY KEY,
  region VARCHAR(50),
  data VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO test_table (region, data) VALUES ('us-east-2', 'Initial test from Region 1');
SELECT 'Test data created' AS Status;
EOF

sleep 3

# Verify on Region 2
echo ""
echo "Verifying data replicated to Region 2..."
mysql -h "$REGION2_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED << EOF
USE test_replication;
SELECT * FROM test_table;
INSERT INTO test_table (region, data) VALUES ('us-west-2', 'Test from Region 2');
SELECT 'Test data inserted in Region 2' AS Status;
EOF

sleep 3

# Verify back on Region 1
echo ""
echo "Verifying data replicated back to Region 1..."
mysql -h "$REGION1_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED << EOF
USE test_replication;
SELECT * FROM test_table;
EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Active-Active Replication Working!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Connection Commands:${NC}"
echo "Region 1: mysql -h $REGION1_ADDR -u admin -p"
echo "Region 2: mysql -h $REGION2_ADDR -u admin -p"
echo ""
echo -e "${YELLOW}Both regions can now accept writes!${NC}"
echo ""
echo -e "${BLUE}Important Notes:${NC}"
echo "- Binary logs are retained for 7 days (168 hours) on both instances"
echo "- Group Replication user: rdsgrprepladmin"
echo "- Make sure both instances remain ONLINE in the cluster"
echo ""
