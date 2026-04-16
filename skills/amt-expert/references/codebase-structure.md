# Codebase Structure

Repository layout, build targets, and directory organisation for the AMT project.

## Repository Root

```
amt/
├── build_deb.sh                    # Debian package builder script
├── mkdocs.yml                      # MkDocs documentation config
├── README.md                       # Project overview and setup
├── robot.toml                      # Robot Framework test config
├── .devcontainer.json              # VSCode dev container definition
├── debian/                         # Debian packaging metadata
├── docker_bench/                   # Docker Bench simulation environment
├── docs/                           # Project documentation (Markdown)
├── rtk_os/                         # RTK OS configuration and overlays
├── site/                           # Generated MkDocs site output
└── src/                            # Source code
```

## Source Tree (`src/`)

```
src/
├── CMakeLists.txt                  # Top-level build configuration
│
├── amt_diagnostics_watchdog/       # Health watchdog daemon
│   ├── CMakeLists.txt
│   └── embedded_config.xml
│
├── amt_launch/                     # Launch system
│   ├── CMakeLists.txt
│   ├── scripts/
│   │   ├── amt_launch.sh           # Main launch entry point
│   │   ├── amt_common_functions.sh # Shared shell utilities
│   │   └── xsd_transparent_xinclude.sh
│   ├── config/                     # Runtime node configs
│   │   └── qos_files/              # DDS QoS profiles
│   └── persistent_config/          # Static instance configs
│       ├── mine_model/
│       └── fms_bridge/
│
├── libraries/                      # Shared C++ libraries
│   ├── applied-mathematics-library/
│   │   ├── include/
│   │   ├── test/
│   │   └── integration_tests/
│   ├── ocs-common-config/
│   │   ├── common.xsd
│   │   └── share/
│   ├── robot-model-library/
│   │   ├── robot_model_library/
│   │   ├── docs/
│   │   └── example/
│   └── utilities-library/
│       ├── include/
│       ├── src/
│       └── test/
│
├── stacks/                         # Major functional stacks
│   ├── fms-interface-stack/
│   │   ├── fms_bridge/
│   │   │   ├── src/
│   │   │   │   ├── helper_functions/
│   │   │   │   └── processors/     # ~20 processor plugins
│   │   │   ├── config/
│   │   │   └── test/
│   │   ├── blob_sync_node/
│   │   ├── x2x_bridge/
│   │   ├── libraries/
│   │   │   ├── datatype-conversion-library-aci-ri/
│   │   │   └── datatype-conversion-library-aci-iai/
│   │   └── docs/
│   ├── manager-stack/
│   │   ├── task_spooler2/
│   │   │   ├── src/
│   │   │   ├── include/
│   │   │   ├── config/
│   │   │   └── test/
│   │   ├── wait_task_handler/
│   │   └── docs/
│   ├── mine-model-stack/
│   │   ├── mine_model_adapter/
│   │   │   ├── src/
│   │   │   ├── include/
│   │   │   ├── data/
│   │   │   ├── config/
│   │   │   └── test/
│   │   ├── perception_map_generator/
│   │   └── docs/
│   └── snapshot/                   # Stack snapshots for CI/CD
│
├── resources/                      # Installable resources
│   ├── lme/                        # LME service configs
│   ├── rtiddsspy/                  # DDS debugging tools
│   ├── scripts/
│   └── CMakeLists.txt
│
├── test/                           # Integration test framework
│   └── test-framework/
│       ├── scripts/
│       │   └── run_amt_tests.sh    # Main test runner
│       ├── tests/
│       │   └── amt/
│       │       ├── component/
│       │       ├── integration/
│       │       └── end_to_end/
│       ├── sims/                   # DDS test simulators
│       ├── common/                 # Shared test code/data
│       └── offboard/
│
└── utilities/                      # Development tools
    ├── dev-tools/
    │   ├── arcu/                   # ARCU emulator
    │   ├── cli_test_tools/
    │   ├── dds_to_json_converter/
    │   ├── rtk_log_replayer_multi/
    │   └── multispy/               # DDS network monitor
    ├── dds_sim/
    ├── data_analysis/
    └── log_analyzer/
```

## Build Targets

The top-level `src/CMakeLists.txt` defines the following build targets:

### Executables

| Target | Stack | Description |
|--------|-------|-------------|
| `amt_launch` | Launch | Main launcher (systemd entry point) |
| `amt_diagnostics_watchdog` | Diagnostics | Health monitoring daemon |
| `task_spooler2` | Manager | Task queue manager |
| `wait_task_handler` | Manager | Blocking task handler |
| `fms_bridge` | FMS Interface | FMS communication bridge (RTI Routing Service) |
| `blob_sync_node` | FMS Interface | Binary object synchronisation |
| `mine_model_adapter` | Mine Model | Mine map converter |
| `perception_map_generator` | Mine Model | Perception obstacle map generator |

### Development/Debug Executables

| Target | Location | Description |
|--------|----------|-------------|
| `arcu` | `utilities/dev-tools/arcu/` | ARCU deployment emulator |
| `cli_test_tools` | `utilities/dev-tools/cli_test_tools/` | CLI test helpers |
| `dds_to_json_converter` | `utilities/dev-tools/dds_to_json_converter/` | DDS message serialisation |
| `rtk_log_replayer_multi` | `utilities/dev-tools/rtk_log_replayer_multi/` | Multi-log replay |
| `multispy` | `utilities/dev-tools/multispy/` | DDS network diagnostics |

### Libraries

| Library | Location | Description |
|---------|----------|-------------|
| `ocs_common_config` | `libraries/ocs-common-config/` | Configuration vocabulary |
| `utilities_library` | `libraries/utilities-library/` | General C++ utilities |
| `applied_mathematics_library` | `libraries/applied-mathematics-library/` | Eigen3-based math |
| `robot_model_library` | `libraries/robot-model-library/` | T264 vehicle model |
| `datatype_conversion_library_aci_ri` | `stacks/fms-interface-stack/libraries/` | ACI ↔ RI conversion |
| `datatype_conversion_library_aci_iai` | `stacks/fms-interface-stack/libraries/` | ACI ↔ IAI conversion |

### Static Analysis Exclusions

The following targets are excluded from static analysis:
- `arcu` (non-production utility)
- `cli_test_tools` (non-production utility)

Custom PCLP suppressions: `-e9070`, `-e2771`

## CMake Configuration

**Key CMake variables:**

| Variable | Default | Purpose |
|----------|---------|---------|
| `BUILD_TESTING` | `OFF` | Enable Google Test targets |
| `BUILD_COVERAGE` | `OFF` | Enable code coverage reporting |
| `CMAKE_INSTALL_PREFIX` | `/opt/amt` | Installation directory |
| `CMAKE_BUILD_TYPE` | `RelWithDebInfo` | Build type for Debian packages |

**Key CMake find_package dependencies:**
- `common_data_types` — Shared DDS types
- `rtk_suite` — RTK framework
- `robot_interface_v1` — Robot interface types
- `blob_sync_interface_v1` — Blob sync interface
- `mine_model_interface` — Mine model types
- `autonomy_kit_interface` — Autonomy kit types
- `instrumented_asset_interface_v1` — IAI types
- `SQLiteCpp` — SQLite database
- `RTIConnextDDS` — DDS middleware (core, routing_service, recording_service)

## RTK OS Configuration (`rtk_os/`)

Configuration for building the RTK OS images used on T264 truck computers:

| File | Purpose |
|------|---------|
| `amt_dev.xml` | Development ELBE config (hostname: `rtk-os-dev-amt`) |
| `amt_rpk1.xml` | RPK1 production image config |
| `amt_rpk2.xml` | RPK2 (CIC) production image config |
| `amt_rpk3.xml` | RPK3 (perception) production image config |
| `amt_test_base.xml` | Test base image config |
| `evotrac.xml` | EvoTrac variant config |
| `interface_commands.xml` | Interface package version pinning |
| `install_interfaces.sh` | Interface package installation script |
| `custom_hooks.sh` | Custom build hooks |

**Interface package versions (from `interface_commands.xml`):**

| Package | Version |
|---------|---------|
| `autonomy-kit-interface-7` | 0.9.0 |
| `blob-sync-interface-7-v1` | 0.14.0 |
| `coordination-interface-7` | 1.0.0 |
| `common-data-types-7` | 0.19.0 |
| `robot-interface-7-v1` | 0.29.0 |
| `mine-model-interface` | 0.9.0 |
| `instrumented-asset-interface-v1` | 0.6.0 |

## Debian Packaging (`debian/`)

| File | Purpose |
|------|---------|
| `control` | Package metadata (name, dependencies, architecture) |
| `rules` | Build rules (CMake integration with debhelper) |
| `changelog` | Version history |
| `amt.service` | Systemd unit file for AMT launcher |
| `amt.links` | Symlink definitions |
| `conffiles` | Configuration files to preserve on upgrade |
| `postinst` | Post-installation script |

**Package details:**
- Name: `amt` (renamed to `amt-{branch}` during CI build)
- Architecture: `amd64`
- Depends: `rtk-suite`, `${shlibs:Depends}`, `${misc:Depends}`
- Install prefix: `/opt/amt`
