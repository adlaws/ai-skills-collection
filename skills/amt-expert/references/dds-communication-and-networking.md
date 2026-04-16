# DDS Communication and Networking

DDS domain architecture, topics, QoS profiles, and network topology for AMT.

## DDS Architecture

AMT uses RTI Connext DDS for all inter-process and inter-computer communication. The FMS Bridge acts as a routing service that bridges multiple DDS domains.

### DDS Domains

The onboard system uses multiple DDS domains to isolate different communication patterns:

| Domain | Purpose | Participants |
|--------|---------|-------------|
| Field domain | FMS ↔ onboard communication | FMS Bridge, FMS servers |
| Onboard domain | Internal AMT component communication | All AMT processes |
| IAI domain | Instrumented Asset Interface communication | FMS Bridge, external systems |

### FMS Bridge Routing

The FMS Bridge is an RTI Routing Service that routes topics between domains and performs data transformation:

```
FMS (offboard)                    AMT Onboard
┌──────────┐                     ┌──────────────────┐
│ Field    │ ◄── FMS Bridge ──► │ Onboard Domain   │
│ Domain   │     (routing +      │ - task_spooler2  │
│          │      transform)     │ - mine_model_    │
│          │                     │   adapter        │
│          │                     │ - diagnostics    │
│          │                     │   watchdog       │
└──────────┘                     └──────────────────┘
      │
      ▼
┌──────────┐
│ IAI      │
│ Domain   │
└──────────┘
```

### Key DDS Topics

**Task management (Manager Stack ↔ FMS):**
- Task assignments from FMS
- Task status updates to FMS
- Task completion notifications

**Pose and telemetry (FMS Interface Stack):**
- Asset pose (position + heading)
- Health events and diagnostic justifications
- Vital data / telemetry reports
- Robot operational mode

**Mine model (Mine Model Stack):**
- Mine map data from FMS
- Processed mine model for onboard use

**GNSS and perception:**
- RTK GNSS corrections distribution
- Virtual boundary control commands

**Notifications:**
- Alert notifications to/from FMS
- Acknowledgement messages

### Processor Plugins

The FMS Bridge uses approximately 20 custom processor plugins to transform data as it routes between domains. Each plugin handles a specific topic or topic group and performs:

1. **Type conversion** — Between ACI, Robot Interface, and IAI data types
2. **Data enrichment** — Adding timestamps, asset IDs, or context
3. **Filtering** — Dropping irrelevant or redundant messages
4. **Aggregation** — Combining multiple inputs into single outputs

## QoS Profiles

DDS Quality of Service profiles are configured in XML files under `src/amt_launch/config/qos_files/`.

Key QoS considerations for AMT:
- **Reliability:** Reliable delivery for task commands and health events
- **Durability:** Transient-local for configuration data that late-joiners need
- **History:** Keep-last for high-frequency telemetry, keep-all for commands
- **Deadline:** Configured for periodic data (pose, telemetry)

## Network Topology

### T264 Truck Physical Network

The T264 autonomous haul truck has three compute nodes connected via dual Ethernet NICs:

```
┌───────────────────────────────────────────────────────┐
│                    T264 Truck                         │
│                                                       │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐        │
│  │  RPK1    │    │  RPK2    │    │  RPK3    │        │
│  │  (AMT)   │    │  (CIC)   │    │  (RPK)   │        │
│  └────┬─┬───┘    └────┬─┬───┘    └────┬─┬───┘        │
│       │ │             │ │             │ │             │
│  eno1 │ │eno2    eno1 │ │eno2    eno1 │ │eno2        │
│       │ │             │ │             │ │             │
│  ┌────▼─▼─────────────▼─▼─────────────▼─▼──┐         │
│  │      Onboard Network (10.10.10.0/24)     │         │
│  └──────────────────────────────────────────┘         │
│       │                                               │
│  ┌────▼─────────────────────────────────────┐         │
│  │     Offboard Network (10.10.1.0/24)      │         │
│  └────┬─────────────────────────────────────┘         │
│       │                                               │
│  ┌────▼─────┐                                         │
│  │AVI Radio │ ← NAT gateway to mine network          │
│  └────┬─────┘                                         │
└───────┼───────────────────────────────────────────────┘
        │
   Mine OT Network
        │
   ┌────▼─────┐
   │   FMS    │
   └──────────┘
```

### IP Address Assignments

| Node | Onboard (eno1) | Offboard (eno2) |
|------|---------------|-----------------|
| RPK1 (AMT) | `10.10.10.110` | `10.10.1.110` |
| RPK2 (CIC) | `10.10.10.111` | `10.10.1.111` |
| RPK3 (Perception) | `10.10.10.112` | `10.10.1.112` |
| Platform Sim / T264 | `10.10.10.55` | `10.10.1.55` |
| AVI Radio | — | `10.10.1.2` |

### Docker Bench Network Emulation

The Docker Bench replicates this topology using four Docker networks:

| Docker Network | Subnet | Real-World Equivalent |
|----------------|--------|-----------------------|
| `onboard` (local-ocs-network) | `10.10.10.0/24` | Truck internal Ethernet |
| `offboard` (amt-offboard) | `10.10.1.0/24` | Link to AVI radio |
| `local-fms-network` | `172.18.0.0/16` | Mine OT network |
| `can` | Docker CAN plugin | Physical CAN bus |

## DDS Debugging Tools

### rtiddsspy

**Location:** `src/resources/rtiddsspy/`

```bash
# Monitor offboard DDS traffic
./rtiddsspy_offboard.sh

# Update QoS profiles for spy tool
./rtiddsspy_update_qos_profiles.sh
```

### multispy

**Location:** `src/utilities/dev-tools/multispy/`

Real-time DDS network monitoring tool. Displays active topics, participants, and data rates.

### dds_to_json_converter

**Location:** `src/utilities/dev-tools/dds_to_json_converter/`

Serialises DDS messages to JSON format for debugging and analysis.

### rtk_log_replayer_multi

**Location:** `src/utilities/dev-tools/rtk_log_replayer_multi/`

Replays multiple RTK log recordings simultaneously, useful for reproducing multi-node scenarios.
