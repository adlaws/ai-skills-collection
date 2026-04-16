# Build, Test, and Deploy

Development workflow, build commands, testing strategies, and deployment procedures for AMT.

## Development Environment Setup

### Prerequisites

- VSCode with Remote Containers extension
- Docker (for dev container and Docker Bench)
- Git with submodule support

### Getting Started

```bash
# Clone with submodules
git clone https://github.com/fmgl-autonomy/amt.git ~/workspace/amt
cd ~/workspace/amt
git submodule update --init --recursive

# Open in VSCode (auto-detects devcontainer)
code .
```

### Dev Container

The `.devcontainer.json` defines the development environment:
- **Image:** `artifactory.fmgl.com.au/.../ocs:rtk_os_dev_amt-latest-master`
- **User:** `rtkuser`
- **Post-create:** Installs `robotframework==7.1.1`
- **Mounts:** X11 forwarding, Docker socket, PCLP licensing
- **Extensions:** C++, Python, Markdown, ShellCheck, DrawIO

## Building

### Development Build (VSCode)

Use the VSCode task **"Build AMT Bundle"** or run manually:

```bash
# Configure and build (out-of-tree)
PROJECT_NAME=amt
BUILD_DIR=$HOME/workspace/build/$PROJECT_NAME
mkdir -p $BUILD_DIR && cd $BUILD_DIR
cmake ~/workspace/amt/src -DBUILD_TESTING=TRUE
make -j6 install
```

Output is installed to `~/workspace/build/install/`.

### Clean and Rebuild

VSCode task **"Clean and Build AMT Bundle"** or:

```bash
bash ~/workspace/amt/.vscode/clean.sh
bash ~/workspace/amt/.vscode/build.sh
```

### Debian Package (Production)

```bash
# Create build directory and build
rm -rf ~/workspace/build/debian_build
mkdir -p ~/workspace/build/debian_build
cd ~/workspace/build/debian_build
bash ~/workspace/amt/build_deb.sh
```

**Output artifacts:**
- `amt_VERSION_amd64.deb` — Main package
- `amt-dbgsym_VERSION_amd64.deb` — Debug symbols package
- `.buildinfo`, `.changes` — Build metadata

**Install locally:**
```bash
cd ~/workspace/build/debian_build
sudo apt install -f --reinstall -y --allow-downgrades ./amt_*_amd64.deb
```

### Build a Specific Target

```bash
cmake --build ./build --target task_spooler2 -- -j8
cmake --build ./build --target fms_bridge -- -j8
```

### CMake Configuration Options

| Flag | Default | Purpose |
|------|---------|---------|
| `-DBUILD_TESTING=ON` | OFF | Enable unit tests (Google Test) |
| `-DBUILD_COVERAGE=ON` | OFF | Enable code coverage reporting |
| `-DCMAKE_BUILD_TYPE=Debug` | Release | Build type |
| `-DCMAKE_INSTALL_PREFIX=/opt/amt` | — | Installation prefix |

## Testing

### Unit Tests (Google Test)

```bash
# Run all tests
cd ~/workspace/build/amt
ctest -j8 --output-on-failure

# Run specific test target
ctest -R "task_spooler" -V

# Run with coverage
cmake --build . --target coverage
```

### Integration Tests (Robot Framework)

AMT uses Robot Framework for integration, component, and end-to-end testing.

**Configuration:** `robot.toml` at repository root defines paths, environment variables, and test settings.

**Key environment variables:**
- `BUNDLE=amt`
- `ABS_SRC_DIR=/home/rtkuser/workspace/amt/src`
- `ABS_BINARY_DIRECTORY=/opt/amt/bin`
- `ABS_INSTALLED_CONFIG_ROOT=/opt/amt/share`

**Running tests:**

```bash
# Smoke tests (quick validation)
./src/test/test-framework/scripts/run_amt_tests.sh -i smoke

# Component tests (subsystem validation)
./src/test/test-framework/scripts/run_amt_tests.sh -i component

# Integration tests (cross-component)
./src/test/test-framework/scripts/run_amt_tests.sh -i integration

# Specific DDS domain
./src/test/test-framework/scripts/run_amt_tests.sh -d 20 -i smoke
```

**Test categories:**

| Category | Location | Scope |
|----------|----------|-------|
| Component | `tests/amt/component/manager_stack/` | Individual stack testing |
| Component | `tests/amt/component/fms_interface_stack/` | FMS bridge testing |
| Component | `tests/amt/component/diagnostics_watchdog/` | Watchdog testing |
| Integration | `tests/amt/integration/` | Cross-stack testing |
| End-to-end | `tests/amt/end_to_end/` | Full system testing |

**Test simulators (in `sims/`):**
- `dds_publisher_sim/` — Publishes test DDS messages
- `dds_subscriber_sim/` — Subscribes and validates DDS messages

### Docker Bench Integration Tests

The Docker Bench provides a full multi-container simulation for end-to-end testing:

```bash
# Start the bench
cd docker_bench
docker compose up --build -d

# Run automated tests
./run_tests.sh

# Start with test-manager profile
docker compose --profile test-manager up --build -d
```

See the `docker-bench-expert` skill for detailed Docker Bench information.

### Static Analysis

AMT uses PCLP (PC-lint Plus) for C++ static analysis via RTK tooling:

```bash
# File-level analysis (current file)
# VSCode: F1 → RTK C++ File Static Analysis

# Project-level analysis (project containing current file)
# VSCode: F1 → RTK C++ Project Static Analysis

# Workspace-level analysis (all source)
# VSCode: F1 → RTK C++ Workspace Static Analysis
```

**Custom suppressions:** `-e9070`, `-e2771`

## Deployment

### Systemd Service

AMT runs as a systemd service on RPK1:

```ini
[Unit]
Description=Launcher for the AMT Bundle

[Service]
ExecStart=/opt/amt/bin/amt_launch
User=rtkuser

[Install]
WantedBy=multi-user.target
```

The service only runs on RPK1 — it is excluded from RPK2 and RPK3 variants.

### Manual Launch (Development)

```bash
cd /opt/amt/include
../bin/amt_launch
```

### RTK OS Image Build

Production OS images are built using ELBE with configuration files in `rtk_os/`:

| Config | Target |
|--------|--------|
| `amt_rpk1.xml` | RPK1 (AMT management computer) |
| `amt_rpk2.xml` | RPK2 (CIC control computer) |
| `amt_rpk3.xml` | RPK3 (perception computer) |
| `amt_test_base.xml` | Test base image |
| `amt_dev.xml` | Development image |

### LME Artifact Packaging

AMT components can be packaged as LME artifacts for deployment:
- See `docs/package_lme_artifact.md` for packaging procedures
- See `docs/lme_artifact_packaging_shell_utilities.md` for shell utilities
- Manifest: `src/resources/lme/manifest.xml`
