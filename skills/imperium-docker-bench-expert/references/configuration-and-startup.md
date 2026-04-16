# Configuration and Startup

## Key Files

All files are relative to `Tools/local-environment/`:

| File | Purpose |
|------|---------|
| `startAssetDockerBench.ps1` | Start a Docker Bench asset (usually called indirectly via `startAsset.ps1 -useDockerBench`) |
| `stopAssetDockerBench.ps1` | Stop a Docker Bench asset's containers |
| `diagnoseAssetDockerBench.ps1` | Inspect a running Docker Bench asset without making changes |
| `commonDockerBench.psm1` | PowerShell module with Docker Bench utility functions (CIC interaction, mode changes, DDS tools) |
| `common.psm1` | Shared PowerShell module for all local-environment scripts |
| `assets.json` | Asset definitions including Docker Bench network configuration |
| `.env-asset-AHT001-docker-bench` | AHT001-specific Docker Bench environment variables |
| `.env-asset-AHT002-docker-bench` | AHT002-specific Docker Bench environment variables |
| `asset-docker-compose-field-AHT001.yml` | Asset Shadow Docker Compose for AHT001 |
| `asset-docker-compose-field-AHT002.yml` | Asset Shadow Docker Compose for AHT002 |
| `.env` | Global environment configuration for all FMS services |
| `.env-version` | Pinned versions for FMS and Docker Bench containers |
| `.env-field` | Field-side environment overrides (site name, map offsets) |

## Prerequisites

Before running Docker Bench in Imperium:

1. **AMT repository**: Set `$Env:AmtRepo` to a locally-cloned [amt repository](https://github.com/fmgl-autonomy/amt)
2. **Docker CAN plugin**: Install the [Docker CAN](https://github.com/fmgl-autonomy/docker_can) networking plugin
3. **Docker version**: Must be >= 27.0.3
4. **Linux kernel settings**: Enable multicast on loopback, set DDS-related kernel parameters
5. **WSL users**: Use the [RTK WSL Kernel](https://github.com/fmgl-autonomy/rtk-wsl-kernel)
6. **FMS services running**: SQL, infrastructure, and FMS Core services must be started first

### DDS Kernel Settings

Set the following for reliable DDS communication:

```text
net.ipv4.udp_mem=102400 873800 16777216
net.ipv4.ipfrag_high_thresh=8388608
net.core.netdev_max_backlog=30000
net.core.rmem_max=20971520
net.core.wmem_max=20971520
net.core.rmem_default=20971520
net.core.wmem_default=20971520
```

Place these in `/etc/sysctl.d/50-dds.conf` and restart the host.

Enable multicast on loopback:

```text
SUBSYSTEM=="net", KERNEL=="lo", RUN+="/sbin/ip link set dev lo multicast on"
```

Place in `/etc/udev/rules.d/50-rtk-lo-multicast.rules`.

## Starting a Docker Bench Asset

### Quick Start

From `Tools/local-environment/` in a PowerShell terminal:

```powershell
./startAsset.ps1 -assetId AHT001 -useDockerBench
```

This internally calls `startAssetDockerBench.ps1` which:

1. Reads the asset's Docker Bench config from `assets.json`
2. Generates/updates the `.env-asset-{ASSET_ID}-docker-bench` file
3. Starts the Asset Shadow container via `asset-docker-compose-field-{ASSET_ID}.yml`
4. Starts the Docker Bench containers from the AMT repository's `docker_bench/docker-compose.yml`
5. Waits for avi-radio NAT setup to complete (verifies iptables rules)
6. Optionally forces the asset into autonomous mode

### Startup Parameters

| Parameter | Description |
|-----------|-------------|
| `-assetId` | Asset ID (e.g. AHT001, AHT002) - must exist in `assets.json` |
| `-dockerBenchVersion` | Override Docker Bench container version |
| `-dockerBenchUseLatest` | Use latest Docker Bench containers |
| `-testManager` | Enable the test-manager container |
| `-startPos` | Starting position (lat/lon, UTM, or MGRS format) |
| `-startHeading` | Starting heading in degrees |
| `-forceAuto` | Attempt to force the asset into autonomous mode |
| `-userSapNumber` | SAP number for authentication (defaults to `$Env:USER_SAP`) |

## Assets.json Docker Bench Configuration

Each asset in `assets.json` can have a `dockerBench` section that defines its network topology:

```json
{
  "AssetId": "AHT001",
  "IsAutonomousAsset": "true",
  "dockerBench": {
    "networks": {
      "local-fms-network": {
        "subnet": "172.18.0.0/16",
        "addresses": { "avi-radio": "172.18.11.1" }
      },
      "offboard": {
        "subnet": "10.1.11.0/24",
        "addresses": {
          "avi-radio": "10.1.11.2",
          "rpk1": "10.1.11.110",
          "rpk2": "10.1.11.111",
          "rpk3": "10.1.11.112",
          "platform-sim": "10.1.11.55"
        }
      },
      "onboard": {
        "subnet": "10.10.11.0/24",
        "addresses": {
          "rpk1": "10.10.11.110",
          "rpk2": "10.10.11.111",
          "rpk3": "10.10.11.112",
          "platform-sim": "10.10.11.55"
        }
      }
    },
    "t264SimWebPort": 8124,
    "cicWebPort": 8010
  }
}
```

Different assets use different subnets and ports to enable running multiple Docker Bench instances simultaneously.

## Version Selection

### Docker Bench Container Version

Set in `.env-version` as `AMT_DOCKER_BENCH_VERSION` or via the `-dockerBenchVersion` parameter. The `startAssetDockerBench.ps1` script will prompt if not provided and suggest the previously used version.

### CIC Version (rpk2)

* Tarballs stored in `docker_bench/overlay/rpk2/persistent/` within the AMT repo
* The `.env` variable `CIC_FIND_PATTERN` controls which version is installed (e.g. `cic*0.62*.tgz`)
* Set to `cic*.tgz` to always install the latest available version

### RPK Version (rpk3)

* Tarballs stored in `docker_bench/overlay/rpk3/persistent/` within the AMT repo
* The `.env` variable `RPK_FIND_PATTERN` controls which version is installed (e.g. `rpk*FS62*.tgz`)
* Set to `rpk*.tgz` for the latest available version

### T264 Sim Version (platform-sim)

* The `.env` variable `T264_SIM_VERSION` forces a specific version (DPKG format)
* If unset, the version bundled with the base image is used

### FMS Service Version

Set via `./setVersion.ps1` and stored in `.env-version` as `VERSION`. The Asset Shadow containers use this version.

## Stopping a Docker Bench Asset

```powershell
./stopAssetDockerBench.ps1 -assetId AHT001
```

This preserves the existing container version in the `.env-asset-{ASSET_ID}-docker-bench` file and runs `docker compose down --timeout 0`.

## Startup Order

The correct order for the full Imperium environment with Docker Bench:

1. `./startSql.ps1` - SQL Server (defines the `local-fms-network`)
2. `./startInfra.ps1` - Redis, RabbitMQ
3. `./startServices.ps1` - All FMS Core services
4. `./startOffice.ps1` - Office UI (optional)
5. `./startAsset.ps1 -assetId AHT001 -useDockerBench` - Docker Bench asset

SQL must start first because it creates the Docker network that all other containers join.
