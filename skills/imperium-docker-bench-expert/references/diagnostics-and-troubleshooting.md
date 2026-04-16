# Diagnostics and Troubleshooting

## Diagnostic Tool

The `diagnoseAssetDockerBench.ps1` script inspects a running Docker Bench asset without making changes:

```powershell
./diagnoseAssetDockerBench.ps1 -assetId AHT001
```

It performs the following checks:

1. Validates the RPK container is running
2. Collects Robot Control status and diagnostics from FMS services
3. Captures onboard DDS messages (`/robot_mode_state`, `rtk/health/diagnostics`, `rtk/health/justification`)
4. Detects mode mismatches between Robot Control and onboard state
5. Identifies active health issues
6. Generates a colour-coded diagnostic summary with suggestions

### Common Diagnostic Suggestions

| Issue | Suggested Fix |
|-------|---------------|
| Health diagnostics not healthy | Run `requestRobotControlHealthResetAll.ps1` |
| DDSWSG faults active | Mask via CIC test page or `commonDockerBench.psm1` functions |
| DDSWSG directory_monitor missing | Inject via CIC test page |
| ClearToProceed available | Execute ClearToProceed command |
| Mode mismatch | Check both Robot Control and onboard DDS state |

## Mode Change Orchestration

The `commonDockerBench.psm1` module provides `Invoke-ForcedModeChange` which orchestrates the transition to autonomous mode using multiple fallback paths:

### Peaceful Path (via Robot Control Service)

1. Request mode change through Robot Control Service API
2. Wait for confirmation from onboard DDS `/robot_mode_state`

### Forceful Path (via CIC)

If the peaceful path fails:

1. Unlatch RPK Lane Breach via CIC test page
2. Mask DDSWSG RPK errors (InfluxDB not running)
3. Check RTK diagnostics health; restart `amt.service` if unhealthy
4. POST to CIC `/test` endpoint with `dbw_feedback_autonomous_pause` command
5. If ClearToProceed available, execute it
6. Inject DDSWSG directory_monitor if needed

### Health Gate

The asset cannot enter autonomous mode unless `rtk/health/justification.response_action` equals "PROCEED". The diagnostic script and mode change functions check this gate.

## Key Utility Functions (commonDockerBench.psm1)

| Function | Purpose |
|----------|---------|
| `Request-CicAuto` | Sets asset to Autonomy mode through CIC test interface |
| `Request-CicInjectDdswsgDirectoryMonitor` | Forcefully injects DDSWSG directory_monitor to RPK |
| `Request-CicRpkDdswgMask` | Masks DDSWSG RPK errors (InfluxDB not running) |
| `Get-OnboardDdsMessageSample` | Grabs DDS messages from onboard RPK1 container |
| `Get-OnboardRobotModeInfo` | Retrieves and normalises `/robot_mode_state` |
| `Get-RtkDiagnosticsIsHealthy` | Checks if RTK diagnostics indicate healthy system |
| `Invoke-ClearFaultsForcefully` | Attempts to clear faults: unlatch RPK Lane Breach, DDSWG mask, AMT restart |
| `Invoke-ClearToProceedCommandIfAvailable` | Executes ClearToProceed if available |
| `Invoke-ForcedModeChange` | Full mode change orchestration with peaceful and forceful paths |

## Common Problems and Solutions

### Docker Bench Won't Start

1. **Check Docker version**: Requires >= 27.0.3. Run `docker --version`
2. **Check Docker CAN plugin**: `docker plugin ls` - the `run_tests.sh` script installs it automatically, but for Imperium you may need to install manually
3. **Check base images are available**: `docker images | grep rtk_os_docker_bench`
4. **Check AMT repo path**: Ensure `$Env:AmtRepo` is set and points to a valid AMT checkout
5. **Check port conflicts**: `ss -tlnp | grep -E '8009|8010|8123|8124|8125'` - CIC and T264 Sim ports
6. **Check SQL is running**: SQL creates the `local-fms-network`; Docker Bench requires it

### Container Crashes or Won't Stay Running

1. Check logs: `docker compose logs rpk1-{asset_id_lower}` (e.g. `rpk1-aht001`)
2. Check exit code: `docker inspect <container> --format='{{.State.ExitCode}}'`
3. Verify the `overwrite-ip-address-config` service ran successfully - IP mismatches cause downstream failures
4. For rpk2/rpk3: check that the CIC/RPK tarball matched the `FIND_PATTERN` and installed correctly
5. Shell into a failed container: `docker run -it --entrypoint /bin/bash <image>`

### AVI-Radio NAT Not Setting Up

The `startAssetDockerBench.ps1` script validates avi-radio NAT rules by checking iptables. If it times out:

1. Shell into avi-radio: `docker exec -it avi-radio-{asset_id_lower} bash`
2. Check NAT rules: `iptables -t nat -L -n -v`
3. Check FORWARD rules: `iptables -L FORWARD -n -v`
4. Check network interfaces: `ip route list`
5. Verify the container has both offboard and local-fms-network interfaces

### DDS Communication Failures

1. Verify DDS domain ID is consistent (should be 50 for Imperium Docker Bench assets)
2. Check Asset Shadow DDS initial peers match the asset's avi-radio IP
3. Verify QoS profiles match across containers
4. Test DDS connectivity by sampling messages: use `Get-OnboardDdsMessageSample` from `commonDockerBench.psm1`
5. Check that kernel DDS parameters are set (see Configuration and Startup reference)

### Asset Shadow Cannot Reach Docker Bench

1. Verify both the Asset Shadow and avi-radio are on `local-fms-network`
2. Check that DDS initial peers in the asset-docker-compose file match the avi-radio IP from `assets.json`
3. Test connectivity: `docker exec shadow-{ASSET_ID} ping {avi-radio-ip}`
4. Verify the DDS participant ID matches between Asset Shadow and the `.env-asset-*-docker-bench` file

### FMS Services Cannot See the Asset

1. Ensure Asset Shadow is running and registered with FMS Core services
2. Check RabbitMQ connectivity from the Asset Shadow container
3. Check Redis connectivity: the Asset Shadow uses the offboard Redis instance
4. Verify the asset exists in the FMS database (seeding must have been run)
5. Check Asset Manager knows about the asset ID

### No Map Visible in Office

1. Zoom out in the Office map view
2. Verify site offsets in `.env-field` match the seeded map
3. Re-run seeding if needed: `./seeding/seedFMS.ps1`

### Asset Won't Enter Autonomous Mode

1. Run `./diagnoseAssetDockerBench.ps1 -assetId {ASSET_ID}` for a full diagnostic
2. Check health justification: response_action must be "PROCEED"
3. Try `./requestRobotControlHealthResetAll.ps1` to clear health faults
4. Use the CIC web interface (`http://localhost:{cicWebPort}/test`) to inspect and clear faults
5. As a last resort, restart the Docker Bench containers

## Container Capabilities

Docker Bench containers require elevated Linux capabilities:

| Capability | Used By | Why |
|------------|---------|-----|
| CAP_NET_ADMIN | All RPKs, platform-sim | Network configuration, IP remapping |
| CAP_SYS_MODULE | All RPKs, platform-sim | Kernel module loading (CAN drivers) |
| CAP_SYS_PTRACE | rpk1 | Process tracing for diagnostics |
| CAP_IPC_LOCK | rpk2, rpk3 | Lock memory for real-time performance |
| CAP_SYS_NICE | rpk2, rpk3 | Set real-time scheduling priorities |
