---
name: vas-expert
description: 'Deep expertise in the Vehicle Awareness System (VAS) bundle for autonomous and manned vehicles. Provides authoritative guidance on VAS architecture, RTK GNSS-INS positioning, the three VAS variants (VAS, VAS:Precision, VAS:AHT), pose tracking, health monitoring, notifications, driver integration, and DDS data flows. Use to answer questions about VAS design, components, configuration, troubleshooting, and best practices. Explains concepts at multiple expertise levels (beginner to expert developer). Honest about knowledge limits—admits when uncertain rather than speculating.'
license: 'Proprietary (Fortescue Metals Group)'
compatibility: 'VAS bundle with RTK Suite, C++17, CMake 3.18+, RTI Connext DDS'
metadata:
  project: Vehicle Awareness System
  organization: Fortescue Metals Group
  language: English
  expertise-level: expert
  focus-areas: positioning, pose-tracking, notifications, drivers, DDS-routing, architecture
---

# VAS Expert Skill

## Purpose

This skill provides in-depth expertise on the **Vehicle Awareness System (VAS)**, a bundled software system for determining and communicating vehicle position and status in both autonomous and manned vehicle fleets. The skill can explain VAS concepts at multiple levels—from high-level architecture overviews for stakeholders to low-level technical details about driver integration and DDS data flows for developers.

## Core VAS Understanding

### What VAS Does

VAS is responsible for:

1. **Determining vehicle position** — Using RTK GNSS-INS sensors to achieve lane-precise (< 0.5m) 6-DOF positioning
2. **Reporting vehicle state** — Communicating position, heading, health events, and telemetry to FMS and other vehicles
3. **Receiving V2X data** — Collecting positions from all fleet vehicles via FMS or V2X to maintain a single source of truth
4. **Managing communications** — Handling notifications, acknowledgements, sound requests, and vital data between onboard and offboard systems
5. **Boundary detection** — Computing vehicle bounds relative to detected boundaries (VAS:Precision only)

### Key Architecture Elements

**VAS operates as a layered system:**

- **Sensors** — GNSS-INS (RTK) dual-antenna receivers, integrated INS for dead reckoning
- **Drivers** — AN GNSS driver, Motium microcontroller interface, CAN frame handling
- **Pose Stack** — Localiser and pose translation components for 6-DOF calculation
- **Interface Bridges** — VAS interface stack and specialized stacks (AHT, Precision, notifications)
- **DDS Routing** — RTI Connext DDS for high-performance pub/sub communication with field and IAI domains

## VAS Variants

VAS comes in three product variants, each built from shared components with variant-specific subsets:

### 1. VAS (Standard)

**Use case:** Manned vehicles requiring reliable position and status reporting

**Architecture:**
```
GNSS-INS → GNSS Driver → Pose Stack → VAS Interface Stack → FMS/V2X
```

**Key features:**
- Real-time pose (position + heading) from RTK GNSS-INS
- Health event reporting and justification chains
- Telemetry (vehicle vital data) reporting
- RTK correction distribution to fleet

**Typical components deployed:**
- `an-gnss-driver-rtk` — integrates GNSS receiver
- `pose-stack/localiser` — computes 6-DOF pose
- `vas-interface-stack` — bridges DDS domains

---

### 2. VAS:Precision (HPMG)

**Use case:** High-precision manned operations (surveying, loading coordination)

**Architecture:**
```
GNSS-INS → GNSS Driver ↔ Precision Pose Stack
    ↓                           ↓
RTK Corrections        Boundary Detection Stack
    ↓                           ↓
    └──────→ VAS Interface Stack ←──────┘
                   ↓
        Surveying, Loading, A470 Bridge
```

**Key additions over VAS:**
- **Boundary Interaction Detection** — Computes vehicle bounds relative to detected zone boundaries
- **Precision Advisor** — Provides enhanced surveying/positioning guidance
- **A470 Bridge** — Integrates A470 OCS display with VAS data
- Higher frequency pose updates for precise manoeuvring

**Configuration:** `rtk_os/vas_precision.xml`

---

### 3. VAS:AHT

**Use case:** Automated Haul Truck (AHT) systems operated by remote OCS

**Architecture:**
```
VAS Interface Stack ← OCS (all core logic and sensing)
```

**Key characteristics:**
- Minimal onboard VAS footprint—mainly network bridge
- Uses centralized OCS for all positioning and decision-making
- Receives commands and publishes status via DDS
- No onboard GNSS/INS processing

**Configuration:** `rtk_os/vas_aht.xml`

---

## Component Library Organization

### Drivers

| Driver | Purpose | Variants |
|--------|---------|----------|
| `an-gnss-driver-lib` | GNSS receiver abstraction | All |
| `an-gnss-driver-rtk` | RTK GNSS with RTI DDS integration | VAS, Precision |
| `motium-driver-rtk` | Motium wheel encoder/IMU | Precision |
| `motium-microcontroller-driver` | Microcontroller communication | Precision |
| `can_frame_driver_rti_dds` | CAN→DDS bridging (A470) | Precision |

### Libraries

| Library | Purpose |
|---------|---------|
| `utilities-library` | String, conversion, logging utilities |
| `rti_dds_utilities_library` | DDS initialization, domain participant helpers |
| `advanced-navigation-sdk-library` | AN GNSS receiver SDK wrapper |
| `robot-model-library` | Vehicle bounds and geometry calculations |
| `applied-mathematics-library` | Pose transforms, homogeneous transformations |
| `http-client-lib` | HTTP requests for external APIs |
| `sensor-emulation-library` | Testing: mock GNSS/sensors |
| `vas-test-helpers` | Testing utilities and fixtures |

### Stacks

| Stack | Purpose | Variants |
|-------|---------|----------|
| `pose-stack/*` | Localiser + pose translation | VAS, Precision |
| `vas-interface-stack` | DDS bridge (field/IAI/ext. domains) | All |
| `notification-manager-stack` | Notification → FMS routing | All |
| `boundary-interaction-detection-stack` | Bounds computation | Precision |
| `precision-advisor-stack` | Guidance + surveyance | Precision |
| `sound-management-stack` | Audio feedback | All |
| `shutdown-controller-stack` | Graceful shutdown | All |
| `t264-interface-stack` | T264 metadata integration | All |

## DDS Data Flow

VAS uses RTI Connext DDS with **three main domain pairs:**

### Domain Pair 1: vas_domain ↔ field_domain

**Primary data flow to/from FMS and field users**

**Key topics (VAS variant):**
- `/asset_pose` — Primary 6-DOF vehicle position (read by FMS)
- `/health_event` — Structured health events + justifications
- `/report` — VAS telemetry (battery, comms, system health)
- `/gnss_rtk_corrections` — RTK corrections distributed to fleet
- `/virtual_boundary_control` — Virtual geofence commands from FMS
- `/notifications/*` — Alerts and acknowledgements

**Key topics (VAS:Precision variant - additional):**
- `/boundary_interaction` — Vehicle bounds vs. detected boundaries
- `/precision_design_files` — Survey data and boundary definitions

### Domain Pair 2: vas_domain ↔ iai_domain

**Communication with Instrumented Asset Interface (IAI)**

**Key topics:**
- `/asset/v1/all_pose` — Complete multi-pose information
- `/asset/v1/pose_status` — Pose reliability indicators

## When to Use This Skill

**Ask the vas-expert skill when you need to:**

1. **Understand VAS concepts** — Explain positioning, variants, architecture
2. **Debug/troubleshoot issues** — Trace data flows, check driver status, validate configuration
3. **Extend VAS** — Add new sensors, integrate external systems, customize stacks
4. **Optimize performance** — Tune pose frequency, reduce latency, improve reliability
5. **Review code** — Assess driver/stack implementations for VAS best practices
6. **Configure VAS** — Explain variant XML configs, deployment options
7. **Integrate with external systems** — Connect to FMS, OCS, V2X, OTA systems
8. **Understand test failures** — Interpret unit test results, mock sensor behavior
9. **Explain to stakeholders** — Translate architecture, capabilities, limitations

## Knowledge Boundaries

**This skill knows:**

✓ VAS bundle architecture, components, and data flows
✓ RTK GNSS-INS positioning principles and accuracy
✓ DDS routing patterns in VAS
✓ Driver and stack implementation details
✓ Configuration and deployment for each variant
✓ VAS testing strategies and common edge cases
✓ Integration points with FMS, OCS, external systems
✓ Performance and reliability considerations

**This skill admits when uncertain about:**

✗ Proprietary OCS or FMS internals (not in bundle)
✗ Real-world GPS denied scenarios (beyond documented INS fallback)
✗ Specific customer site configurations
✗ Future feature roadmaps or product plans
✗ Non-VAS systems or external projects

## How to Interact with This Skill

### 1. Quick Conceptual Questions

**You ask:** "What is VAS?"
**Skill responds:** Concise overview → optionally drill deeper

### 2. Technical Deep Dives

**You ask:** "Explain the pose_stack architecture and how localiser feeds full_body_pose_translator"
**Skill responds:** Component interaction diagram → data types → flow explanation

### 3. Troubleshooting Guidance

**You ask:** "Asset pose is stale—how do I debug?"
**Skill responds:**
1. Check GNSS signal (check health events)
2. Verify DDS routing config (check vas_domain connectivity)
3. Check localiser logs
4. Verify GNSS driver status
→ Links to test/debug references

### 4. Code Review Support

**You ask:** "Review this driver integration for VAS best practices"
**Skill responds:**
- Architecture alignment
- Thread safety / concurrency
- Error handling patterns
- DDS publishing best practices
- Integration test coverage

### 5. Comparative Questions

**You ask:** "How does VAS:Precision differ from VAS in terms of architecture?"
**Skill responds:** Side-by-side comparison → deployment differences → when to use each

## Key References

Refer to bundled references for detailed information on:
- **Pose Stack Architecture** — `references/pose-stack-architecture.md`
- **DDS Routing Primer** — `references/dds-routing.md`
- **Networking Requirements** — `references/networking-requirements.md` (ports, bandwidth, RTK)
- **Driver Integration Checklist** — `references/driver-integration.md`
- **Testing Strategy** — `references/testing-strategy.md`
- **Configuration Guide** — `references/variant-configuration.md`

## Building VAS

**Build commands:**
```bash
# Quick build (debug + tests):
bash .vscode/build.sh

# Clean rebuild:
bash .vscode/clean.sh && bash .vscode/build.sh

# Debian package (for deployment):
bash build_deb.sh

# Specific target:
cmake --build ./build --target localiser -- -j8
```

**Build dependencies:**
- RTI Connext DDS (CONNEXTDDS_DIR env var)
- RTK Suite (CMake find_package)
- Common data types (find_package)
- C++17 compiler

## Testing VAS

**Run all tests:**
```bash
ctest -j8 --output-on-failure
```

**Run specific stack tests:**
```bash
ctest -R "pose_stack" -V
```

**Run with coverage:**
```bash
cmake --build ./build --target coverage
```

---

*VAS Expert Skill™ — Built on deep repository analysis and documentation comprehension.*
