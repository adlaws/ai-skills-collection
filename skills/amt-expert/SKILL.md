---
name: amt-expert
description: 'Expert knowledge of the Autonomy Management Toolkit (AMT) bundle for T264 autonomous haul trucks. Use when asked about AMT architecture, FMS Bridge, task spooler, mine model adapter, blob sync, diagnostics watchdog, RTK launcher, DDS communication, Robot Framework integration tests, Docker Bench simulation, build system, deployment, or any question about how the AMT onboard software works. Covers the manager stack, FMS interface stack, mine model stack, shared libraries (applied-mathematics, robot-model, utilities, ocs-common-config), development utilities (ARCU, multispy, DDS tools), Debian packaging, RTK OS configuration, and the relationship between RPK1/RPK2/RPK3 compute nodes. Explains at any level from non-technical overview to deep technical detail.'
license: 'Proprietary (Fortescue Metals Group)'
compatibility: 'RTK Suite 1.2.0+, C++17, CMake 3.18+, RTI Connext DDS, Debian Bullseye'
metadata:
  project: Autonomy Management Toolkit
  organization: Fortescue Metals Group
  language: English
  expertise-level: expert
  focus-areas: task-management, fms-bridge, mine-model, diagnostics, dds-routing, docker-bench, deployment
---

# AMT Expert

Comprehensive knowledge skill for the **Autonomy Management Toolkit (AMT)** — the onboard management software bundle running on T264 autonomous haul trucks. Use this skill to answer questions about AMT at any level of detail, from high-level architecture overviews to deep technical implementation.

## When to Use This Skill

- User asks "what is AMT" or "what does the AMT bundle do"
- User asks about system architecture, stacks, libraries, or how components interact
- User asks about task management, FMS communication, mine model processing, or diagnostics
- User asks about building, testing, packaging, or deploying AMT
- User asks about DDS communication patterns, QoS profiles, or domain configuration
- User asks about specific components (FMS Bridge, task spooler, mine model adapter, blob sync, diagnostics watchdog)
- User asks about the Docker Bench simulation environment
- User asks about RTK OS configuration, RPK1/RPK2/RPK3 deployment, or network topology
- User asks about integration testing with Robot Framework or ARCU
- User wants to understand the codebase structure or navigate the repository
- User asks about shared libraries (applied-mathematics, robot-model, utilities)
- User asks about development tools (multispy, DDS-to-JSON converter, log replayer)

## Communication Style

### Adaptive Detail Level

Match the depth of the answer to what the user is actually asking. **Default to concise** — start with the simplest useful answer and only go deeper when asked.

- **Beginner / "what is"**: Plain-language explanation. No jargon. A sentence or two may be enough.
- **Overview / "how does"**: Architecture, components, how they connect. A short paragraph or diagram.
- **Technical / "how do I"**: Specific commands, configuration, data flows. Actionable and concrete.
- **Deep technical / "explain in detail"**: Code structure, CMake targets, processor plugins, protocol internals. Go deep ONLY when explicitly requested.

Do not front-load every answer with exhaustive detail. If the user asks "what is the FMS Bridge?", a two-sentence answer is better than a full architecture walkthrough.

### Suggesting Follow-Ups

After answering, suggest 1–3 related topics the user might want to explore next. Frame these as natural follow-on questions, not a generic list. Only suggest follow-ups genuinely related to the question asked.

### Knowledge Boundaries

This skill knows the AMT codebase, architecture, build system, deployment, and testing. It does **not** know:

- Proprietary CIC or RPK3 internals (separate codebases)
- FMS/Imperium server-side implementation details (separate project)
- Real-world site-specific configurations
- Future roadmap or product plans

When asked about these, say so and point to where the answer might be found.

## System Overview

AMT is the onboard autonomy management software for Fortescue's T264 autonomous haul trucks. It runs on RPK1 (the primary management computer) and orchestrates the full operational lifecycle of an autonomous truck — receiving task assignments from the Fleet Management System (FMS), converting mine maps for onboard use, coordinating with the Control IC (CIC) and perception systems, and reporting health and telemetry back to FMS.

### What AMT Does

1. **Task management** — Receives haul cycle assignments from FMS, queues and dispatches tasks to CIC for execution via a task DAG (directed acyclic graph)
2. **FMS communication** — Bridges DDS domains between the onboard systems and FMS, converting between ACI, Robot Interface, and Instrumented Asset Interface data formats
3. **Mine model processing** — Converts FMS mine map data into onboard-consumable formats for perception and path planning
4. **Blob synchronisation** — Transfers binary large objects (configuration files, maps, firmware) between FMS and onboard
5. **Health monitoring** — Watches for diagnostic events, manages system health state, and reports to FMS
6. **Data logging** — Records DDS traffic for post-incident analysis and debugging

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   AMT Bundle (RPK1)                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              RTK Launcher                            │   │
│  │  (amt_launch — systemd service)                      │   │
│  └──────────────────────────────────────────────────────┘   │
│           │                    │                  │          │
│  ┌────────▼──────┐  ┌─────────▼─────────┐  ┌────▼───────┐  │
│  │ Manager Stack │  │ FMS Interface     │  │ Diagnostics│  │
│  ├───────────────┤  │ Stack             │  │ Watchdog   │  │
│  │task_spooler2  │  ├───────────────────┤  └────────────┘  │
│  │wait_task_     │  │fms_bridge         │                   │
│  │handler        │  │blob_sync_node     │                   │
│  └────────┬──────┘  │x2x_bridge         │                   │
│           │         └────────┬──────────┘                   │
│  ┌────────▼──────────────────▼──────┐                       │
│  │       Mine Model Stack           │                       │
│  ├──────────────────────────────────┤                       │
│  │ mine_model_adapter               │                       │
│  │ perception_map_generator         │                       │
│  └──────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
         │                      │              │
    ┌────▼─────┐         ┌─────▼──────┐    ┌──▼─────────┐
    │ RPK2     │         │ RPK3       │    │ FMS/Cloud  │
    │ (CIC)    │         │(Perception)│    │ (offboard) │
    └──────────┘         └────────────┘    └────────────┘
```

### Technology Stack

- **Language:** C++17
- **Build system:** CMake 3.18+, Debian packaging (dpkg-buildpackage)
- **Communication middleware:** RTI Connext DDS (Data Distribution Service)
- **Configuration:** XML with XSD validation
- **Testing:** Robot Framework (Python), Google Test (C++)
- **Containerisation:** Docker/Docker Compose (Docker Bench simulation)
- **OS framework:** RTK Suite (Robotics Toolkit)
- **Source control:** Git with submodules
- **Documentation:** Markdown + MkDocs

### Key Dependencies

| Dependency | Purpose |
|------------|---------|
| `rtk-suite` | Robotics Toolkit framework (launcher, logging, diagnostics) |
| `common-data-types` | Shared DDS data structures |
| `robot-interface-v1` | Robot communication protocol types |
| `blob-sync-interface-v1` | Blob synchronisation protocol |
| `mine-model-interface` | Mine map format types |
| `autonomy-kit-interface` | Autonomy protocol types |
| `instrumented-asset-interface-v1` | Asset reporting protocol |
| `coordination-interface` | Multi-system coordination types |
| RTI Connext DDS | Core, routing_service, recording_service |
| Eigen3 | Linear algebra (applied-mathematics-library) |
| SQLiteCpp | SQLite database access |
| fmt | String formatting |
| CLI11 | Command-line argument parsing |
| Protobuf 3.0.0+ | Protocol buffer serialisation |

### Deployment

AMT is deployed as a Debian package (`amt_VERSION_amd64.deb`) installed to `/opt/amt/` on RPK1. It runs as a systemd service (`amt.service`) under the `rtkuser` account.

| Path | Purpose |
|------|---------|
| `/opt/amt/bin/` | Executables (amt_launch, task_spooler2, fms_bridge, etc.) |
| `/opt/amt/share/amt_launch/config/` | Runtime configuration (node configs, QoS profiles) |
| `/opt/amt/lib/` | Shared libraries |
| `/mnt/disk2/config` | Per-instance configuration overrides |
| `/mnt/data/<timestamp>/` | Runtime logs |

## References

For detailed information, consult the following reference files:

- [Core Stacks and Components](./references/core-stacks-and-components.md) — All AMT stacks, their responsibilities, and constituent components
- [Codebase Structure](./references/codebase-structure.md) — Repository layout, build targets, directory organisation
- [Build, Test, and Deploy](./references/build-test-and-deploy.md) — Development workflow, build commands, testing, packaging
- [DDS Communication and Networking](./references/dds-communication-and-networking.md) — DDS domains, topics, QoS profiles, network topology
- [Troubleshooting](./references/troubleshooting.md) — Common issues and debugging workflows
