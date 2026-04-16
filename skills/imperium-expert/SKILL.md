---
name: imperium-expert
description: 'Expert knowledge of the Imperium Fleet Management System (FMS) for autonomous mining operations. Use when asked about Imperium, FMS, Fortex Dispatch, fleet management, autonomous trucks, haul trucks, mine model, assignment engine, asset management, traffic management, spatial stack, field services, office services, Overwatch, Centurion, or any question about how the system works, its architecture, configuration, deployment, or operations. Explains at any level from non-technical overview to deep technical detail.'
---

# Imperium Expert

Comprehensive knowledge skill for the Imperium Fleet Management System (FMS), also known as Fortex Dispatch. Use this skill to answer questions about Imperium at any level of detail, from high-level non-technical overviews to deep technical architecture.

## When to Use This Skill

* User asks "what is Imperium" or "what does the FMS do"
* User asks about system architecture, service stacks, or how components interact
* User asks about configuration, deployment, or local development setup
* User asks about specific services (e.g. Asset Manager, Traffic Manager, Mine Model)
* User asks about autonomous mining operations, haul trucks, load/dump cycles
* User wants to understand glossary terms, data flows, or messaging patterns
* User needs help navigating the codebase or understanding project structure

## Adjusting Detail Level

Match the explanation depth to the user's request:

* **Non-technical**: Focus on business purpose, what it does, and why it matters
* **Overview**: Architecture components, how they connect, key concepts
* **Technical**: Service responsibilities, APIs, messaging, data ownership
* **Deep technical**: Code structure, configuration files, protocols (gRPC, DDS, RabbitMQ), database schemas

## System Overview

Imperium is Fortescue's autonomous mining Fleet Management System. It orchestrates fleets of autonomous and manned haul trucks, excavators, and other mining assets across open-pit mine sites. The system manages the full haul cycle - assigning trucks to loading units, routing them through the mine, managing load and dump operations, tracking material movement, and ensuring safe traffic coordination.

### Three-Tier Architecture

The FMS is comprised of three distinct deployment components:

1. **FMS Core** - Backend microservices running centrally; organised into functional stacks
2. **FMS Field** - Services deployed onto each asset (truck/excavator) in the field
3. **FMS Office** - Operator-facing applications installed on control room machines

### Technology Stack

* **Backend**: .NET (C#), microservices architecture
* **Frontend**: TypeScript, React
* **Messaging**: RabbitMQ (inter-service), DDS (real-time asset comms)
* **Data**: SQL Server, Redis
* **Containerisation**: Docker, Kubernetes
* **Observability**: OpenTelemetry (tracing), Serilog (logging)
* **Communication protocols**: gRPC, HTTP/REST, SignalR (real-time UI)
* **Build/Deploy**: GitHub Actions, Octopus Deploy, Artifactory
* **Simulation**: NAsset (Akka.NET scale testing), Robot Simulator, WPF Simulator

## References

For detailed information, consult the following reference files:

* [Core Stacks and Services](./references/core-stacks-and-services.md) - All FMS Core service stacks, their responsibilities, and constituent services
* [Glossary and Domain Concepts](./references/glossary-and-domain-concepts.md) - Mining and FMS terminology, data model concepts, time usage model
* [Codebase Structure](./references/codebase-structure.md) - Repository layout, solution files, project organisation
* [Configuration and Deployment](./references/configuration-and-deployment.md) - Local setup, Docker, environment variables, platform configuration
* [Quality Attributes and Standards](./references/quality-attributes-and-standards.md) - Design principles, logging, tracing, coding standards
