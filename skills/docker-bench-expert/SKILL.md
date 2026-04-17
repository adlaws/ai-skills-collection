---
name: docker-bench-expert
description: 'Specialised skill for the AMT Docker Bench — a multi-container simulation of a T264 autonomous truck. Use when asked about docker_bench containers (rpk1, rpk2, rpk3, platform-sim, avi-radio, test-manager), Docker Compose configuration, network topology (onboard/offboard/CAN/local-fms-network), NAT setup, CIC/RPK version selection, T264 simulator, DDS QoS profiles, IP address remapping, overlay files, run_tests.sh, or any issue involving the Docker Bench environment. Also use for debugging container startup failures, networking problems, build errors, or service readiness issues in the bench.'
---

# Docker Bench Expert

A specialised skill for understanding, maintaining, and debugging the AMT Docker Bench environment — a collection of Docker containers that emulate the separate physical computers on a T264 autonomous haul truck for testing and validation purposes.

This skill extends the `docker-expert` skill with domain-specific knowledge of the Docker Bench architecture, its containers, networking, and configuration.

## When to Use This Skill

- Understanding how the Docker Bench containers fit together
- Debugging container build failures, startup issues, or service readiness problems
- Analysing or modifying the `docker-compose.yml`, Dockerfiles, or overlay configuration
- Diagnosing networking issues between containers (onboard, offboard, CAN, FMS)
- Understanding or modifying the NAT setup (avi-radio)
- Selecting or changing CIC/RPK/T264 Sim versions
- Understanding the IP address remapping system
- Troubleshooting DDS communication or QoS profile issues
- Working with `run_tests.sh` or the test-manager container
- Understanding the relationship between Docker Bench and the real truck hardware

## Communication Style

- **Default**: Provide concise, plain-language explanations. Focus on what is happening, why it matters, and how to fix it. Do not assume the reader has deep Docker or networking knowledge.
- **When asked for more detail**: Give in-depth explanations covering the underlying Docker and networking mechanisms.
- Always provide actionable solutions — not just descriptions of problems.

## Docker Bench Architecture Overview

The Docker Bench simulates a T264 autonomous haul truck using six containers, each representing a physical computer or network device on the real truck:

| Container | Role | What It Emulates |
|-----------|------|------------------|
| **rpk1** | Autonomy Management Toolkit (AMT) | The main onboard management computer running the RTK launcher, diagnostics watchdog, mine model adapter, blob sync, and FMS bridge |
| **rpk2** | Compute IC (CIC) | The control computer running the Control IC software with a web interface on port 8009 |
| **rpk3** | Robot Perception Kernel (RPK) | The perception computer running obstacle detection and point cloud processing |
| **platform-sim** | T264 Simulator | Simulates the vehicle dynamics and CAN bus of the physical truck, with a web interface on port 8123 |
| **avi-radio** | NAT Gateway | Emulates the AVI radio that bridges the truck's internal network to the external FMS/OT network using iptables NAT rules |
| **test-manager** | Test Automation (optional) | Runs ARCU automation tests; enabled via `--profile test-manager` |

### Key Files

| File | Purpose |
|------|---------|
| [docker_bench/docker-compose.yml](docker_bench/docker-compose.yml) | Orchestrates all containers, networks, volumes, and build arguments |
| [docker_bench/.env](docker_bench/.env) | Environment variables: versions, IPs, asset ID, patterns |
| [docker_bench/run_tests.sh](docker_bench/run_tests.sh) | Automated test orchestration script |
| [docker_bench/utils/helpers.sh](docker_bench/utils/helpers.sh) | Shell utility functions for logging, Docker version checks, container readiness |
| [docker_bench/dockerfile-rpk1](docker_bench/dockerfile-rpk1) | AMT container Dockerfile |
| [docker_bench/dockerfile-rpk2](docker_bench/dockerfile-rpk2) | CIC container Dockerfile |
| [docker_bench/dockerfile-rpk3](docker_bench/dockerfile-rpk3) | RPK container Dockerfile |
| [docker_bench/dockerfile-platform-sim](docker_bench/dockerfile-platform-sim) | T264 Simulator Dockerfile |
| [docker_bench/dockerfile-test-manager](docker_bench/dockerfile-test-manager) | Test manager Dockerfile |
| [docker_bench/dockerfile-avi-radio](docker_bench/dockerfile-avi-radio) | NAT gateway Dockerfile |
| [docs/docker_bench/index.md](docs/docker_bench/index.md) | User-facing documentation for Docker Bench |

## Network Architecture

The Docker Bench uses four networks to mirror the real truck's network topology:

### Networks

| Network | Subnet | Purpose | Real-World Equivalent |
|---------|--------|---------|----------------------|
| **onboard** (local-ocs-network) | `10.10.10.0/24` | Internal communication between onboard computers | The truck's internal Ethernet connecting all RPKs |
| **offboard** (amt-offboard) | `10.10.1.0/24` | Connects onboard computers to the AVI radio | The link from onboard computes to the external-facing radio |
| **local-fms-network** | `172.18.0.0/16` | External FMS/cloud connectivity | The OT (Operational Technology) mine network |
| **can** | Docker CAN plugin | CAN bus between RPK2, RPK3, and platform-sim | Physical CAN bus on the truck |

### IP Address Assignments

| Container | Onboard (eno1) | Offboard (eno2) | Other |
|-----------|---------------|-----------------|-------|
| rpk1 | `10.10.10.110` | `10.10.1.110` | — |
| rpk2 | `10.10.10.111` | `10.10.1.111` | CAN network |
| rpk3 | `10.10.10.112` | `10.10.1.112` | — |
| platform-sim | `10.10.10.55` | `10.10.1.55` | CAN network |
| test-manager | `10.10.10.56` | `10.10.1.56` | local-fms-network |
| avi-radio | — | `10.10.1.2` | `172.18.50.1` (FMS side) |

### NAT and Port Forwarding (avi-radio)

The avi-radio container performs Network Address Translation so that external systems (like FMS) can reach the internal containers through a single external IP (`172.18.50.1`). Port forwarding rules:

| Port | Protocol | Destination | Service |
|------|----------|-------------|---------|
| 19910 | UDP | rpk1 | DDS unicast discovery (FMS Bridge) |
| 19911 | UDP | rpk1 | DDS unicast data (FMS Bridge) |
| 8009 | TCP | rpk2 | CIC web interface |
| 8123 | TCP | platform-sim | T264 Sim web interface |
| 22 | TCP | rpk1 | SSH |
| 2020 | TCP | rpk1:22 | SSH (alternative port) |
| 2021 | TCP | rpk2:22 | SSH |
| 2022 | TCP | rpk3:22 | SSH |

## IP Address Remapping System

Each container runs an `overwrite-ip-address-config.service` at boot that rewrites IP addresses in configuration files. This allows the bench to work with different subnet configurations without manually editing every config file.

- Controlled by [overlay/common/etc/overwrite_ip_address_config/overwrite_ip_address_config.xml](docker_bench/overlay/common/etc/overwrite_ip_address_config/overwrite_ip_address_config.xml)
- Executed by [overlay/common/usr/bin/overwrite_ip_address_config.py](docker_bench/overlay/common/usr/bin/overwrite_ip_address_config.py)
- Searches through `/etc/systemd/`, `/opt/amt/`, `/opt/lme/cic/`, `/opt/lme/rpk/`, and `/persistent/`
- Replaces default IPs with actual container IPs using environment variables

## Version Selection

### CIC Version (rpk2)

- CIC tarballs are stored in `docker_bench/overlay/rpk2/persistent/`
- The `.env` variable `CIC_FIND_PATTERN` controls which version is installed (e.g. `cic*0.62*.tgz`)
- Set to `cic*.tgz` to always install the latest available version
- The `upgradeCIC.sh` script in the overlay handles installation

### RPK Version (rpk3)

- RPK tarballs are stored in `docker_bench/overlay/rpk3/persistent/`
- The `.env` variable `RPK_FIND_PATTERN` controls which version is installed (e.g. `rpk*FS62*.tgz`)
- Set to `rpk*.tgz` to always install the latest available version

### T264 Sim Version (platform-sim)

- The `.env` variable `T264_SIM_VERSION` forces a specific version (in DPKG format)
- If unset, the version bundled with the base image is used

### Docker Bench Compatibility Matrix

- Use this matrix when selecting compatible combinations of Docker Bench component versions:
   [Docker Bench Versions Compatibility Matrix](https://fmgl-autonomy.atlassian.net/wiki/spaces/AFSENG/pages/1226080308/Docker+Bench+Versions+Compatibility+Matrix)
- Important ordering note: the newest compatible combinations are at the **bottom** of the table, not the top.
- When scanning manually, verify this by checking that version numbers increase as you go down.

## Container Capabilities and Permissions

The containers require elevated Linux capabilities to function:

| Capability | Used By | Why |
|------------|---------|-----|
| `CAP_NET_ADMIN` | All RPKs, platform-sim | Network configuration, IP remapping, interface management |
| `CAP_SYS_MODULE` | All RPKs, platform-sim | Kernel module loading (CAN drivers) |
| `CAP_SYS_PTRACE` | rpk1 | Process tracing for diagnostics |
| `CAP_IPC_LOCK` | rpk2, rpk3 | Lock memory for real-time performance |
| `CAP_SYS_NICE` | rpk2, rpk3 | Set real-time scheduling priorities |

## DDS Communication

The bench uses RTI Connext DDS for inter-container communication:

- DDS Domain ID: **20** (used by ARCU tests)
- QoS profiles are defined in [overlay/common/persistent/USER_QOS_PROFILES.xml](docker_bench/overlay/common/persistent/USER_QOS_PROFILES.xml)
- FMS Bridge communicates externally via unicast through the avi-radio NAT
- The `ASSET_SHADOW_DDS_PARTICIPANT_ID` build argument configures the FMS Bridge participant

## Spoof Scripts

Located in `docker_bench/overlay/common/persistent/`, these scripts simulate data that would come from real truck sensors or systems:

| Script | What It Simulates |
|--------|-------------------|
| `spoof_aci_pose.sh` | Vehicle position and attitude (published every 100ms) |
| `spoof_aci_robot_mode.sh` | Robot operational mode |
| `spoof_health_event_*.sh` | Various health/diagnostic events |
| `spoof_actioned_diagnostics_perception_stop.sh` | Perception system diagnostic actions |
| `spoof_health_reset_perception_stop.sh` | Perception health status reset |

## Troubleshooting Workflows

### Bench Won't Start

1. Check Docker version: requires >= 27.0.3. Run `docker --version`.
2. Verify the Docker CAN plugin is installed: `docker plugin ls`. The `run_tests.sh` script installs it automatically.
3. Check that base images are available: `docker images | grep rtk_os_docker_bench`.
4. Verify `.env` has valid `CONTAINER_VERSION` (e.g. `latest-master`).
5. Check for port conflicts on the host: `ss -tlnp | grep -E '8009|8123|2020|2021|2022'`.

### Container Crashes or Won't Stay Running

1. Check logs: `docker compose logs <service>` (e.g. `docker compose logs rpk1`).
2. Check exit code: `docker inspect <container> --format='{{.State.ExitCode}}'`.
3. Verify the `overwrite-ip-address-config` service ran successfully — IP mismatches cause failures downstream.
4. For rpk2/rpk3: check that the CIC/RPK tarball matched the `FIND_PATTERN` and installed correctly.
5. Shell into a failed container interactively: `docker run -it --entrypoint /bin/bash <image>`.

### Services Not Ready (run_tests.sh Timeout)

The test script waits for these processes:

**rpk1**: `rtk_launcher`, `rtk_log_recorder`, `amt_diagnostics_watchdog`, `mine_model_adapter`, `task_spooler`, `blob_sync_node`, `fms_bridge`

**platform-sim**: `/usr/bin/t264_simulator`

If the readiness check times out:
1. Shell into the container: `docker exec -it rpk1 bash`.
2. Check `systemctl status amt.service` (rpk1) or the relevant service.
3. Check `journalctl -u amt.service --no-pager -n 50` for errors.
4. Verify DDS licence is present and valid (RTI Connext).

### Networking Issues Between Containers

1. Verify containers are on the correct networks: `docker network inspect <network>`.
2. Test connectivity: `docker exec rpk1 ping 10.10.10.111` (rpk2 onboard).
3. Check that applications bind to `0.0.0.0`, not `127.0.0.1`.
4. For DDS issues: verify QoS profiles match across containers and domain ID is consistent.
5. For FMS connectivity: check avi-radio NAT rules with `docker exec avi-radio iptables -t nat -L -n`.

### CAN Bus Issues

1. Verify the Docker CAN plugin is running: `docker plugin ls`.
2. Check CAN interfaces inside containers: `docker exec rpk2 ip link show`.
3. Decode CAN messages from platform-sim:
   ```bash
   docker exec platform-sim bash -l -c "candump vcan10 | cantools decode --single-line /t264-sim/libraries/dbc/DBW_OAL.dbc"
   ```

### Build Failures

1. Check if base images exist: the Dockerfiles expect pre-built `rtk_os_docker_bench_*` images.
2. Before changing `CONTAINER_VERSION`, check the [Docker Bench Versions Compatibility Matrix](https://fmgl-autonomy.atlassian.net/wiki/spaces/AFSENG/pages/1226080308/Docker+Bench+Versions+Compatibility+Matrix) and pick a known-compatible combination (newest compatible entries are at the bottom of the table).
3. Verify Netskope CA certificate is accessible (used for SSL in all containers).
4. For test-manager: ensure `USER_GITHUB_PAT` is set and the GitHub token has `repo`, `read:org`, `read:user` permissions with SSO enabled.
5. Check that overlay files referenced in `COPY` directives exist at the expected paths.

## Useful Commands

| Task | Command |
|------|---------|
| Start the bench | `cd docker_bench && docker compose up --build -d` |
| Start (force pull latest images) | `cd docker_bench && docker compose up --build --pull always -d` |
| Start with test-manager | `docker compose --profile test-manager up --build -d` |
| Stop the bench | `docker compose down` |
| View all logs | `docker compose logs -f` |
| View one service's logs | `docker compose logs -f rpk1` |
| Run automated tests | `./run_tests.sh` |
| SSH into rpk1 | `ssh -p 22 rtkuser@localhost` or `docker exec -it rpk1 bash` |
| SSH into rpk2 | `ssh -p 2021 rtkuser@localhost` |
| SSH into rpk3 | `ssh -p 2022 rtkuser@localhost` |
| CIC web UI | Open `http://localhost:8009` |
| T264 Sim web UI | Open `http://localhost:8123` |
| Run ARCU tests manually | `docker exec -itu rtkuser rpk1 /opt/amt/bin/arcu -d 20 -i /opt/amt/share/arcu/arcu_config.xml` |
| Check container readiness | `docker ps --format 'table {{.Names}}\t{{.Status}}'` |
| Inspect NAT rules | `docker exec avi-radio iptables -t nat -L -n` |

## Imperium Integration

Docker Bench can integrate with the Imperium local environment for end-to-end testing:

- Use `startAsset.ps1 -useDockerBench` to connect Imperium to the bench
- The asset must be configured as AHT002 with `IsMannedAsset` set to `false`
- Imperium modifies the FMS Bridge's `offboard_addresses_qos_profiles.xml` and `asset.xml` to match its own IPs and domain participant IDs

## References

- [Docker Bench Documentation](docs/docker_bench/index.md)
- [AMT T264 Docker Bench (Confluence)](https://fmgl-autonomy.atlassian.net/wiki/spaces/PROJ/pages/889520682/AMT+T264+Docker+Bench#START-HERE)
- [Imperium Local Environment](https://github.com/fmgl-autonomy/imperium/tree/master/Tools/local-environment)
- [Docker official documentation](https://docs.docker.com/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
