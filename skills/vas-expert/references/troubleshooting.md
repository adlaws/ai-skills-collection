# VAS Troubleshooting Guide

*Common issues and solutions for VAS deployment and development*

## Pose-Related Issues

### Stale Asset Pose in FMS

**Symptom:** FMS shows old timestamp for `/asset_pose`, not updating

**Diagnosis:**
1. Check GNSS driver health:
   ```bash
   rtiddsspy | grep -i "HealthJustification"
   # Look for GNSS_RTK_NO_FIX events
   ```

2. Verify localiser running:
   ```bash
   ps aux | grep localiser
   systemctl status vas-localiser
   ```

3. Confirm DDS connectivity:
   ```bash
   rtiddsspy | grep -i "/ComputedPose"
   # Should see new samples every 20ms
   ```

4. Check routing service:
   ```bash
   ps aux | grep routing_service
   systemctl status vas-routing-service
   ```

**Solutions:**
- **If GNSS driver not running:** `systemctl restart vas-gnss-driver`
- **If localiser stalled:** Check logs: `journalctl -u vas-localiser -n 50`. Likely: RTK timeout or corrupted input.
- **If pose not routing:** Verify field_domain participant is online (`rtiddsspy`). Check DDS config.
- **If RTK lost:** Verify base station connection, antenna placement, sky view.

### Position Jumps / High Uncertainty

**Symptom:** Asset pose occasionally jumps meters or shows high covariance

**Causes:**

| Cause | Indicator | Fix |
|-------|-----------|-----|
| **RTK float→fix transition** | Covariance suddenly drops 10×; position accurate after | Normal behavior—FMS should wait for reliable pose |
| **Multipath / reflections** | Covariance oscillates; position drifts slowly | Move antenna to roof, away from metal structures |
| **INS not converged** | High roll/pitch error on first 30 seconds | Wait 30s after startup before critical decisions |
| **Antenna cable loose** | Frequent RTK loss; GNSS status reports poor SNR | Reseat connector, check continuity |
| **Dual antenna misalignment** | Heading error >5°; baseline not locked | Re-survey antenna baseline; check mounting |

**Debug covariance:**
```cpp
auto pose = get_latest_pose();
float pos_uncertainty = sqrt(pose.covariance[0]);  // meters
if (pos_uncertainty > 0.5) {
  LOG_WARN("Pose uncertainty high: " << pos_uncertainty << "m");
  // FMS should reduce trust in this pose
}
```

## DDS/Communication Issues

### Topics Not Appearing in FMS

**Symptom:** `rtiddsspy` shows no `/asset_pose` in field_domain

**Debug:**
```bash
# 1. Verify topic exists in vas_domain:
rtiddsspy | grep -i "asset_pose"
# If yes, continue; if no: localiser not publishing

# 2. Verify routing service running:
ps aux | grep routing_service
# If not running: systemctl restart vas-routing-service

# 3. Check routing service logs:
journalctl -u vas-routing-service -n 100
# Look for: "Route enabled: asset_pose" or error messages

# 4. Verify network connectivity:
ping <fms_ip>
# If unreachable: network down / firewall blocking
```

**Common fixes:**
- Restart routing service: `systemctl restart vas-routing-service`
- Verify DDS config points to correct domain IDs (check `rtk_os/common.xml`)
- Check firewall: DDS uses UDP ports 7410-7425 by default (see `networking-requirements.md` for full port table)

### DDS Domain Mismatch

**Symptom:** Error: "Cannot discover domain participant for domain 2"

**Cause:** VAS and FMS using different DDS domain IDs, or network unreachable

**Fix:**
```xml
<!-- rtk_os/common.xml -->
<DDS_DOMAIN_PARTICIPANT>
  <domain_id>1</domain_id>  <!-- VAS domain -->
</DDS_DOMAIN_PARTICIPANT>

<!-- Check FMS using domain 2 (field_domain) -->
<!-- If not: coordinate with FMS team on domain IDs -->
```

Also verify:
- Network connectivity: `ping <fms_ip>`
- Firewall allows UDP ports 7416-7420 (see `networking-requirements.md`)
- DDS discover peers configured: `export NDDS_DISCOVERY_PEERS=<fms_ip>:7400`

### High Latency / Delayed Messages

**Symptom:** FMS pose updates lag 2-3 seconds behind reality

**Causes:**
1. **Network timeout:** DDS retrying send
2. **Congestion:** Multiple large topics overwhelming network
3. **System overload:** CPU maxed, threads starved

**Mitigation:**
```xml
<!-- rtk_os/common.xml: Tune for low latency -->
<participant_qos>
  <reliability>RELIABLE</reliability>
  <latency_budget_ms>50</latency_budget_ms>  <!-- Max 50ms delay -->
  <transport_priority>FAST</transport_priority>
</participant_qos>
```

**Monitor latency:**
```bash
# In FMS, check message timestamp vs. current time
auto age_ms = now_ms() - pose.timestamp_ms;
if (age_ms > 100) {
  LOG_WARN("Asset pose is " << age_ms << "ms old");
}
```

## Hardware Integration Issues

### GNSS Driver Fails to Initialize

**Symptom:** `systemctl status vas-gnss-driver` shows error

**Common causes:**

| Error | Fix |
|-------|-----|
| `Cannot open /dev/ttyUSB0` | Device not plugged in; check: `ls /dev/ttyUSB*` |
| `Permission denied` | User not in dialout group: `sudo usermod -a -G dialout $USER` |
| `Timeout reading from device` | Device offline or wrong baud rate; verify 115200 bps |
| `Bad frame checksum` | Cable intermittent; reseat connectors |

**Verify serial connectivity:**
```bash
# Install minicom if needed
sudo apt install minicom

# Connect to device (exit with Ctrl-A X):
sudo minicom -D /dev/ttyUSB0 -b 115200

# Should see periodic GGA sentences or device output
```

### Motium Wheel Encoder Not Connecting (Precision)

**Symptom:** No motion data in logs; pose heading not improving

**Debug:**
```bash
# 1. Check CAN interface up:
ip link show can0
# Should show "UP" state

# 2. Verify CAN traffic:
candump can0 | head -20
# Should see frames with Motium data (typically ID 0x200-0x2FF)

# 3. Check driver config:
cat rtk_os/vas_precision.xml | grep -A5 "Motium"
# Verify CANInterface and CANBaudrate match hardware
```

**Common CAN issues:**
```bash
# CAN interface down:
sudo ip link set can0 up type can bitrate 1000000

# CAN bus errors (check dmesg):
dmesg | tail -20 | grep -i can

# Device permissions:
sudo usermod -a -G can $USER
```

## Building Issues

### CMake Failed with "RTI Connext not found"

**Symptom:** `CMake Error: Could not find RTI Connext DDS`

**Fix:**
```bash
# Set environment variable:
export CONNEXTDDS_DIR=/opt/rti_connext_dds-6.0.0  # Adjust version

# Or set up in shell profile:
echo 'export CONNEXTDDS_DIR=/opt/rti_connext_dds-6.0.0' >> ~/.bashrc

# Then rebuild:
rm -rf build
cmake -B build .
```

### Data Type Mismatch Errors at Runtime

**Symptom:** `Error: Type mismatch when deserializing message`

**Cause:** Built against old `common_data_types` package

**Fix:**
```bash
# Update RTK Suite:
sudo apt update && sudo apt install rtk-suite

# Rebuild VAS:
rm -rf build
cmake -B build .
cmake --build build -j8
```

## Testing/Validation Issues

### Unit Tests Failing

**Symptom:** `ctest` reports failures

**Debug:**
```bash
# Run specific test with output:
ctest -R "my_test_name" -V

# Run test directly to see full error:
./build/stacks/pose-stack/localiser/localiser_test

# Get test output and stack trace:
ctest -R "my_test_name" --output-on-failure
```

### Integration Tests Timeout

**Symptom:** Test hangs for 30+ seconds then fails with timeout

**Likely causes:**
1. DDS participant initialization stalled (network issue)
2. Mutex deadlock in test code
3. Topic subscription never firing callback

**Debug:**
```bash
# Run with timeout and core dump:
ulimit -c unlimited
timeout 10s ./build/integration_test
# If hangs: use gdb to attach and see stack trace

# Verify DDS connectivity in test:
rtiddsspy  # (in another terminal while test running)
```

### Memory Leaks in Tests

**Symptom:** `LeakSanitizer` report in test output

**Check for common leaks:**
```cpp
// ❌ Not freed:
std::shared_ptr<MyClass> ptr = new MyClass();  // Memory leak!

// ✓ Correct:
auto ptr = std::make_shared<MyClass>();

// In tests, ensure cleanup:
TEST_F(MyTest, SomethingTest) {
  auto resource = setup_resource();
  // ... test code ...
  cleanup_resource(resource);  // Must call cleanup
}
```

**Run tests with leak detection:**
```bash
export LSAN_OPTIONS=verbosity=1
ctest -R "my_test" -V
```

## Performance Issues

### Low Pose Update Rate

**Symptom:** Poses publishing < 50 Hz (target)

**Measure rate:**
```bash
# Subscribe and count:
rtiddsspy -d 1 -t /ComputedPose | grep -c "DataSample"
# In 1 second, should see ~50 lines

# If <50: check CPU usage
top -p $(pidof localiser)
# If CPU > 90%: likely compute bottleneck
```

**Optimize:**
1. Increase thread priority: `nice -n -19 localiser`
2. Enable compiler optimizations: `-O3 -march=native`
3. Check for locks contention in code

### Memory Usage Growing Over Time

**Symptom:** VAS process memory steadily increases (memory leak)

**Debug:**
```bash
# Monitor memory:
watch -n 1 'ps aux | grep -E "vas|localiser" | grep -v grep'

# Verify no accumulating queues:
grep -r "queue.push_back" stacks/
# Ensure associated pop_front calls exist

# Run with address sanitizer:
cmake -B build -DENABLE_ASAN=ON .
cmake --build build
# Will report leaks and usage errors
```

## Network/Deployment Issues

### VAS Package Installation Fails

**Symptom:** `apt install ./vas_*.deb` reports conflicts or errors

**Debug:**
```bash
# Check dependencies:
sudo apt update
apt-cache showpkg vas

# Install with verbose output:
sudo apt install -f --reinstall -y ~/build/debian_build/vas_*_amd64.deb

# Check for conflicting packages:
dpkg -l | grep -i vas
```

### Onboard Asset Cannot Reach FMS

**Symptom:** DDS participant in field_domain never discovers

**Check connectivity:**
```bash
# 1. Network accessible:
ping <fms_ip>

# 2. DDS discovery working:
export NDDS_DISCOVERY_PEERS=<fms_ip>:7400
rtiddsspy
# Should see FMS domain participants

# 3. Check firewall:
sudo ufw status
# DDS needs UDP 7416-7420 open (see networking-requirements.md for full port table)
```

For comprehensive network diagnosis, see `networking-requirements.md`.

---

**Still stuck? Collect logs and ask vas-expert:**
```bash
# Full system diagnostics:
tar -czf vas_debug_$(date +%s).tar.gz \
  /var/log/vas/* \
  /proc/$(pidof localiser)/cmdline \
  /proc/$(pidof localiser)/maps \
  build/compile_commands.json
```
