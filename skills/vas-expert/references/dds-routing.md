# DDS Routing Primer

*Understanding data flows in VAS through RTI Connext DDS*

## Core Concepts

VAS relies on **RTI Connext DDS** (a pub/sub middleware) to decouple components. Data flows between **three DDS domains**, each representing a different network logical partition:

| Domain | Participants | Purpose |
|--------|--------------|---------|
| **vas_domain** | VAS components (drivers, stacks) | Internal VAS processing |
| **field_domain** | FMS, OCS, field users | External communications |
| **iai_domain** | Instrumented Asset Interface | Asset telemetry standardization |

## Domain Bridge: VAS Interface Stack

The **VAS Interface Stack** is the bridge between these domains. It contains:

1. **Routing services** — RTI Routing Service subscriptions/publications
2. **Processors** — Data transformation logic (format conversion, filtering, aggregation)
3. **Connectors** — Domain propagation config (which topics flow to which domains)

### Key Routing Patterns

#### Pattern 1: Pose Broadcasting (vas_domain → field_domain)

```
vas_domain:
  /multi_pose_w_bounding_box (MultiPose from full_body_pose_translator)
    ↓
VAS Interface Stack [asset_pose_processor]
    ↓ (transforms Common→VAS Interface data types)
field_domain:
  /asset_pose (VAS Interface Pose)
  ↓
FMS / Field operations
```

**Why transform?** Common types are internal; VAS Interface types are stable API for FMS.

#### Pattern 2: Health Event Chain (vas_domain → field_domain)

```
GNSS Driver (vas_domain):
  publishes RTKLossDetected event
    ↓
Health Event Justifier Stack (vas_domain):
  subscribes → creates structured HealthEvent ← Justification chain
    ↓
VAS Interface Stack [health_event_processor]
    ↓
field_domain:
  /health_event (HealthEvent) → FMS
```

**Why separate publish/subscribe?** Allows multiple internal systems to gather **justifications** (root causes) before reporting externally. Example:

```
Event: VAS_UNHEALTHY
Justified by: [
  RTK_NO_FIX (because antenna signal lost),
  INVALID_HEADING (because dual antenna baseline not resolved),
  INS_DRIFT_HIGH (because 45 seconds coasting)
]
Recommended action: Park vehicle until RTK recovers
```

#### Pattern 3: Command Reception (field_domain → vas_domain)

```
field_domain:
  /virtual_boundary_control (VirtualBoundaryControl from FMS)
    ↓
VAS Interface Stack [reverse processor]
    ↓ (field_domain→vas_domain conversion)
vas_domain:
  /virtual_boundary_control (Common format)
    ↓
Boundary Detection / Pose Stack (if needed)
```

#### Pattern 4: Cross-Domain Aggregation (vas_domain ↔ iai_domain)

```
vas_domain:
  /multi_pose_w_bounding_box + /health_event + /telemetry
    ↓
VAS Interface Stack [all_pose_processor]
    ↓ (aggregates into standardized IAI format)
iai_domain:
  /asset/v1/all_pose (AllPoseKeyedWrapper)
  /asset/v1/pose_status
```

## Topic Landscape by Variant

### VAS (Standard)

**vas_domain (internal):**
- `/RawIMUData` → GNSS driver
- `/ComputedPose` → localiser
- `/MultiPose` → full_body_pose_translator
- `/HealthJustification` → health justifier
- `/Telemetry` → telemetry publisher

**field_domain (external):**
- `/asset_pose` ← VAS Interface
- `/health_event` ← VAS Interface
- `/report` (telemetry) ← VAS Interface
- `/gnss_rtk_corrections` → fleet
- `/virtual_boundary_control` ← from FMS
- `/notifications/*` ← notification manager

**iai_domain (standardized):**
- `/asset/v1/all_pose` ← VAS Interface
- `/asset/v1/pose_status` ← VAS Interface

### VAS:Precision (additional topics)

**vas_domain additions:**
- `/MotiumData` ← Motium driver
- `/BoundaryInteraction` ← boundary detection stack
- `/PrecisionAdvisoryData` ← precision advisor

**field_domain additions:**
- `/boundary_interaction` ← VAS Interface
- `/precision_design_files` ← precision advisor
- `/surveying_guidance` ← precision advisor (optional)

## DDS Configuration in VAS

### XML Configuration Files

Located in `rtk_os/`:

```
rtk_os/
  common.xml              # Shared DDS participant setup
  vas.xml                 # VAS variant (standard)
  vas_precision.xml       # VAS:Precision additions
  vas_aht.xml            # VAS:AHT (minimal)
  custom_hooks.sh        # Environment setup
```

**Key config sections:**

```xml
<!-- common.xml -->
<DDS_DOMAIN_PARTICIPANT>
  <domain_id>1</domain_id>  <!-- vas_domain ID -->
  <participant_qos>
    <!-- DDS Quality of Service: reliability, latency budgets, etc. -->
  </participant_qos>

  <registered_topics>
    <topic>
      <name>RawIMUData</name>
      <type_name>common::sensor::RawIMUData</type_name>
      <qos>RELIABLE</qos>
    </topic>
    <!-- ... more topics ... -->
  </registered_topics>
</DDS_DOMAIN_PARTICIPANT>
```

### Reliability vs. Latency

Different VAS topics have different QoS profiles:

| Topic | Reliability | Latency Budget | Reason |
|-------|-------------|-----------------|--------|
| `/asset_pose` | Best-Effort | <100ms | Fresh pose always better than stale guaranteed |
| `/health_event` | Reliable | <500ms | Critical alerts must not be lost |
| `/gnss_rtk_corrections` | Reliable | <1s | Loss of corrections is better than corrupted ones |
| `/notifications/notification` | Reliable | <2s | Alerts to driver should not be lost |

## Debugging DDS Flows

### Check Domain Connectivity

```bash
# List all DDS participants (requires rtiddsspy tool):
rtiddsspy

# Expected output (VAS running):
# [Participant 1: vas_domain (ID 1)]
#   - DataWriter: RawIMUData
#   - DataReader: ComputedPose
# [Participant 2: field_domain (ID 2)]
#   - DataReader: /asset_pose
```

**Note:** See `networking-requirements.md` for port-level diagnosis and firewall configuration.

### Monitor Topic Traffic

```bash
# Subscribe to topic and observe:
ddsspy_tools subscribe -d 1 -t /ComputedPose

# Expected: pose messages @ 50 Hz with fresh timestamps
```

### Trace Routing Service

VAS Interface Stack runs as a **Routing Service** application:

```bash
# Check it's running:
ps aux | grep routing_service

# View logs:
tail -f /var/log/vas/routing_service.log

# Expected: "Route enabled: asset_pose" messages at startup
```

### Check Published Topics

```bash
# From das_command (or similar monitoring tool):
# List all topics and their activity
das_command list topics

# Typical output:
# Topic: /asset_pose (field_domain)
#   Status: ACTIVE
#   DataWriters: 1 (from VAS Interface Stack)
#   DataReaders: N (FMS, OCS, etc.)
#   Frequency: 50 Hz
#   Last sample age: 14 ms
```

## Common DDS Issues in VAS

### Pose Not Appearing in FMS

**Root cause:** Routing Service didn't start / domain mismatch

**Debug:**
1. Check routing service process: `systemctl status vas-routing-service`
2. Verify vas_domain has ComputedPose: `rtiddsspy | grep -i "ComputedPose"`
3. Verify field_domain participants exist: check FMS is online
4. Inspect config file: `cat rtk_os/vas.xml | grep -A5 "asset_pose"`

### High Latency in Health Events

**Root cause:** Reliable transport + network congestion / recovery

**Mitigation:**
- Reduce other reliable topic volume
- Increase DDS thread priority (nice level)
- Verify network MTU is 1500+ bytes (fragmentation?)

### Data Type Mismatch Errors

**Symptom:** "Cannot serialize message—schema version mismatch"

**Cause:** VAS built against old `common_data_types` package

**Fix:**
```bash
# Rebuild with latest common types:
rm -rf build
export CMAKE_PREFIX_PATH=/opt/rtk_suite/lib/cmake
cmake -B build .
```

---

**Want low-level DDS config? See RTI Connext documentation or `references/dds-qos-tuning.md`**
