# 📋 Deployment Checklist - MySQL Active-Active

Use this checklist to ensure proper deployment and configuration.

## ✅ Pre-Deployment

### Environment Setup
- [ ] Terraform >= 1.0 installed and working
- [ ] AWS CLI configured with valid credentials
- [ ] MySQL client installed (version 8.0+)
- [ ] Access to both us-east-1 and us-west-2 regions confirmed
- [ ] IAM permissions verified (VPC, RDS, EC2, IAM roles)

### Network Planning
- [ ] Reviewed existing VPCs in both regions
- [ ] Confirmed CIDR ranges don't overlap (default: 10.10.0.0/24, 10.11.0.0/24)
- [ ] Verified CIDRs are all below 128.0.0.0 (required for peering)
- [ ] Planned IP allocation (32 IPs per subnet × 3 subnets = 96 IPs per region)

### Configuration Review
- [ ] Copied all 21 files to correct locations
- [ ] Edited `terraform.tfvars` with custom password
- [ ] Reviewed instance class (db.t3.medium default)
- [ ] Set appropriate `allowed_cidr_blocks` for security
- [ ] Decided on `db_publicly_accessible` setting
- [ ] Configured `skip_final_snapshot` based on environment

## ✅ Deployment Phase

### Terraform Initialization
- [ ] Ran `terraform init` successfully
- [ ] Provider plugins downloaded
- [ ] No initialization errors

### Infrastructure Planning
- [ ] Ran `terraform plan` successfully
- [ ] Reviewed plan shows ~24 resources to create
- [ ] No unexpected resource changes
- [ ] Verified VPC CIDRs in plan output
- [ ] Confirmed RDS MySQL version is 8.0.39

### Infrastructure Deployment
- [ ] Ran `terraform apply`
- [ ] Typed 'yes' to confirm
- [ ] Waited ~10-15 minutes for completion
- [ ] No errors during deployment
- [ ] All 24 resources created successfully

### Output Verification
- [ ] Ran `terraform output` and saved values
- [ ] Noted Region 1 RDS endpoint
- [ ] Noted Region 2 RDS endpoint
- [ ] Noted Group Replication UUID
- [ ] Noted VPC IDs and CIDR blocks
- [ ] Noted VPC peering connection ID

## ✅ Group Replication Setup

### Automated Setup
- [ ] Made setup script executable (`chmod +x scripts/*.sh`)
- [ ] Ran `./scripts/setup_replication.sh`
- [ ] Entered database password when prompted
- [ ] Script updated parameter groups successfully
- [ ] Instances rebooted (waited ~5 minutes)
- [ ] Region 1 initialized as bootstrap member
- [ ] Region 2 joined the group successfully
- [ ] Both members show as ONLINE

### Manual Verification
- [ ] Connected to Region 1 MySQL instance
- [ ] Ran: `SELECT * FROM performance_schema.replication_group_members;`
- [ ] Confirmed 2 members with MEMBER_STATE='ONLINE'
- [ ] Connected to Region 2 MySQL instance
- [ ] Ran same query, confirmed 2 members ONLINE
- [ ] Both instances show correct MEMBER_ROLE

## ✅ Replication Testing

### Test Script
- [ ] Ran `./scripts/test_replication.sh`
- [ ] All 6 tests passed:
  - [ ] Test 1: Cluster membership ✓
  - [ ] Test 2: Write from Region 1 ✓
  - [ ] Test 3: Read from Region 2 ✓
  - [ ] Test 4: Write from Region 2 ✓
  - [ ] Test 5: Read from Region 1 ✓
  - [ ] Test 6: Replication lag check ✓

### Manual Testing
- [ ] Created test database on Region 1
- [ ] Inserted test data on Region 1
- [ ] Verified data appeared on Region 2 (< 2 seconds)
- [ ] Inserted test data on Region 2
- [ ] Verified data appeared on Region 1 (< 2 seconds)
- [ ] Confirmed bidirectional replication working

### Replication Health
- [ ] No conflicts detected (COUNT_CONFLICTS_DETECTED = 0)
- [ ] Transaction queue empty or minimal
- [ ] Replication lag < 1 second
- [ ] No error messages in CloudWatch logs

## ✅ Security Review

### Network Security
- [ ] VPC peering connection is active
- [ ] Security groups allow port 3306 (MySQL)
- [ ] Security groups allow port 33061 (Group Replication)
- [ ] Security group rules are appropriately restrictive
- [ ] No overly permissive 0.0.0.0/0 rules in production

### RDS Security
- [ ] Storage encryption enabled (default)
- [ ] SSL/TLS connections working
- [ ] Master password is strong and secure
- [ ] Master password stored in password manager
- [ ] No default passwords in use
- [ ] Backup retention configured (default: 7 days)

### IAM Security
- [ ] RDS monitoring role created with correct permissions
- [ ] No overly permissive IAM policies
- [ ] CloudWatch logs properly configured

## ✅ Monitoring Setup

### CloudWatch
- [ ] RDS instances visible in CloudWatch
- [ ] CPU utilization metric available
- [ ] Database connections metric available
- [ ] Storage metrics available
- [ ] Set up alarms for:
  - [ ] High CPU usage (>80%)
  - [ ] Low free storage (<20%)
  - [ ] High connection count
  - [ ] Replication lag (>5 seconds)

### RDS Events
- [ ] Subscribed to RDS events
- [ ] Email notifications configured
- [ ] Event categories selected (failure, maintenance, recovery)

### Application Monitoring
- [ ] Application can connect to both regions
- [ ] Connection pooling configured
- [ ] Failover logic implemented (if applicable)
- [ ] Query performance acceptable

## ✅ Backup & Recovery

### Automated Backups
- [ ] Automated backups enabled (retention: 7 days default)
- [ ] Backup window configured (default: 03:00-04:00 UTC)
- [ ] Backups occurring successfully
- [ ] Can see backup snapshots in RDS console

### Manual Snapshots
- [ ] Created manual snapshot of Region 1
- [ ] Created manual snapshot of Region 2
- [ ] Snapshots completed successfully
- [ ] Documented snapshot IDs

### Recovery Testing
- [ ] Documented recovery procedures
- [ ] Tested snapshot restore (optional but recommended)
- [ ] Verified RTO (Recovery Time Objective)
- [ ] Verified RPO (Recovery Point Objective)

## ✅ Documentation

### Infrastructure Documentation
- [ ] Documented all resource IDs
- [ ] Saved terraform outputs
- [ ] Created network diagram
- [ ] Documented CIDR allocations
- [ ] Recorded Group Replication UUID

### Access Documentation
- [ ] Documented connection strings
- [ ] Stored credentials securely
- [ ] Created runbook for common operations
- [ ] Documented troubleshooting steps

### Team Communication
- [ ] Notified team of new infrastructure
- [ ] Shared connection details securely
- [ ] Scheduled knowledge transfer session
- [ ] Updated team wiki/documentation

## ✅ Production Readiness

### Performance
- [ ] Instance class appropriate for workload
- [ ] Storage size adequate
- [ ] Replication lag acceptable (<1 second)
- [ ] Connection pool sizes configured
- [ ] Query performance tested under load

### High Availability
- [ ] Both regions operational
- [ ] Automatic failover tested (optional)
- [ ] Recovery procedures documented
- [ ] On-call rotation established
- [ ] Monitoring alerts configured

### Compliance
- [ ] Data encryption at rest enabled
- [ ] Data encryption in transit enforced
- [ ] Audit logging enabled
- [ ] Compliance requirements met
- [ ] Security review completed

### Cost Optimization
- [ ] Instance sizes appropriate (not over-provisioned)
- [ ] Storage autoscaling configured if needed
- [ ] Reserved instances considered for long-term
- [ ] Cost alerts configured
- [ ] Monthly budget established

## ✅ Post-Deployment

### Day 1 Checks
- [ ] All services running normally
- [ ] No errors in CloudWatch logs
- [ ] Replication lag within acceptable range
- [ ] Application performance normal
- [ ] No alerts triggered

### Week 1 Checks
- [ ] Monitor daily for issues
- [ ] Review CloudWatch metrics
- [ ] Check replication health daily
- [ ] Verify backups completing
- [ ] Review cost reports

### Month 1 Checks
- [ ] Capacity planning review
- [ ] Performance optimization opportunities
- [ ] Security audit
- [ ] Cost optimization review
- [ ] Disaster recovery drill

## 📝 Sign-Off

**Deployment Date:** _______________

**Deployed By:** _______________

**Reviewed By:** _______________

**Production Approved:** _______________

---

## 🚨 Issues Encountered

Document any issues during deployment:

| Issue | Resolution | Date | Notes |
|-------|------------|------|-------|
|       |            |      |       |
|       |            |      |       |
|       |            |      |       |

---

## 📞 Support Contacts

**AWS Support:** _______________

**Database Team:** _______________

**On-Call Engineer:** _______________

**Escalation Contact:** _______________

---

## 🎯 Success Criteria

✅ All checklist items completed
✅ Both regions operational
✅ Bidirectional replication working
✅ No critical alerts
✅ Team notified and trained
✅ Documentation complete

---

**Status:** [ ] IN PROGRESS  [ ] COMPLETE  [ ] BLOCKED

**Notes:** ________________________________
