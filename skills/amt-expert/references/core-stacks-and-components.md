# Core Stacks and Components

Detailed descriptions of all AMT functional stacks, shared libraries, and utilities.

## Stacks

AMT is organised into three main functional stacks, plus a launch system and diagnostics daemon.

### FMS Interface Stack

**Location:** `src/stacks/fms-interface-stack/`
**Purpose:** Bridge between the Fleet Management System (FMS/offboard) and the onboard autonomy systems.

The FMS Interface Stack is the primary communication layer between the truck and the outside world. It handles bidirectional data flow — receiving task assignments, mine model updates, and configuration from FMS, and reporting pose, health, telemetry, and task status back.

#### fms_bridge

**Location:** `src/stacks/fms-interface-stack/fms_bridge/`
**Type:** RTI Routing Service with processor plugins
**Config schema:** `fms_bridge_config.xsd`

The FMS Bridge is the heart of AMT's external communication. It runs as an RTI Routing Service instance with approximately 20 custom processor plugins that transform data between DDS domains.

**Key processor plugins (in `src/processors/`):**
- ACI pose processing and transformation
- Health event forwarding and aggregation
- Telemetry/vital data reporting
- Task command reception and response
- GNSS RTK correction distribution
- Virtual boundary control reception
- Notification routing
- Asset monitoring
- Robot mode bridging

**Helper functions (in `src/helper_functions/`):**
- ACI pose conversion and wrapping logic
- Monitoring and watchdog integration

**Configuration:**
- `fms_bridge_config.xsd` — XML schema for bridge configuration
- `fms_bridge_diagnostics.xml` — Diagnostic event definitions
- Runtime config deployed to `/opt/amt/share/amt_launch/config/`

#### blob_sync_node

**Location:** `src/stacks/fms-interface-stack/blob_sync_node/`
**Type:** Standalone C++ executable

Synchronises binary large objects between FMS and the onboard system. Used for transferring configuration files, mine model data, firmware updates, and other binary payloads.

#### x2x_bridge

**Location:** `src/stacks/fms-interface-stack/x2x_bridge/`
**Type:** Protocol format conversion utility

Converts between different interface protocol versions (X2X format bridging).

#### Datatype Conversion Libraries

**Location:** `src/stacks/fms-interface-stack/libraries/`

| Library | Purpose |
|---------|---------|
| `datatype-conversion-library-aci-ri` | Converts between ACI (Autonomy Common Interface) and RI (Robot Interface) data types |
| `datatype-conversion-library-aci-iai` | Converts between ACI and IAI (Instrumented Asset Interface) data types |

---

### Manager Stack

**Location:** `src/stacks/manager-stack/`
**Purpose:** Task orchestration and mission execution management.

The Manager Stack receives task assignments from FMS via the FMS Bridge, organises them into a task DAG (directed acyclic graph), and dispatches them to the Control IC (CIC on RPK2) for execution.

#### task_spooler2

**Location:** `src/stacks/manager-stack/task_spooler2/`
**Type:** Standalone C++ executable
**Config schema:** `task_spooler2_config.xsd`

The primary task queue manager. Key responsibilities:

- **Task reception** — Receives task assignments from FMS via DDS
- **Task DAG management** — Organises tasks into a directed acyclic graph for dependency-aware execution (`task_graph.cpp`)
- **Task dispatch** — Sends tasks to CIC for execution
- **State tracking** — Monitors task execution state and reports back to FMS
- **Task removal** — Handles task cancellation and cleanup (`removed_tasks.cpp`)

**Key source files:**
- `task_spooler_node.cpp` — Main node entry point
- `task_spooler_dds.cpp` — DDS communication layer
- `task_graph.cpp` — Task DAG management
- `removed_tasks.cpp` — Task removal handling

#### wait_task_handler

**Location:** `src/stacks/manager-stack/wait_task_handler/`
**Type:** Standalone C++ executable

Handles blocking/wait task execution. When a task requires the truck to wait (e.g., at a loading point or queue), the wait task handler manages the blocking state until the task can proceed.

---

### Mine Model Stack

**Location:** `src/stacks/mine-model-stack/`
**Purpose:** Convert FMS mine map data to onboard perceptual models.

#### mine_model_adapter

**Location:** `src/stacks/mine-model-stack/mine_model_adapter/`
**Type:** Standalone C++ executable

Transforms FMS mine map format into an onboard-consumable format used by perception and path planning systems. This includes road networks, dump points, load points, and spatial features.

#### perception_map_generator

**Location:** `src/stacks/mine-model-stack/perception_map_generator/`
**Type:** Standalone C++ executable

Creates obstacle and traversability maps from mine model data for the perception system (RPK3).

---

### AMT Launch System

**Location:** `src/amt_launch/`
**Purpose:** Bootstrap and launch all AMT components.

The launch system is an RTK launcher configuration that starts all AMT processes in the correct order with proper configuration. It runs as a systemd service (`amt.service`) on RPK1.

**Key files:**
- `scripts/amt_launch.sh` — Main launch entry point
- `scripts/amt_common_functions.sh` — Shared shell utilities
- `scripts/xsd_transparent_xinclude.sh` — Config validation
- `config/` — Runtime node configurations and QoS profile files
- `persistent_config/` — Static configuration for mine_model and fms_bridge

### AMT Diagnostics Watchdog

**Location:** `src/amt_diagnostics_watchdog/`
**Type:** RTK diagnostics watchdog executable

Monitors the health of all AMT processes and reports diagnostic events. Uses an embedded configuration (`embedded_config.xml`) defining diagnostic responses and health state transitions.

---

## Shared Libraries

### applied-mathematics-library

**Location:** `src/libraries/applied-mathematics-library/`

Mathematical utilities built on Eigen3. Provides:
- Vector and matrix operations
- Coordinate system transformations
- Geometric calculations
- Homogeneous transformations

Includes both unit tests and integration tests.

### robot-model-library

**Location:** `src/libraries/robot-model-library/`

T264 vehicle kinematics and geometry model. Provides:
- Vehicle state representation
- Vehicle bounds and geometry calculations
- Configuration validation
- Example configurations for reference

### utilities-library

**Location:** `src/libraries/utilities-library/`

General-purpose C++ utilities including:
- String manipulation
- Type conversion helpers
- Logging utilities
- Common patterns

### ocs-common-config

**Location:** `src/libraries/ocs-common-config/`

Shared configuration vocabulary with XSD schema validation. Defines the common configuration types used across AMT components.

---

## Development Utilities

**Location:** `src/utilities/dev-tools/`

| Utility | Location | Purpose |
|---------|----------|---------|
| `arcu` | `dev-tools/arcu/` | ARCU (Automated Remote Control Unit) deployment emulator — simulates FMS task assignment |
| `cli_test_tools` | `dev-tools/cli_test_tools/` | Command-line test helpers |
| `dds_to_json_converter` | `dev-tools/dds_to_json_converter/` | Serialises DDS messages to JSON for debugging |
| `rtk_log_replayer_multi` | `dev-tools/rtk_log_replayer_multi/` | Replays multiple RTK log files simultaneously |
| `multispy` | `dev-tools/multispy/` | Real-time DDS network monitoring and diagnostics |

**Other utilities:**

| Utility | Location | Purpose |
|---------|----------|---------|
| `dds_sim` | `utilities/dds_sim/` | DDS simulation utilities |
| `data_analysis` | `utilities/data_analysis/` | Data analysis tools |
| `log_analyzer` | `utilities/log_analyzer/` | Log analysis tools |
| `rtiddsspy` | `resources/rtiddsspy/` | RTI DDS debugging scripts and QoS profiles |

---

## Resources

**Location:** `src/resources/`

### LME (Large Mission Executor) Resources

**Location:** `src/resources/lme/`

Service configuration overrides and scripts for LME integration:
- `cic.service.d.override.conf.fortescue` — CIC systemd service overrides
- `cic.start_cic_rti_7.sh.fortescue` — CIC startup with RTI DDS 7
- `debian_cic/`, `debian_rpk/`, `debian_perception/` — Debian packaging helpers
- `manifest.xml` — LME artifact manifest
- `rpk.service.fortescue` — RPK systemd service configuration
