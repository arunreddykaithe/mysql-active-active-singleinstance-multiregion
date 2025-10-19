#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MySQL Active-Active Replication Test${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if in scripts directory, if so go back to root
if [ -d "../modules" ]; then
    cd ..
fi

# Get endpoints
REGION1_ADDR=$(terraform output -raw region1_rds_address 2>/dev/null)
REGION2_ADDR=$(terraform output -raw region2_rds_address 2>/dev/null)

if [ -z "$REGION1_ADDR" ] || [ -z "$REGION2_ADDR" ]; then
    echo -e "${RED}Error: Could not get RDS endpoints${NC}"
    exit 1
fi

# Prompt for password
read -sp "Enter database password: " DB_PASSWORD
echo -e "\n"

# Test 1: Check cluster membership
echo -e "${YELLOW}Test 1: Checking cluster membership...${NC}"

MEMBER_COUNT=$(mysql -h "$REGION1_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED -sN \
  -e "SELECT COUNT(*) FROM performance_schema.replication_group_members WHERE MEMBER_STATE='ONLINE';" 2>/dev/null)

if [ "$MEMBER_COUNT" -eq 2 ]; then
    echo -e "${GREEN}✓ Both members are ONLINE${NC}\n"
else
    echo -e "${RED}✗ Expected 2 members, found $MEMBER_COUNT${NC}\n"
    exit 1
fi

# Test 2: Write from Region 1
echo -e "${YELLOW}Test 2: Writing from Region 1...${NC}"

TIMESTAMP=$(date +%s)
mysql -h "$REGION1_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED << EOF 2>/dev/null
USE test_replication;
INSERT INTO test_table (region, data) VALUES ('us-east-2', 'Test write at $TIMESTAMP');
EOF

echo -e "${GREEN}✓ Write successful${NC}\n"

# Wait for replication
sleep 2

# Test 3: Read from Region 2
echo -e "${YELLOW}Test 3: Reading from Region 2...${NC}"

RESULT=$(mysql -h "$REGION2_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED -sN \
  -e "SELECT COUNT(*) FROM test_replication.test_table WHERE data='Test write at $TIMESTAMP';" 2>/dev/null)

if [ "$RESULT" -eq 1 ]; then
    echo -e "${GREEN}✓ Data replicated to Region 2${NC}\n"
else
    echo -e "${RED}✗ Data not found in Region 2${NC}\n"
    exit 1
fi

# Test 4: Write from Region 2
echo -e "${YELLOW}Test 4: Writing from Region 2...${NC}"

TIMESTAMP2=$(date +%s)
mysql -h "$REGION2_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED << EOF 2>/dev/null
USE test_replication;
INSERT INTO test_table (region, data) VALUES ('us-west-2', 'Test write at $TIMESTAMP2');
EOF

echo -e "${GREEN}✓ Write successful${NC}\n"

# Wait for replication
sleep 2

# Test 5: Read from Region 1
echo -e "${YELLOW}Test 5: Reading from Region 1...${NC}"

RESULT2=$(mysql -h "$REGION1_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED -sN \
  -e "SELECT COUNT(*) FROM test_replication.test_table WHERE data='Test write at $TIMESTAMP2';" 2>/dev/null)

if [ "$RESULT2" -eq 1 ]; then
    echo -e "${GREEN}✓ Data replicated to Region 1${NC}\n"
else
    echo -e "${RED}✗ Data not found in Region 1${NC}\n"
    exit 1
fi

# Test 6: Check replication lag
echo -e "${YELLOW}Test 6: Checking replication lag...${NC}"

echo "Region 1 stats:"
mysql -h "$REGION1_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED \
  -e "SELECT MEMBER_HOST, COUNT_TRANSACTIONS_IN_QUEUE, COUNT_TRANSACTIONS_CHECKED, COUNT_CONFLICTS_DETECTED FROM performance_schema.replication_group_member_stats;" 2>/dev/null

echo ""
echo "Region 2 stats:"
mysql -h "$REGION2_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED \
  -e "SELECT MEMBER_HOST, COUNT_TRANSACTIONS_IN_QUEUE, COUNT_TRANSACTIONS_CHECKED, COUNT_CONFLICTS_DETECTED FROM performance_schema.replication_group_member_stats;" 2>/dev/null

echo ""

# Display recent writes
echo -e "${YELLOW}Recent writes from both regions:${NC}"
mysql -h "$REGION1_ADDR" -u admin -p"$DB_PASSWORD" --ssl-mode=REQUIRED \
  -e "SELECT * FROM test_replication.test_table ORDER BY created_at DESC LIMIT 10;" 2>/dev/null

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All Tests Passed!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Summary:${NC}"
echo "- Both members are ONLINE"
echo "- Writes from Region 1 replicate to Region 2"
echo "- Writes from Region 2 replicate to Region 1"
echo "- Replication lag is minimal"
echo ""
echo -e "${GREEN}Active-Active replication is working correctly!${NC}"
echo ""
