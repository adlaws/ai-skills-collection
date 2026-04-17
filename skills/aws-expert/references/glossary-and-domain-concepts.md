# AWS Glossary and Domain Concepts

Key AWS terminology, acronyms, and concepts.

## Core Concepts

| Term | Definition |
|------|-----------|
| **Region** | Geographic area with 2+ Availability Zones (e.g., `us-east-1`, `ap-southeast-2`). Services and data stay within a region unless explicitly replicated. |
| **Availability Zone (AZ)** | One or more discrete data centres within a region, with independent power, cooling, and networking. Identified as `us-east-1a`, `us-east-1b`, etc. |
| **Edge Location** | CloudFront/Route 53 point of presence for caching and DNS. 450+ globally. |
| **Local Zone** | Extension of a region placed closer to users for low-latency workloads. |
| **Wavelength Zone** | AWS infrastructure within telecom carrier data centres for ultra-low latency mobile/5G apps. |
| **ARN** | Amazon Resource Name — unique identifier for any AWS resource. Format: `arn:aws:service:region:account-id:resource-type/resource-id` |
| **Account** | An AWS account is the basic container for resources, billing, and access control. Each account has a unique 12-digit ID. |
| **Partition** | Isolated AWS infrastructure groupings: `aws` (standard), `aws-cn` (China), `aws-us-gov` (GovCloud). |

## Networking Terms

| Term | Definition |
|------|-----------|
| **VPC** | Virtual Private Cloud — logically isolated virtual network. |
| **CIDR** | Classless Inter-Domain Routing — notation for IP address ranges (e.g., `10.0.0.0/16`). |
| **Subnet** | Segment of a VPC in a single AZ. |
| **IGW** | Internet Gateway — enables internet access for a VPC. |
| **NAT Gateway** | Network Address Translation gateway — allows private subnet outbound internet access. |
| **ENI** | Elastic Network Interface — virtual network card attached to an instance. |
| **EIP** | Elastic IP — static public IPv4 address. |
| **Security Group** | Stateful firewall at the instance level (allow rules only). |
| **NACL** | Network Access Control List — stateless firewall at the subnet level (allow and deny rules). |
| **Transit Gateway** | Regional hub for connecting VPCs, VPNs, and Direct Connect. |
| **PrivateLink** | Expose a service privately to other VPCs via an interface endpoint (no internet, no peering). |
| **VPC Endpoint** | Private connection to AWS services without traversing the internet. |

## Compute Terms

| Term | Definition |
|------|-----------|
| **AMI** | Amazon Machine Image — template for launching EC2 instances (OS, software, configuration). |
| **Instance Type** | CPU/memory/storage/networking combination (e.g., `t3.micro`, `m6i.xlarge`). |
| **Spot Instance** | Unused EC2 capacity at up to 90% discount; can be interrupted with 2-minute warning. |
| **Reserved Instance (RI)** | 1- or 3-year commitment for discounted EC2 pricing. |
| **Savings Plan** | Flexible commitment to a consistent amount of compute usage ($/hr) for 1 or 3 years. |
| **Auto Scaling Group (ASG)** | Automatically adjusts the number of EC2 instances based on demand or schedule. |
| **Launch Template** | Configuration template for launching EC2 instances (replaces launch configurations). |
| **Fargate** | Serverless compute engine for containers (ECS and EKS). No EC2 management. |
| **Cold Start** | Initial latency when a Lambda function or Fargate task starts from scratch. |

## Storage Terms

| Term | Definition |
|------|-----------|
| **Object Storage** | Data stored as objects with metadata and a unique key (S3). |
| **Block Storage** | Data stored as fixed-size blocks, mountable as a drive (EBS). |
| **File Storage** | Shared file system accessible via NFS (EFS) or SMB (FSx). |
| **Storage Class** | S3 tier optimised for different access patterns and cost (Standard, IA, Glacier, etc.). |
| **Lifecycle Policy** | Rules to automatically transition or expire objects between storage classes. |
| **Multipart Upload** | Upload large objects to S3 in parts for reliability and parallelism. |
| **Versioning** | S3 feature to keep multiple versions of an object. |

## Database Terms

| Term | Definition |
|------|-----------|
| **Multi-AZ** | RDS deployment with a synchronous standby replica in another AZ for high availability. |
| **Read Replica** | Asynchronous copy of a database for read scaling. |
| **RCU / WCU** | Read Capacity Unit / Write Capacity Unit — DynamoDB provisioned throughput. 1 RCU = 1 strongly consistent read/s for 4 KB. |
| **GSI** | Global Secondary Index — DynamoDB index with a different partition key and optional sort key. |
| **LSI** | Local Secondary Index — DynamoDB index with the same partition key but different sort key. |
| **DAX** | DynamoDB Accelerator — in-memory cache for DynamoDB. |
| **Aurora Serverless** | Aurora mode that auto-scales compute capacity based on demand. |

## Security Terms

| Term | Definition |
|------|-----------|
| **IAM** | Identity and Access Management — controls who can do what in AWS. |
| **Principal** | Entity that can make AWS API requests (user, role, service, federated identity). |
| **Policy** | JSON document defining permissions (identity-based, resource-based, SCP, etc.). |
| **SCP** | Service Control Policy — organization-level guardrail that limits maximum permissions. |
| **Permissions Boundary** | IAM feature that sets the maximum permissions an identity can have. |
| **MFA** | Multi-Factor Authentication — second factor for authentication (virtual, hardware, FIDO). |
| **SSE** | Server-Side Encryption — data encrypted at rest by the service (SSE-S3, SSE-KMS, SSE-C). |
| **CMK** | Customer Master Key (now called "KMS key") — encryption key in AWS KMS. |
| **Envelope Encryption** | Pattern where a data key encrypts data, and a KMS key encrypts the data key. |
| **ABAC** | Attribute-Based Access Control — authorise based on tags/attributes rather than explicit resource ARNs. |
| **Identity Center** | AWS IAM Identity Center (formerly AWS SSO) — centralised federated access to multiple accounts. |

## Architecture Terms

| Term | Definition |
|------|-----------|
| **Well-Architected** | AWS framework of best practices across 6 pillars (operational excellence, security, reliability, performance, cost, sustainability). |
| **Infrastructure as Code (IaC)** | Define and provision infrastructure via code (CloudFormation, CDK, Terraform). |
| **Shared Responsibility Model** | AWS secures the cloud infrastructure; customers secure their workloads in the cloud. |
| **Blast Radius** | The scope of impact when something fails; minimise by isolating workloads in separate accounts/VPCs. |
| **Fan-Out** | Pattern where a single event triggers multiple parallel consumers (SNS → multiple SQS queues). |
| **Dead-Letter Queue (DLQ)** | Queue for messages that fail processing repeatedly. |
| **Circuit Breaker** | Pattern to prevent cascading failures by stopping calls to a failing service. |
| **Idempotency** | Property where repeating an operation produces the same result (critical for Lambda, SQS, Step Functions). |
| **Eventually Consistent** | Read may not reflect the latest write immediately (DynamoDB default, S3 listing before 2020). S3 is now strongly consistent. |
| **Strongly Consistent** | Read always reflects the latest write (DynamoDB optional at 2x RCU cost). |

## Pricing Terms

| Term | Definition |
|------|-----------|
| **On-Demand** | Pay by the hour/second with no commitment. |
| **Reserved** | 1- or 3-year commitment for significant discount. |
| **Spot** | Bid on unused capacity at up to 90% discount; can be interrupted. |
| **Savings Plan** | Commit to $/hr of compute for 1 or 3 years; flexible across instance types/regions. |
| **Free Tier** | Limited free usage for new accounts (12 months) and always-free services. |
| **Data Transfer** | Inbound is free; outbound to internet and cross-region is charged. Same-AZ traffic between private IPs is free; cross-AZ is charged. |
| **Right-Sizing** | Matching instance types and sizes to actual workload requirements. Use Compute Optimizer recommendations. |

## Common Acronyms

| Acronym | Meaning |
|---------|---------|
| ALB | Application Load Balancer |
| ASG | Auto Scaling Group |
| AZ | Availability Zone |
| CDK | Cloud Development Kit |
| CFN | CloudFormation |
| CIDR | Classless Inter-Domain Routing |
| CW | CloudWatch |
| DDB | DynamoDB |
| DX | Direct Connect |
| EBS | Elastic Block Store |
| ECR | Elastic Container Registry |
| ECS | Elastic Container Service |
| EFS | Elastic File System |
| EKS | Elastic Kubernetes Service |
| ELB | Elastic Load Balancing |
| ENI | Elastic Network Interface |
| IAM | Identity and Access Management |
| IGW | Internet Gateway |
| KMS | Key Management Service |
| NACL | Network Access Control List |
| NLB | Network Load Balancer |
| OAC | Origin Access Control |
| RDS | Relational Database Service |
| SG | Security Group |
| SNS | Simple Notification Service |
| SQS | Simple Queue Service |
| SSM | Systems Manager |
| TGW | Transit Gateway |
| VPC | Virtual Private Cloud |
| WAF | Web Application Firewall |
