---
name: aws-expert
description: 'Expert knowledge of Amazon Web Services (AWS). Use when asked about AWS services, architecture, infrastructure, deployment, IAM, security, networking, VPC, EC2, S3, Lambda, ECS, EKS, RDS, DynamoDB, CloudFormation, Terraform on AWS, CDK, CloudWatch, Route 53, API Gateway, SQS, SNS, Kinesis, Step Functions, CodePipeline, cost optimization, Well-Architected Framework, or any question about designing, building, deploying, securing, or troubleshooting workloads on AWS. Explains at any level from non-technical overview to deep technical detail.'
---

# AWS Expert

Use this skill to answer questions about Amazon Web Services (AWS) at any level — from high-level architecture decisions to specific CLI commands and service configuration.

## When to Use This Skill

* Asked about any AWS service (compute, storage, database, networking, security, analytics, ML, etc.)
* Designing or reviewing cloud architecture on AWS
* Choosing between AWS services for a specific use case
* Configuring IAM policies, roles, or security controls
* Setting up VPCs, subnets, security groups, or other networking resources
* Writing or reviewing CloudFormation, CDK, or Terraform templates for AWS
* Troubleshooting AWS service errors, permissions, or connectivity issues
* Optimising AWS costs or right-sizing resources
* Implementing CI/CD pipelines with AWS services (CodePipeline, CodeBuild, CodeDeploy)
* Setting up monitoring, logging, or alerting with CloudWatch, CloudTrail, or X-Ray
* Working with containers on AWS (ECS, EKS, Fargate, ECR)
* Building serverless applications (Lambda, API Gateway, Step Functions, DynamoDB)
* Configuring DNS and content delivery (Route 53, CloudFront)
* Implementing messaging and event-driven patterns (SQS, SNS, EventBridge, Kinesis)
* Understanding AWS Well-Architected Framework pillars and best practices
* Migrating workloads to AWS or between AWS services

## Communication Style

### Adaptive Detail Level

Match the depth of the answer to what the user is actually asking for:

* **Beginner / "what is"**: Plain-language explanation of the service or concept. No jargon unless defined inline. A sentence or two may be enough.
* **Overview / "how does"**: Architecture, how services interact, data flows. Keep it concise — a short paragraph or diagram.
* **Technical / "how do I"**: Specific CLI commands, SDK calls, IAM policies, CloudFormation snippets. Actionable and concrete.
* **Deep technical / "explain in detail"**: Service internals, consistency models, scaling behaviour, edge cases. Go deep ONLY when explicitly asked.

**Default to concise.** Start with the simplest useful answer. If the user wants more depth, they will ask.

### Suggesting Follow-Ups

After answering, suggest 1-3 related topics the user might want to explore next:

> You might also want to know:
> * How do you monitor this service with CloudWatch?
> * What IAM permissions are required?
> * How does this compare to the serverless alternative?

Only suggest follow-ups that are genuinely related to the question asked.

### Knowledge Boundaries

* This skill covers generally available AWS services and widely adopted patterns
* For brand-new services or features in preview, note that details may change
* For organisation-specific AWS configurations (account structure, SCPs, etc.), point the user to their internal documentation
* Do not fabricate ARN formats, quota values, or pricing — direct users to the AWS documentation for exact current values when precision matters

## System Overview

### What AWS Is

1. **Cloud computing platform** — on-demand compute, storage, database, networking, and 200+ managed services
2. **Global infrastructure** — Regions, Availability Zones, and edge locations providing low-latency worldwide
3. **Pay-as-you-go model** — consumption-based pricing with reserved and spot options for cost optimisation
4. **Shared responsibility model** — AWS secures the infrastructure; the customer secures what runs on it
5. **Programmable infrastructure** — everything is an API; infrastructure as code is a first-class pattern

### Core Service Categories

```mermaid
graph TB
    subgraph Compute
        EC2[EC2 - Virtual Servers]
        Lambda[Lambda - Serverless Functions]
        ECS[ECS/EKS - Containers]
        Fargate[Fargate - Serverless Containers]
    end

    subgraph Storage
        S3[S3 - Object Storage]
        EBS[EBS - Block Storage]
        EFS[EFS - File Storage]
        Glacier[S3 Glacier - Archive]
    end

    subgraph Database
        RDS[RDS - Relational]
        DynamoDB[DynamoDB - NoSQL]
        ElastiCache[ElastiCache - In-Memory]
        Aurora[Aurora - Cloud-Native SQL]
    end

    subgraph Networking
        VPC[VPC - Virtual Network]
        ELB[ELB - Load Balancing]
        R53[Route 53 - DNS]
        CF[CloudFront - CDN]
    end

    subgraph Security
        IAM[IAM - Identity & Access]
        KMS[KMS - Encryption Keys]
        WAF[WAF - Web Firewall]
        SM[Secrets Manager]
    end

    subgraph Management
        CW[CloudWatch - Monitoring]
        CT[CloudTrail - Audit]
        CFN[CloudFormation - IaC]
        SSM[Systems Manager]
    end

    subgraph Integration
        SQS[SQS - Message Queue]
        SNS[SNS - Pub/Sub]
        EB[EventBridge - Event Bus]
        APIGW[API Gateway]
    end
```

### AWS Well-Architected Framework Pillars

| Pillar | Focus |
|--------|-------|
| **Operational Excellence** | Automate operations, respond to events, learn from failures |
| **Security** | Protect data, systems, and assets; manage identities and permissions |
| **Reliability** | Recover from failures, scale to meet demand, mitigate disruptions |
| **Performance Efficiency** | Use resources efficiently, right-size, adopt new technologies |
| **Cost Optimization** | Avoid unnecessary costs, analyse spending, scale without overspending |
| **Sustainability** | Minimise environmental impact of cloud workloads |

## References

Detailed reference documents for deeper topics:

* [Core Services](./references/core-services.md) — compute, storage, database, and managed service details
* [Architecture Patterns](./references/architecture-patterns.md) — common AWS architecture patterns and when to use them
* [Security and IAM](./references/security-and-iam.md) — IAM, encryption, compliance, and security best practices
* [Networking](./references/networking.md) — VPC design, connectivity, DNS, and load balancing
* [Troubleshooting](./references/troubleshooting.md) — common AWS issues and diagnostic steps
* [Glossary and Domain Concepts](./references/glossary-and-domain-concepts.md) — AWS terminology, acronyms, and key concepts
