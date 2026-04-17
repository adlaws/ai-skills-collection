# AWS Core Services

Detailed reference for the most commonly used AWS services, organised by category.

## Compute

### EC2 (Elastic Compute Cloud)

**Purpose:** Virtual servers in the cloud with configurable CPU, memory, storage, and networking.

**Key concepts:**

* **Instance types** — families optimised for different workloads (general purpose `t3`/`m6i`, compute `c6i`, memory `r6i`, storage `i3`, GPU `p4d`/`g5`)
* **AMIs (Amazon Machine Images)** — pre-configured OS templates; can be AWS-provided, marketplace, or custom
* **Instance purchasing options:**

| Option | Use Case | Savings vs On-Demand |
|--------|----------|---------------------|
| On-Demand | Unpredictable workloads, short-term | Baseline |
| Reserved (1yr/3yr) | Steady-state workloads | Up to 72% |
| Savings Plans | Flexible commitment | Up to 72% |
| Spot | Fault-tolerant, flexible timing | Up to 90% |

* **User data** — bootstrap scripts that run on first launch
* **Instance metadata** — available at `http://169.254.169.254/latest/meta-data/` (use IMDSv2 with token)
* **Placement groups** — cluster (low-latency), spread (high availability), partition (large distributed systems)

**Common CLI:**

```bash
# Launch an instance
aws ec2 run-instances --image-id ami-xxxxx --instance-type t3.micro --key-name mykey

# List running instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Stop / start / terminate
aws ec2 stop-instances --instance-ids i-xxxxx
aws ec2 start-instances --instance-ids i-xxxxx
aws ec2 terminate-instances --instance-ids i-xxxxx
```

### Lambda

**Purpose:** Run code without provisioning servers. Pay per invocation and duration.

**Key concepts:**

* **Triggers** — API Gateway, S3 events, SQS, EventBridge, DynamoDB Streams, and 200+ event sources
* **Runtime** — Python, Node.js, Java, .NET, Go, Ruby, or custom runtimes via container images
* **Limits** — 15 min max execution, 10 GB memory, 512 MB `/tmp` (configurable to 10 GB), 6 MB sync payload
* **Layers** — shared code/libraries packaged separately from the function
* **Concurrency** — default 1000 concurrent executions per region (soft limit); reserved and provisioned concurrency available
* **Cold starts** — first invocation after idle period takes longer; mitigate with provisioned concurrency or SnapStart (Java)

**Common CLI:**

```bash
# Create a function
aws lambda create-function --function-name my-func \
  --runtime python3.12 --handler app.handler \
  --role arn:aws:iam::123456789012:role/lambda-role \
  --zip-file fileb://function.zip

# Invoke
aws lambda invoke --function-name my-func output.json

# Update code
aws lambda update-function-code --function-name my-func --zip-file fileb://function.zip
```

### ECS (Elastic Container Service)

**Purpose:** Run and manage Docker containers at scale.

**Key concepts:**

* **Task definitions** — JSON blueprint for containers (image, CPU, memory, ports, env vars, volumes)
* **Services** — maintain desired count of running tasks, integrate with load balancers
* **Launch types:**

| Type | Description | Use When |
|------|-------------|----------|
| Fargate | Serverless — AWS manages infrastructure | Don't want to manage EC2 instances |
| EC2 | You manage the underlying instances | Need GPU, specific instance types, or cost control |

* **ECR (Elastic Container Registry)** — managed Docker registry for storing container images

### EKS (Elastic Kubernetes Service)

**Purpose:** Managed Kubernetes control plane on AWS.

**Key concepts:**

* AWS manages the control plane (API server, etcd)
* Worker nodes can be self-managed EC2, managed node groups, or Fargate
* Integrates with IAM for authentication (aws-auth ConfigMap or EKS Pod Identity)
* Supports cluster autoscaler and Karpenter for node scaling

## Storage

### S3 (Simple Storage Service)

**Purpose:** Object storage with virtually unlimited capacity, 99.999999999% (11 nines) durability.

**Key concepts:**

* **Buckets** — globally unique name, region-specific
* **Objects** — key-value store; max 5 TB per object; multipart upload for objects > 100 MB
* **Storage classes:**

| Class | Use Case | Retrieval |
|-------|----------|-----------|
| Standard | Frequently accessed | Immediate |
| Intelligent-Tiering | Unknown/changing access patterns | Immediate |
| Standard-IA | Infrequent, but rapid access needed | Immediate (retrieval fee) |
| One Zone-IA | Infrequent, non-critical, single AZ | Immediate (retrieval fee) |
| Glacier Instant Retrieval | Archive, millisecond access | Immediate (retrieval fee) |
| Glacier Flexible Retrieval | Archive, minutes to hours | Minutes to hours |
| Glacier Deep Archive | Long-term archive, 7-10 year retention | 12-48 hours |

* **Versioning** — keep multiple versions of objects; required for cross-region replication
* **Lifecycle rules** — automatically transition or expire objects
* **Bucket policies** — resource-based JSON policies for access control
* **Encryption** — SSE-S3 (default), SSE-KMS, SSE-C, or client-side
* **Event notifications** — trigger Lambda, SQS, SNS, or EventBridge on object events

**Common CLI:**

```bash
# Copy file to S3
aws s3 cp myfile.txt s3://my-bucket/

# Sync directory
aws s3 sync ./local-dir s3://my-bucket/prefix/

# List objects
aws s3 ls s3://my-bucket/

# Presigned URL (temporary access)
aws s3 presign s3://my-bucket/myfile.txt --expires-in 3600
```

### EBS (Elastic Block Store)

**Purpose:** Block storage volumes for EC2 instances. Persists independently of instance lifecycle.

**Key types:**

| Type | Code | Use Case | Max IOPS | Max Throughput |
|------|------|----------|----------|----------------|
| General Purpose SSD | gp3 | Most workloads | 16,000 | 1,000 MB/s |
| Provisioned IOPS SSD | io2 | Databases, latency-sensitive | 64,000 | 1,000 MB/s |
| Throughput Optimized HDD | st1 | Big data, data warehouses | 500 | 500 MB/s |
| Cold HDD | sc1 | Infrequently accessed | 250 | 250 MB/s |

* **Snapshots** — point-in-time backups stored in S3; incremental; can copy cross-region
* **Encryption** — AES-256 via KMS; encrypt at creation or copy an unencrypted snapshot to create encrypted volume

### EFS (Elastic File System)

**Purpose:** Managed NFS file system, shared across multiple EC2 instances or containers.

* Automatically scales from bytes to petabytes
* Standard and Infrequent Access storage classes with lifecycle management
* Regional (multi-AZ) or One Zone deployment
* Supports NFS v4.1; mountable from EC2, ECS, EKS, Lambda

## Database

### RDS (Relational Database Service)

**Purpose:** Managed relational databases — AWS handles patching, backups, failover.

**Supported engines:** MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, and Amazon Aurora.

**Key concepts:**

* **Multi-AZ** — synchronous standby replica in another AZ for high availability
* **Read replicas** — asynchronous replicas for read scaling (up to 15 for Aurora)
* **Automated backups** — daily snapshots + transaction logs; point-in-time restore up to 35 days
* **Parameter groups** — engine configuration (e.g., `max_connections`, `innodb_buffer_pool_size`)
* **Proxy** — RDS Proxy pools connections, useful for Lambda and high-connection workloads

### Aurora

**Purpose:** AWS cloud-native relational database, MySQL and PostgreSQL compatible, up to 5x MySQL / 3x PostgreSQL throughput.

* **Storage** — auto-scales up to 128 TB, 6-way replication across 3 AZs
* **Aurora Serverless v2** — scales compute automatically based on demand
* **Global Database** — cross-region replication with < 1 second lag
* **DSQL** — Aurora DSQL for serverless, distributed SQL

### DynamoDB

**Purpose:** Fully managed NoSQL key-value and document database. Single-digit millisecond latency at any scale.

**Key concepts:**

* **Tables** — items (rows) with attributes (columns); schema-less except for primary key
* **Primary key** — partition key, or partition key + sort key (composite)
* **Capacity modes:**

| Mode | Description | Use When |
|------|-------------|----------|
| On-Demand | Pay per request | Unpredictable traffic |
| Provisioned | Set RCU/WCU | Predictable, steady traffic |

* **GSI / LSI** — Global Secondary Indexes (any attribute as key) / Local Secondary Indexes (same partition key, different sort key)
* **DynamoDB Streams** — ordered stream of item-level changes; trigger Lambda for event-driven patterns
* **DAX** — in-memory cache for DynamoDB, microsecond read latency
* **Single-table design** — advanced pattern: store multiple entity types in one table using composite keys and GSIs

### ElastiCache

**Purpose:** Managed in-memory data store — Redis or Memcached.

* **Redis** — persistence, pub/sub, Lua scripting, sorted sets, cluster mode
* **Memcached** — simple key-value cache, multi-threaded
* Use for session stores, leaderboards, real-time analytics, caching database queries

## Application Integration

### SQS (Simple Queue Service)

**Purpose:** Fully managed message queue for decoupling services.

| Type | Ordering | Deduplication | Throughput |
|------|----------|---------------|------------|
| Standard | Best-effort | At-least-once | Nearly unlimited |
| FIFO | Strict FIFO | Exactly-once | 3,000 msg/s (with batching) |

* **Visibility timeout** — time a message is hidden after being read (default 30s)
* **Dead-letter queue (DLQ)** — messages that fail processing after N attempts
* **Long polling** — reduce empty responses and cost by waiting up to 20s

### SNS (Simple Notification Service)

**Purpose:** Managed pub/sub messaging for fan-out patterns.

* **Topics** — Standard (high throughput, best-effort ordering) or FIFO (strict ordering)
* **Subscribers** — SQS, Lambda, HTTP/HTTPS, email, SMS, mobile push
* **Message filtering** — filter policies on subscription attributes to reduce unnecessary deliveries

### EventBridge

**Purpose:** Serverless event bus for event-driven architectures.

* Routes events from AWS services, SaaS partners, or custom applications to targets
* **Rules** — pattern-match events and route to one or more targets
* **Schema registry** — discover and version event schemas
* **Pipes** — point-to-point integration between source and target with optional filtering/transformation
* **Scheduler** — cron and rate-based scheduling

### Step Functions

**Purpose:** Orchestrate workflows as state machines with visual workflow designer.

* **Standard workflows** — up to 1 year execution, exactly-once, audit trail
* **Express workflows** — up to 5 minutes, at-least-once, high volume (100,000+/s)
* States: Task, Choice, Parallel, Map, Wait, Pass, Succeed, Fail
* Integrates natively with 200+ AWS services

### API Gateway

**Purpose:** Create, publish, and manage APIs at any scale.

| Type | Protocol | Use Case |
|------|----------|----------|
| REST API | HTTP/REST | Full-featured, caching, WAF, usage plans |
| HTTP API | HTTP/REST | Lower latency, lower cost, simpler |
| WebSocket API | WebSocket | Real-time two-way communication |

* **Stages** — deploy to dev/staging/prod
* **Authorizers** — IAM, Cognito, Lambda authorizers
* **Throttling** — default 10,000 req/s, 5,000 burst per region

## Management and Monitoring

### CloudWatch

**Purpose:** Monitoring, logging, and alerting for AWS resources and applications.

* **Metrics** — built-in (EC2 CPU, RDS connections, etc.) and custom metrics
* **Alarms** — trigger actions (SNS, Auto Scaling, Lambda) when metrics cross thresholds
* **Logs** — centralised log storage, search, and analysis via Logs Insights
* **Dashboards** — custom visualisations of metrics and logs

### CloudTrail

**Purpose:** Audit log of all API calls made in your AWS account.

* Records who did what, when, and from where
* Management events (control plane) and data events (e.g., S3 GetObject)
* Deliver to S3 and optionally to CloudWatch Logs
* Essential for security investigations and compliance

### CloudFormation

**Purpose:** Infrastructure as Code — define AWS resources in JSON/YAML templates.

* **Stacks** — collection of resources managed as a unit
* **Change sets** — preview changes before applying
* **Drift detection** — identify manual changes to stack resources
* **StackSets** — deploy stacks across multiple accounts and regions
* **Nested stacks** — modular templates that reference other templates

### AWS CDK (Cloud Development Kit)

**Purpose:** Define cloud infrastructure using familiar programming languages (TypeScript, Python, Java, C#, Go).

* Synthesises to CloudFormation under the hood
* **Constructs** — reusable, composable cloud components at three levels (L1: CFN resources, L2: opinionated defaults, L3: patterns)
* `cdk synth` to generate CloudFormation, `cdk deploy` to deploy, `cdk diff` to compare

### Systems Manager (SSM)

**Purpose:** Operations hub for managing AWS resources and on-premises servers.

* **Parameter Store** — securely store configuration and secrets (free tier available)
* **Session Manager** — SSH-less remote shell access to EC2 instances
* **Run Command** — execute scripts across fleets without SSH
* **Patch Manager** — automate OS patching
* **Automation** — runbooks for common operational tasks
