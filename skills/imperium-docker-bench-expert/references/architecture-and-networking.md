# Architecture and Networking

## Container-to-Truck Mapping

Docker Bench simulates a T264 autonomous haul truck using six containers, each representing a physical computer or network device on the real truck:

| Container | Role | What It Emulates |
|-----------|------|------------------|
| rpk1 | Autonomy Management Toolkit (AMT) | Main onboard management computer: RTK launcher, diagnostics watchdog, mine model adapter, blob sync, FMS bridge |
| rpk2 | Compute IC (CIC) | Control computer running Control IC software with web interface |
| rpk3 | Robot Perception Kernel (RPK) | Perception computer for obstacle detection and point cloud processing |
| platform-sim | T264 Simulator | Vehicle dynamics and CAN bus simulation |
| avi-radio | NAT Gateway | AVI radio bridging the truck's internal network to the external FMS/OT network |
| test-manager | Test Automation (optional) | ARCU automation tests; enabled via `--profile test-manager` |

## Network Topology

Docker Bench uses four networks that mirror the real truck's physical network segments. When integrated with Imperium, these networks must coexist with the `local-fms-network` used by FMS Core services.

### Networks

| Network | Purpose | Real-World Equivalent |
|---------|---------|----------------------|
| onboard (local-ocs-network) | Internal communication between onboard computers | Truck's internal Ethernet connecting all RPKs |
| offboard (amt-offboard) | Connects onboard computers to the AVI radio | Link from onboard computes to the external-facing radio |
| local-fms-network | External FMS/cloud connectivity (shared with FMS Core) | OT (Operational Technology) mine network |
| can | CAN bus between RPK2, RPK3, and platform-sim | Physical CAN bus on the truck |

### Multi-Asset Network Isolation

When running multiple Docker Bench assets (e.g. AHT001 and AHT002), each asset gets its own isolated network subnets to prevent collisions. This is configured in `assets.json`:

#### AHT001 Network Addresses

| Network | Subnet | Key Addresses |
|---------|--------|---------------|
| local-fms-network | 172.18.0.0/16 | avi-radio: 172.18.11.1 |
| offboard | 10.1.11.0/24 | rpk1: 10.1.11.110, rpk2: 10.1.11.111, platform-sim: 10.1.11.55 |
| onboard | 10.10.11.0/24 | rpk1: 10.10.11.110, rpk2: 10.10.11.111, platform-sim: 10.10.11.55 |

#### AHT002 Network Addresses

| Network | Subnet | Key Addresses |
|---------|--------|---------------|
| local-fms-network | 172.18.0.0/16 | avi-radio: 172.18.50.1 |
| offboard | 10.10.1.0/24 | rpk1: 10.10.1.110, rpk2: 10.10.1.111, platform-sim: 10.10.1.55 |
| onboard | 10.10.10.0/24 | rpk1: 10.10.10.110, rpk2: 10.10.10.111, platform-sim: 10.10.10.55 |

### Web Port Mapping

Each asset exposes different host ports for CIC and T264 Sim web UIs:

| Asset | T264 Sim Web Port | CIC Web Port |
|-------|-------------------|--------------|
| AHT001 | 8124 | 8010 |
| AHT002 | 8125 | 8011 |

## NAT and Port Forwarding (avi-radio)

The avi-radio container performs Network Address Translation so that FMS Core services (on local-fms-network) can reach the internal Docker Bench containers through a single external IP. This mirrors how the real AVI radio bridges the truck to the mine's OT network.

### Port Forwarding Rules

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

## How Docker Bench Connects to FMS Services

The bridge between Docker Bench and FMS is the Asset Shadow service. Each Docker Bench asset has a corresponding `asset-docker-compose-field-{ASSET_ID}.yml` that starts an Asset Shadow container configured to communicate with both:

* **FMS Core services** via the `local-fms-network` (RabbitMQ, Redis, other services)
* **Docker Bench containers** via DDS through the avi-radio NAT

### Asset Shadow Configuration

The Asset Shadow connects to the Docker Bench asset via DDS with these key settings:

| Setting | AHT001 | AHT002 |
|---------|--------|--------|
| DDS Domain ID | 50 | 50 |
| DDS Participant ID | 71 | 71 |
| DDS Initial Peers | 172.18.11.1 (AHT001 avi-radio) | 172.18.50.1 (AHT002 avi-radio) |
| Asset Shadow HTTP Port | 5503 | 5504 |
| Asset Shadow HTTPS Port | 5558 | 5559 |

### DDS Communication Path

```text
FMS Core Services
    ↕ (RabbitMQ / gRPC / HTTP)
Asset Shadow (shadow-{ASSET_ID})
    ↕ (DDS via local-fms-network)
avi-radio NAT gateway
    ↕ (DDS via offboard network)
rpk1 (FMS Bridge)
    ↕ (DDS via onboard network)
rpk2 (CIC) / rpk3 (RPK) / platform-sim (T264 Sim)
```

## IP Address Remapping System

Each Docker Bench container runs an `overwrite-ip-address-config.service` at boot that rewrites IP addresses in configuration files. This allows the bench to work with different subnet configurations (e.g. AHT001 vs AHT002) without manually editing every config file.

* Controlled by `overlay/common/etc/overwrite_ip_address_config/overwrite_ip_address_config.xml`
* Executed by `overlay/common/usr/bin/overwrite_ip_address_config.py`
* Searches through `/etc/systemd/`, `/opt/amt/`, `/opt/lme/cic/`, `/opt/lme/rpk/`, and `/persistent/`
* Replaces default IPs with actual container IPs using environment variables
