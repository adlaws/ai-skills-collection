# Testing Workflows

## Eliwana Crusher Test with Docker Bench

The `testEliwanaCrusherDockerBench.ps1` script automates an end-to-end crusher dump test using Docker Bench assets against the Eliwana mine map.

### What It Does

1. **Environment setup**: Stops/cleans existing containers, starts FMS services, initialises authentication
2. **Map configuration**: Seeds the Eliwana map, creates a crusher stockpile, sets up a load area
3. **Asset deployment**: Starts an excavator (EX7109) and two haul trucks - one via Robot Simulator (AHT001) and one via Docker Bench (AHT002)
4. **Crusher system**: Creates a crusher in the crusher connector (OPC/UA integration), sets up East/West dump points
5. **Assignment creation**: Creates a manual assignment linking the load location to the crusher
6. **Interactive testing loop**: The operator calls the truck into the load area, kicks it when loaded, and waits for it to dump at the crusher

### Running the Test

```powershell
./testEliwanaCrusherDockerBench.ps1 -dockerBenchVersion "latest-master"
```

### Key Parameters

| Parameter | Description |
|-----------|-------------|
| `-dockerBenchVersion` | Version or "latest-master" |
| `-dockerBenchUseLatest` | Use latest Docker Bench containers |
| `-dockerBenchTestManager` | Enable the test-manager container |
| `-userEmail` | Fortescue email for authentication |
| `-userSapNumber` | SAP number (defaults to `$Env:USER_SAP`) |
| `-assetId` | Target asset ID |
| `-forceRestore` | Full database restore before test |
| `-skipBackup` | Skip safety backups |

### Test Flow

```text
Seed Eliwana Map
    ↓
Create Crusher Stockpile
    ↓
Start Excavator (EX7109) + Trucks (AHT001 Robot Sim, AHT002 Docker Bench)
    ↓
Create Crusher in Crusher Connector
    ↓
Setup East/West Dump Goal Points
    ↓
Create Manual Assignment (Load → Crusher)
    ↓
Interactive Loop:
    Call truck into load area
    ↓
    Kick truck when loaded
    ↓
    Wait for dump at crusher
    ↓
    Repeat
```

## Load and Dump Circuit

The `performLoadAndDump.ps1` script sets up a basic load/dump circuit. It can be used with Docker Bench assets by first starting the asset with `-useDockerBench`:

1. Start FMS services and asset with Docker Bench
2. Run `./performLoadAndDump.ps1` which:
    * Teleports the robot near the loading area entry
    * Creates a load/dump circuit
    * Associates the loader with the area
    * Sets the load area goal point
    * Creates the dump line in the dump area
    * Calls the robot into the load area
    * Kicks the robot from the load area
3. Interactive prompts allow repeated load/dump cycles

## Multi-Asset Testing

Running multiple Docker Bench assets simultaneously:

1. Ensure each asset in `assets.json` has unique Docker Bench network configuration (different subnets, different web ports)
2. Start each asset sequentially:

    ```powershell
    ./startAsset.ps1 -assetId AHT001 -useDockerBench
    ./startAsset.ps1 -assetId AHT002 -useDockerBench
    ```

3. Each asset gets its own:
    * Isolated onboard and offboard networks
    * Unique avi-radio IP on `local-fms-network`
    * Separate CIC and T264 Sim web ports
    * Dedicated Asset Shadow container and ports

### Default Multi-Asset Configuration

| Resource | AHT001 | AHT002 |
|----------|--------|--------|
| Asset Shadow HTTP | 5503 | 5504 |
| Asset Shadow HTTPS | 5558 | 5559 |
| CIC Web Port | 8010 | 8011 |
| T264 Sim Port | 8124 | 8125 |
| Robot Sim Port | 9010 | 9011 |
| AVI-Radio FMS IP | 172.18.11.1 | 172.18.50.1 |
| Offboard Subnet | 10.1.11.0/24 | 10.10.1.0/24 |
| Onboard Subnet | 10.10.11.0/24 | 10.10.10.0/24 |

## Spoof Scripts

Located in the AMT repo at `docker_bench/overlay/common/persistent/`, these scripts simulate data that would come from real truck sensors:

| Script | What It Simulates |
|--------|-------------------|
| `spoof_aci_pose.sh` | Vehicle position and attitude (published every 100ms) |
| `spoof_aci_robot_mode.sh` | Robot operational mode |
| `spoof_health_event_*.sh` | Various health/diagnostic events |
| `spoof_actioned_diagnostics_perception_stop.sh` | Perception system diagnostic actions |
| `spoof_health_reset_perception_stop.sh` | Perception health status reset |

## Useful Commands During Testing

### Check Docker Bench container status

```powershell
docker ps --filter "name=aht001" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### View Docker Bench logs

```powershell
docker logs rpk1-aht001 --tail 50
docker logs avi-radio-aht001 --tail 50
```

### Check avi-radio NAT rules

```bash
docker exec avi-radio-aht001 iptables -t nat -L -n -v
```

### Sample DDS messages from onboard

```powershell
Import-Module ./commonDockerBench.psm1
Get-OnboardDdsMessageSample -assetId AHT001 -topicName "/robot_mode_state"
```

### Check Robot Control status

```powershell
Invoke-RestMethod -Uri "https://robot-control-service.dev.localhost/api/v1/asset/AHT001/status" -SkipCertificateCheck
```

### Access CIC test page

Open in browser: `http://localhost:8010/test` (AHT001) or `http://localhost:8011/test` (AHT002)

Available CIC test commands:

* `dbw_feedback_autonomous_pause` - toggle autonomous pause
* `ddswsg_inject` - inject DDSWSG directory_monitor
* `rpk_ddswsg_mask` - mask DDSWSG RPK errors
