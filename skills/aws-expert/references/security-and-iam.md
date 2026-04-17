# AWS Security and IAM

Reference for AWS identity, access management, encryption, and security best practices.

## IAM (Identity and Access Management)

### Core Concepts

| Concept | Description |
|---------|-------------|
| **User** | Identity for a person or application; has long-term credentials |
| **Group** | Collection of users; policies attached to the group apply to all members |
| **Role** | Identity assumed temporarily; no long-term credentials; used by services, applications, and cross-account access |
| **Policy** | JSON document defining permissions (allow/deny actions on resources) |
| **Principal** | Entity that can make requests (user, role, service, federated identity) |

### Policy Evaluation Logic

```
1. Explicit Deny?           → DENY (always wins)
2. SCP allows?              → Continue (Organizations only)
3. Resource policy allows?  → ALLOW (for same-account)
4. Permissions boundary?    → Intersect with identity policy
5. Identity policy allows?  → ALLOW
6. Default                  → DENY (implicit)
```

**Key rule:** Explicit deny always wins. Everything not explicitly allowed is implicitly denied.

### Policy Structure

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-southeast-2"
        }
      }
    }
  ]
}
```

**Policy types:**

| Type | Attached To | Use Case |
|------|-------------|----------|
| Identity-based | Users, groups, roles | Grant permissions to an identity |
| Resource-based | S3 buckets, SQS, KMS, etc. | Grant cross-account access, service access |
| Permissions boundary | Users, roles | Cap the maximum permissions an identity can have |
| SCP | Organization OUs/accounts | Guardrails across an entire org |
| Session policy | Assumed role session | Further restrict a session |

### IAM Best Practices

* **Never use root account** for day-to-day operations; protect with MFA
* **Use roles, not users** for applications and services — no long-term credentials
* **Least privilege** — grant only the permissions needed; start restrictive and expand
* **Use IAM Identity Center (SSO)** for human access; federate with your IdP
* **Enable MFA** for all human users, especially privileged ones
* **Rotate credentials** — if access keys are necessary, rotate regularly
* **Use conditions** — restrict by IP, region, MFA, tags, or time
* **Audit with Access Analyzer** — identify unused permissions and public/cross-account access

### Common Patterns

#### Cross-Account Access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::111111111111:role/their-role"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

The trusted account creates a role with this trust policy. The trusting identity calls `sts:AssumeRole` to get temporary credentials.

#### Service-Linked Roles

Pre-defined roles that AWS services use to call other services on your behalf. Created automatically (e.g., `AWSServiceRoleForECS`). Cannot be modified.

#### OIDC Federation (e.g., GitHub Actions)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:*"
        }
      }
    }
  ]
}
```

## Encryption

### Encryption at Rest

| Service | Default Encryption | KMS Integration |
|---------|-------------------|-----------------|
| S3 | SSE-S3 (AES-256) enabled by default | SSE-KMS for key control and audit |
| EBS | Optional at volume creation | Yes — default or custom CMK |
| RDS | Optional at instance creation | Yes — cannot enable after creation |
| DynamoDB | Encrypted by default | AWS owned key, AWS managed key, or CMK |
| EFS | Optional at creation | Yes |
| SQS | Optional | SSE-KMS or SSE-SQS |

### KMS (Key Management Service)

* **Customer managed keys (CMK)** — you create, control rotation, and set key policies
* **AWS managed keys** — created automatically by services (e.g., `aws/s3`); AWS manages rotation
* **Key policies** — resource-based policies controlling who can use and manage the key
* **Envelope encryption** — KMS generates a data key; you encrypt data with the data key; KMS encrypts the data key. Only the encrypted data key is stored alongside the ciphertext.
* **Automatic rotation** — enable annual rotation for customer managed symmetric keys
* **Grants** — temporary, scoped permissions for keys (useful for services)

### Encryption in Transit

* **TLS everywhere** — all AWS API endpoints use TLS 1.2+
* **ACM (Certificate Manager)** — free public TLS certificates for ALB, CloudFront, API Gateway; auto-renewal
* **VPN / Direct Connect** — encrypted connections to on-premises
* **S3** — enforce TLS with bucket policy condition `aws:SecureTransport`

## Security Services

### AWS Security Hub

Centralised security findings from GuardDuty, Inspector, Macie, Firewall Manager, IAM Access Analyzer, and third-party tools. Runs automated compliance checks against CIS and AWS Foundational Security Best Practices.

### GuardDuty

Threat detection using ML, anomaly detection, and threat intelligence. Analyses VPC Flow Logs, DNS logs, CloudTrail events, S3 data events, EKS audit logs. No agents to install.

### Inspector

Automated vulnerability scanning for EC2 instances, Lambda functions, and container images in ECR. Checks for software CVEs and network reachability issues.

### Macie

Discovers and protects sensitive data (PII, credentials, financial data) in S3 using ML and pattern matching.

### WAF (Web Application Firewall)

Protects CloudFront, ALB, API Gateway, and AppSync from common web exploits.

* **Managed rule groups** — AWS and marketplace rules for OWASP Top 10, bots, known bad IPs
* **Custom rules** — rate limiting, geo-blocking, IP allow/deny, string matching
* **Rate-based rules** — automatically block IPs exceeding a request threshold

### Secrets Manager

* Store and rotate database credentials, API keys, tokens
* Automatic rotation via Lambda functions (built-in for RDS)
* Cross-account access via resource policies
* Integrates with RDS, Redshift, DocumentDB for seamless credential rotation

### AWS Config

* Continuously records resource configurations and changes
* **Config Rules** — evaluate whether resources comply with desired configuration (e.g., "all S3 buckets must have encryption enabled")
* **Remediation** — automatically fix non-compliant resources via SSM Automation
* **Conformance Packs** — collections of Config Rules for compliance frameworks

## Shared Responsibility Model

| AWS Responsibility | Customer Responsibility |
|---|---|
| Physical security of data centres | IAM users, groups, roles, policies |
| Hardware, networking, virtualisation | Security group and NACL configuration |
| Managed service infrastructure | Data encryption and key management |
| Patching managed service OS/runtime | Application code security |
| Global network security | OS patching (EC2) |
| Compliance of infrastructure | Client-side data protection |

## Security Checklist

* [ ] Root account has MFA; no access keys
* [ ] IAM Identity Center configured for human access
* [ ] Roles used for all application/service access (no long-term keys)
* [ ] CloudTrail enabled in all regions, logging to centralised S3 bucket
* [ ] GuardDuty enabled in all regions
* [ ] S3 Block Public Access enabled at account level
* [ ] Default EBS encryption enabled per region
* [ ] VPC Flow Logs enabled
* [ ] Security Hub enabled with AWS Foundational Best Practices standard
* [ ] AWS Config recording enabled
* [ ] Secrets in Secrets Manager or Parameter Store (never in code)
* [ ] WAF in front of public-facing endpoints
