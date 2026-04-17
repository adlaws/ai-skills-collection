# AWS Troubleshooting

Common AWS issues organised by category with symptoms, diagnostic steps, and solutions.

## IAM and Permissions

### Access Denied (403)

**Symptom:** API call returns `AccessDenied` or `UnauthorizedAccess`.

**Steps:**

1. Identify the exact action and resource from the error message
2. Check which principal is making the call:
   ```bash
   aws sts get-caller-identity
   ```
3. Review the identity's policies (inline + attached + group + permissions boundary)
4. Check for explicit denies in SCPs (Organizations), resource policies, or session policies
5. Use IAM Policy Simulator to test:
   ```bash
   aws iam simulate-principal-policy \
     --policy-source-arn arn:aws:iam::123456789012:role/my-role \
     --action-names s3:GetObject \
     --resource-arns arn:aws:s3:::my-bucket/key
   ```
6. Check CloudTrail for the denied event — the `errorCode` and `errorMessage` fields give details

**Common causes:**

* Missing action in the policy (e.g., `s3:ListBucket` vs `s3:GetObject` — different resource ARN patterns)
* S3 bucket policy denying access (explicit deny overrides identity policy allows)
* SCP restricting the action at the organization level
* Wrong resource ARN (bucket ARN vs object ARN)
* Condition key mismatch (region, IP, MFA, tag)
* KMS key policy not granting `kms:Decrypt` to the calling principal

### AssumeRole Fails

**Symptom:** `AccessDenied` when calling `sts:AssumeRole`.

**Steps:**

1. Verify the role's trust policy allows the calling principal
2. Verify the calling principal has `sts:AssumeRole` permission for the role ARN
3. Check for condition keys in the trust policy (e.g., `sts:ExternalId`, `aws:PrincipalOrgID`)
4. If cross-account, ensure both sides are configured

## EC2

### Instance Won't Start

**Symptom:** Instance stuck in `pending` or immediately goes to `shutting-down`/`terminated`.

**Steps:**

1. Check the instance state reason:
   ```bash
   aws ec2 describe-instances --instance-ids i-xxx \
     --query 'Reservations[].Instances[].StateReason'
   ```
2. Check system log and screenshot:
   ```bash
   aws ec2 get-console-output --instance-id i-xxx
   ```
3. Common causes:
   * **InsufficientInstanceCapacity** — try a different AZ or instance type
   * **InstanceLimitExceeded** — request a quota increase
   * **InvalidAMI** — AMI doesn't exist or you don't have permission
   * **EBS volume limit** — check volume quotas

### Can't SSH to Instance

**Symptom:** Connection times out or is refused.

**Steps:**

1. Verify the instance is running and has a public IP (or you're connecting via private IP/SSM)
2. Check security group allows inbound TCP 22 from your IP
3. Check NACL allows inbound TCP 22 AND outbound ephemeral ports (1024-65535)
4. Check route table — public subnet needs a route to the IGW
5. Verify the key pair matches
6. Check OS-level firewall (`iptables`, `firewalld`)
7. **Alternative:** Use SSM Session Manager (no port 22 needed, no key pair needed)

### Instance Metadata Unavailable

**Symptom:** `curl http://169.254.169.254/latest/meta-data/` times out or returns 401.

**Steps:**

1. Check if IMDSv2 is enforced (instance requires a token):
   ```bash
   TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
   curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/
   ```
2. Check the `HttpEndpoint` setting on the instance (must be `enabled`)
3. If running in a container, the hop limit may need increasing (`HttpPutResponseHopLimit: 2`)

## Networking / VPC

### No Internet Access from Private Subnet

**Symptom:** Instances in private subnets can't reach the internet.

**Steps:**

1. Verify a NAT Gateway exists in a public subnet
2. Check the private subnet's route table has `0.0.0.0/0 → nat-gw-xxx`
3. Verify the NAT Gateway's subnet route table has `0.0.0.0/0 → igw-xxx`
4. Check the NAT Gateway status is `available`
5. Check security group allows outbound traffic on the needed ports
6. Check NACL allows outbound + inbound ephemeral ports

### VPC Peering Not Working

**Symptom:** Instances in peered VPCs can't communicate.

**Steps:**

1. Verify peering connection status is `active`
2. Check route tables in BOTH VPCs have routes to the peer CIDR via the peering connection
3. Check security groups in BOTH VPCs allow traffic from the peer CIDR
4. Check NACLs in both VPCs
5. Verify CIDR blocks don't overlap
6. DNS resolution: enable DNS resolution for the peering connection if using private DNS names

### Security Group Not Working as Expected

**Symptom:** Traffic is blocked despite security group rules appearing correct.

**Steps:**

1. Confirm the security group is attached to the correct ENI/instance
2. Remember: security groups are stateful (return traffic is auto-allowed)
3. Check you're referencing the correct security group ID in source/destination rules
4. Self-referencing rule: a security group can reference itself (e.g., allow cluster communication)
5. Check if the instance has multiple ENIs with different security groups

## S3

### 403 Forbidden on S3 Object

**Symptom:** `AccessDenied` when accessing an S3 object.

**Steps:**

1. Check the bucket policy for explicit denies
2. Check S3 Block Public Access settings (account and bucket level)
3. Verify the IAM policy allows the correct actions on the correct ARN:
   * `s3:ListBucket` → bucket ARN (`arn:aws:s3:::bucket`)
   * `s3:GetObject` → object ARN (`arn:aws:s3:::bucket/*`)
4. If SSE-KMS encrypted, the caller needs `kms:Decrypt` on the key
5. If cross-account, both the bucket policy AND the caller's IAM policy must allow access
6. Check for VPC endpoint policy restrictions (if using a gateway endpoint)

### S3 Upload Fails (Large Files)

**Symptom:** Upload hangs or fails for files over 5 GB.

**Steps:**

1. Use multipart upload for files > 100 MB (required for > 5 GB):
   ```bash
   aws s3 cp large-file.tar.gz s3://bucket/ --expected-size $(stat -c%s large-file.tar.gz)
   ```
2. AWS CLI automatically uses multipart for large files
3. Check for incomplete multipart uploads consuming storage:
   ```bash
   aws s3api list-multipart-uploads --bucket my-bucket
   ```
4. Set a lifecycle rule to abort incomplete multipart uploads after N days

## Lambda

### Function Timeout

**Symptom:** Function exits with `Task timed out after X seconds`.

**Steps:**

1. Increase the timeout (max 15 minutes)
2. Check if the function is waiting on a network call that's timing out:
   * VPC-attached Lambda needs NAT Gateway for internet access
   * Check security groups allow outbound on required ports
3. Look for synchronous calls that could be made async
4. If processing large data, consider increasing memory (also increases CPU)
5. For long-running work, consider Step Functions or SQS + Lambda

### Lambda Can't Access VPC Resource

**Symptom:** Lambda times out when trying to reach RDS, ElastiCache, or other VPC resources.

**Steps:**

1. Verify Lambda is configured with VPC, subnets, and security group
2. Lambda needs subnets with NAT Gateway route for internet access (or VPC endpoints for AWS services)
3. Check security group of the target resource allows inbound from Lambda's security group
4. Lambda execution role needs `ec2:CreateNetworkInterface`, `ec2:DescribeNetworkInterfaces`, `ec2:DeleteNetworkInterface`
5. Check subnet has available IP addresses (Lambda creates ENIs in the subnets)

### Cold Start Latency

**Symptom:** First invocation is significantly slower than subsequent ones.

**Steps:**

1. Keep function package small — remove unnecessary dependencies
2. Increase memory allocation (faster CPU = faster init)
3. Use provisioned concurrency for latency-sensitive functions
4. For Java: use SnapStart; consider GraalVM native image
5. Initialise SDK clients and database connections outside the handler (in module scope)
6. Avoid VPC attachment if not needed (VPC Lambda cold starts have improved but still add some latency)

## CloudFormation

### Stack Stuck in UPDATE_ROLLBACK_FAILED

**Symptom:** Stack is in `UPDATE_ROLLBACK_FAILED` state and can't be updated or deleted.

**Steps:**

1. Check the Events tab for the specific resource that failed to roll back
2. Manually fix the underlying issue (e.g., the resource was manually deleted)
3. Continue the rollback skipping the problematic resources:
   ```bash
   aws cloudformation continue-update-rollback --stack-name my-stack \
     --resources-to-skip LogicalResourceId1
   ```
4. If that doesn't work, delete the stack with `--retain-resources` for the problematic ones

### Circular Dependency

**Symptom:** Template validation error about circular dependency.

**Steps:**

1. Identify the cycle (A depends on B which depends on A)
2. Break the cycle by:
   * Using `DependsOn` only where truly needed
   * Splitting resources into separate stacks with cross-stack references (`Fn::ImportValue`)
   * Using `Fn::GetAtt` on the specific attribute rather than the full resource

## Useful Diagnostic Commands

| Command | Purpose |
|---------|---------|
| `aws sts get-caller-identity` | Confirm which identity you are using |
| `aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=<event>` | Find recent API calls |
| `aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"` | List running instances |
| `aws logs filter-log-events --log-group-name /aws/lambda/my-func --start-time $(date -d '1 hour ago' +%s)000` | Recent Lambda logs |
| `aws ec2 describe-network-interfaces --filters "Name=group-id,Values=sg-xxx"` | Find ENIs using a security group |
| `aws iam simulate-principal-policy ...` | Test IAM permissions |
| `aws s3api get-bucket-policy --bucket my-bucket` | View S3 bucket policy |
| `aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxx"` | VPC route tables |
| `aws cloudformation describe-stack-events --stack-name my-stack` | Stack event history |
| `nslookup <endpoint>` | DNS resolution check |
| `nc -zv <host> <port>` | TCP connectivity check |
