# 🚀 Quick Start Guide - MySQL Active-Active

Get your MySQL active-active cross-region replication running in **15 minutes**!

## ⚡ Prerequisites Check

Before starting, verify you have:

```bash
# Terraform installed
terraform --version
# Should show: Terraform v1.0.0 or higher

# AWS CLI configured
aws --version
aws sts get-caller-identity
# Should show your AWS account details

# MySQL client installed
mysql --version
# Should show: mysql Ver 8.0 or higher
```

## 📝 Step-by-Step Setup

### Step 1: Create Directory Structure (30 seconds)

```bash
mkdir -p mysql-active-active/{modules/{vpc,rds,peering},scripts}
cd mysql-active-active
```

### Step 2: Copy All Files (2 minutes)

Copy all 21 files from the artifacts to the correct locations:

```
mysql-active-active/
├── providers.tf
├── variables.tf
├── data.tf
├── outputs.tf
├── region1.tf
├── region2.tf
├── peering.tf
├── terraform.tfvars
├── .gitignore
├── README.md
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── peering/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── scripts/
    ├── setup_replication.sh
    ├── test_replication.sh
    └── cleanup.sh
```

### Step 3: Configure (1 minute)

Edit `terraform.tfvars`:

```bash
# Change ONLY this line:
db_password = "YourSecurePassword123!"
```

**That's it!** The defaults are production-ready.

### Step 4: Initialize Terraform (30 seconds)

```bash
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 5: Preview Changes (30 seconds)

```bash
terraform plan
```

Expected output:
```
Plan: 24 to add, 0 to change, 0 to destroy.
```

### Step 6: Deploy Infrastructure (10 minutes)

```bash
terraform apply
```

Type `yes` when prompted.

**☕ Grab coffee - this takes ~10 minutes** (RDS instances are slow to provision)

Expected output:
```
Apply complete! Resources: 24 added, 0 changed, 0 destroyed.
```

### Step 7: Configure Group Replication (3 minutes)

```bash
cd scripts
chmod +x *.sh
./setup_replication.sh
```

Enter your database password when prompted.

Expected output:
```
✓ Active-Active Replication Working!
```

### Step 8: Test It! (30 seconds)

```bash
./test_replication.sh
```

Expected output:
```
✓ All Tests Passed!
```

## ✅ Success!

You now have:
- ✅ Two RDS MySQL instances in different regions
- ✅ Both accepting writes simultaneously
- ✅ Sub-second replication between regions
- ✅ Automatic failover capability

## 🎯 Try It Out

### Connect to Region 1:
```bash
mysql -h $(cd .. && terraform output -raw region1_rds_address) -u admin -p
```

### Test active-active replication:
```sql
-- On Region 1
CREATE DATABASE demo;
USE demo;
CREATE TABLE test (id INT, data VARCHAR(100));
INSERT INTO test VALUES (1, 'Hello from us-east-1!');
```

Now connect to Region 2 and check:
```bash
mysql -h $(cd .. && terraform output -raw region2_rds_address) -u admin -p
```

```sql
-- On Region 2
USE demo;
SELECT * FROM test;  -- Should see the data!

-- Write from Region 2
INSERT INTO test VALUES (2, 'Hello from us-west-2!');
```

Back on Region 1:
```sql
SELECT * FROM test;  -- Should see BOTH rows!
```

## 📊 What You've Created

### Network Architecture
```
Region 1 (us-east-1)          Region 2 (us-west-2)
├─ VPC: 10.10.0.0/24          ├─ VPC: 10.11.0.0/24
├─ 3 Subnets (32 IPs each)    ├─ 3 Subnets (32 IPs each)
├─ Internet Gateway           ├─ Internet Gateway
├─ Security Groups            ├─ Security Groups
└─ RDS MySQL 8.0.39           └─ RDS MySQL 8.0.39
        ↕ VPC Peering ↕
   (sub-second replication)
```

### Monthly Cost
**~$173/month** for the complete setup (both regions)

## 🛠️ Common Commands

```bash
# View all outputs
terraform output

# Get connection strings
terraform output region1_mysql_command
terraform output region2_mysql_command

# Check infrastructure status
terraform show

# View specific output
terraform output region1_rds_address

# Test replication
cd scripts && ./test_replication.sh

# Cleanup everything
cd scripts && ./cleanup.sh
```

## 🐛 Troubleshooting

### Issue: "CIDR blocks overlap"

**Solution:** Your VPCs already use 10.10.0.0/24 or 10.11.0.0/24.

Edit `terraform.tfvars`:
```hcl
region1_vpc_cidr = "10.20.0.0/24"  # Different range
region2_vpc_cidr = "10.21.0.0/24"  # Different range

region1_subnet_cidrs = ["10.20.0.0/27", "10.20.0.32/27", "10.20.0.64/27"]
region2_subnet_cidrs = ["10.21.0.0/27", "10.21.0.32/27", "10.21.0.64/27"]
```

### Issue: "Can't connect to database"

**Check security group:**
```bash
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=mysql-active-us-east-1-rds-sg" \
  --query 'SecurityGroups[*].IpPermissions'
```

**Test connectivity:**
```bash
telnet $(terraform output -raw region1_rds_address) 3306
```

### Issue: "Group Replication won't start"

**Verify parameter groups:**
```bash
aws rds describe-db-parameters \
  --db-parameter-group-name mysql-active-us-east-1-pg \
  --query 'Parameters[?ParameterName==`group_replication_group_seeds`]'
```

**Re-run setup:**
```bash
cd scripts && ./setup_replication.sh
```

## 🧹 Cleanup

To destroy everything:

```bash
cd scripts
./cleanup.sh
```

Type `yes` and `DELETE` when prompted.

**Warning:** This deletes ALL data!

## 📚 Next Steps

1. **Read the full README.md** for detailed documentation
2. **Review security settings** for production use
3. **Set up monitoring** with CloudWatch
4. **Configure backups** and snapshots
5. **Implement application failover** logic

## 🎓 Key Concepts

### Active-Active Replication
- Both regions accept **writes** simultaneously
- Data replicates in **sub-second** timeframes
- Conflicts resolved via **last-write-wins**
- Automatic **failover** if one region fails

### Group Replication
- MySQL's native multi-master replication
- Supports up to **9 instances** globally
- **Distributed consensus** for consistency
- **ACID guarantees** with eventual consistency

### Network Design
- **Non-overlapping CIDRs** required for peering
- **VPC Peering** for private connectivity
- **Security groups** control access
- **Multi-AZ** subnets for redundancy

## 💡 Pro Tips

1. **Start small:** Use `db.t3.small` for testing (~$85/month)
2. **Test writes:** Always verify bidirectional replication
3. **Monitor lag:** Check `replication_group_member_stats` regularly
4. **Plan capacity:** Each subnet has 32 IPs (plenty for RDS)
5. **Secure production:** Set `db_publicly_accessible = false`

## ✨ You're Ready!

You now have a production-ready MySQL active-active cluster!

**Questions?** Check the full README.md

**Issues?** Review the Troubleshooting section

**Ready for production?** Review the security checklist in README.md

---

**Happy clustering!** 🚀
