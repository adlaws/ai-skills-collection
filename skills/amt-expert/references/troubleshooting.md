# Troubleshooting

Common issues and debugging workflows for the AMT bundle.

## Build Issues

### CMake Configuration Fails

**Symptom:** `cmake` cannot find packages like `common_data_types`, `rtk_suite`, or RTI Connext DDS.

**Diagnosis:**
1. Verify `rtk-suite-dev` is installed: `dpkg -l | grep rtk-suite`
2. Source the RTK environment: `source /etc/profile.d/rtk_suite.sh`
3. Verify `CONNEXTDDS_DIR` is set: `echo $CONNEXTDDS_DIR`
4. Check interface packages: `dpkg -l | grep -E 'common-data-types|robot-interface'`

**Fix:**
- Install missing packages from Artifactory
- Ensure the dev container is properly configured
- Check `rtk_os/interface_commands.xml` for required versions

### Compilation Errors After Interface Update

**Symptom:** Type mismatches or missing symbols after updating interface packages.

**Fix:**
1. Clean the build: `bash .vscode/clean.sh`
2. Rebuild: `bash .vscode/build.sh`
3. Check `rtk_os/interface_commands.xml` for version pinning
4. Ensure all datatype conversion libraries are updated to match

### Static Analysis Failures

**Symptom:** PCLP reports unexpected warnings.

**Fix:**
- Check if the warning is in the custom suppression list (`-e9070`, `-e2771`)
- Non-production targets (`arcu`, `cli_test_tools`) are excluded from analysis
- Run file-level analysis first to isolate issues

## Runtime Issues

### AMT Service Won't Start

**Symptom:** `systemctl status amt.service` shows failure.

**Steps:**
1. Check the journal: `journalctl -u amt.service --no-pager -n 100`
2. Verify the launcher exists: `ls -la /opt/amt/bin/amt_launch`
3. Check configuration: `ls -la /opt/amt/share/amt_launch/config/`
4. Verify DDS licence: check RTI Connext licence file is present and valid
5. Check instance config: `ls -la /mnt/disk2/config`
6. Try manual launch: `cd /opt/amt/include && ../bin/amt_launch`

### Task Spooler Not Processing Tasks

**Symptom:** FMS sends tasks but they are not executed.

**Steps:**
1. Check task_spooler2 is running: `ps aux | grep task_spooler`
2. Verify DDS connectivity between FMS Bridge and task spooler
3. Check task spooler logs for error messages
4. Verify task spooler configuration (`task_spooler2_config.xsd` validation)
5. Use `dds_to_json_converter` to inspect incoming task messages
6. Check that CIC (RPK2) is ready to receive dispatched tasks

### FMS Bridge Not Routing Data

**Symptom:** Data is not flowing between FMS and onboard systems.

**Steps:**
1. Check FMS Bridge is running: `ps aux | grep fms_bridge`
2. Use `rtiddsspy` to verify DDS traffic on each domain
3. Check QoS profiles match between publisher and subscriber
4. Verify network connectivity: `ping` between RPK1 and FMS
5. Check NAT rules on AVI radio if going through radio gateway
6. Inspect FMS Bridge processor plugin logs for transformation errors
7. Verify datatype conversion libraries are loaded

### Mine Model Not Updating

**Symptom:** Onboard mine model is stale or missing.

**Steps:**
1. Check mine_model_adapter is running: `ps aux | grep mine_model`
2. Verify mine model data is arriving via DDS
3. Check blob_sync_node for binary transfer status
4. Inspect mine model adapter configuration
5. Check disk space on `/mnt/data/`

### Diagnostics Watchdog Reporting False Positives

**Symptom:** Diagnostic events firing for healthy processes.

**Steps:**
1. Check watchdog configuration: `embedded_config.xml`
2. Verify monitored processes are running with expected names
3. Check timing — some diagnostics have cooldown periods
4. Review diagnostic event chain for justification

## DDS Issues

### No DDS Communication Between Nodes

**Steps:**
1. Verify network connectivity: `ping 10.10.10.111` (RPK2 from RPK1)
2. Check DDS domain IDs match across all participants
3. Verify QoS profiles are compatible (especially reliability/durability)
4. Check firewall rules are not blocking DDS ports
5. Use `rtiddsspy` to check for active participants
6. Verify RTI Connext DDS licence is valid on all nodes

### DDS Discovery Not Working

**Steps:**
1. Check multicast is enabled on the onboard network
2. For unicast discovery (through NAT), verify peer addresses in QoS profiles
3. Check that DDS participant IDs are unique
4. Verify `ASSET_SHADOW_DDS_PARTICIPANT_ID` is set correctly

### High DDS Latency or Message Loss

**Steps:**
1. Check network bandwidth: `iftop` or similar
2. Verify QoS history depth is appropriate
3. Check for topic type mismatches causing deserialization failures
4. Monitor CPU usage — DDS serialization is CPU-intensive
5. Check for competing multicast traffic

## Docker Bench Issues

For Docker Bench-specific troubleshooting, refer to the `docker-bench-expert` skill.

**Quick checks:**
1. Docker version >= 27.0.3: `docker --version`
2. Docker CAN plugin installed: `docker plugin ls`
3. Base images available: `docker images | grep rtk_os_docker_bench`
4. `.env` has valid `CONTAINER_VERSION`
5. No port conflicts: `ss -tlnp | grep -E '8009|8123|2020|2021|2022'`

## Test Issues

### Robot Framework Tests Failing

**Steps:**
1. Check `robot.toml` configuration is correct
2. Verify Python path includes all required test modules
3. Check DDS domain ID matches test configuration
4. Verify test simulators are built: `ls ~/workspace/build/install/bin/`
5. Check test output in `src/test/output/`

### ARCU Tests Timing Out

**Steps:**
1. Verify all AMT processes are running and healthy
2. Check DDS domain 20 is used (ARCU default)
3. Verify ARCU configuration: `/opt/amt/share/arcu/arcu_config.xml`
4. Check that spoof scripts are running (for simulated sensor data)
5. Review test-manager container logs if using Docker Bench

## Useful Diagnostic Commands

| Task | Command |
|------|---------|
| Check AMT service status | `systemctl status amt.service` |
| View AMT logs | `journalctl -u amt.service --no-pager -n 100` |
| List running AMT processes | `ps aux \| grep -E 'amt_launch\|task_spooler\|fms_bridge\|mine_model\|blob_sync\|diagnostics'` |
| Monitor DDS traffic | `rtiddsspy` or `multispy` |
| Convert DDS to JSON | `dds_to_json_converter` |
| Check installed AMT version | `dpkg -l \| grep amt` |
| Validate XML config | `xmllint --schema config.xsd config.xml` |
| Check disk space | `df -h /mnt/data /mnt/disk2` |
| View DDS participants | `rtiddsspy -printSample` |
| Replay logs | `rtk_log_replayer_multi` |
