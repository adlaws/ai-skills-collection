# Pose Stack Architecture

*Reference for understanding VAS pose computation and integration*

## Overview

The **Pose Stack** is VAS's core positioning system. It receives noisy GNSS-INS measurements and outputs a clean, high-frequency 6-DOF pose (position + orientation) for use throughout VAS.

## High-Level Data Flow

```
GNSS-INS Device
     ↓ (raw measurements)
an-gnss-driver-rtk (driver)
     ↓ (DDS RawIMUData topic)
localiser (pose estimation)
     ↓ (ComputedPose)
full_body_pose_translator
     ↓ (MultiPose w/ bounds)
Asset Pose → VAS Interface Stack → FMS/V2X
```

## Core Components

### 1. GNSS Driver (an-gnss-driver-rtk)

**Responsibility:** Bridge the GNSS-INS hardware to DDS

**Inputs:**
- Serial/network stream from AN GNSS receiver
- RTK corrections from network (injected into receiver)

**Outputs:**
- `RawIMUData` topic (raw 9-DOF sensor fusion from receiver)
- Health/diagnostic events

**Key behaviors:**
- Connects to GNSS receiver (serial URL from config)
- Monitors RTK signal strength / baseline lock
- Publishes health events on RTK loss/restoration
- Publishes corrections to `/gnss_rtk_corrections` for fleet distribution
- Handles graceful shutdown (TCP/serial cleanup)

**Configuration:**
```xml
<!-- rtk_os/vas.xml -->
<GNSS>
  <SerialURL>serial:///dev/ttyUSB0@115200</SerialURL>
  <RTKCorrectionRetryRate_ms>5000</RTKCorrectionRetryRate_ms>
</GNSS>
```

### 2. Localiser (pose-stack/localiser)

**Responsibility:** Fuse GNSS-INS data into a stable pose estimate

**Inputs:**
- `RawIMUData` from GNSS driver
- Optional: Motium wheel encoder data (Precision variant)

**Outputs:**
- `ComputedPose` (position: lat/lon/alt, orientation: quaternion, covariance)

**Algorithm:**
- Tightly-coupled Kalman filter
- GNSS position + INS measurements fused
- Handles GNSS signal loss (coasts on INS, degrades confidence)
- Dual-antenna heading calculation (when available)
- Wheel encoder fusion for dead-reckoning assist (Precision)

**Publishing behavior:**
- Publishes at 50 Hz (configurable)
- Includes uncertainty matrix for downstream consumers
- Health metrics: RTK lock status, INS saturation, antenna baseline fix

**Configuration parameters:**
```yaml
pose_frequency_hz: 50        # Output rate
rtk_timeout_ms: 5000         # How long to coast on INS
imu_bias_settle_time_s: 30   # Initial calibration window
```

### 3. Full Body Pose Translator (vas-interface-stack/full_body_pose_translator)

**Responsibility:** Transform localiser pose into vehicle body frame + bounds

**Inputs:**
- `ComputedPose` from localiser
- Vehicle model (dimensions, antenna offset from center)

**Outputs:**
- `MultiPose` with bounding box
- Reference frames: global WGS84 → vehicle body → sensor frame

**Computation:**
- Transforms GNSS antenna position to vehicle center-of-mass
- Computes vehicle corners (bounds polygon)
- Includes covariance propagation through transforms

**Example transformation:**
```
Antenna position (lat, lon, alt) + antenna_offset_from_com
    ↓
Vehicle center position
    ↓ (rotate to vehicle frame)
Bounds polygon in local NED coordinates
```

## Why This Matters

### Accuracy

- **Bare GNSS:** ±30cm (with RTK)
- **After Kalman filter:** ±5-10cm
- **After dual-antenna heading fusion:** <0.5m lane-precise positioning

### Responsiveness

- 50 Hz pose output allows smooth trajectory tracking
- Low-latency bridging to FMS for real-time control decisions

### Robustness

- Covariance published downstream allows FMS to weight VAS pose appropriately
- INS fallback during RTK loss  (up to ~60 seconds of dead reckoning)

## Debugging Pose Issues

### Stale Asset Pose

**Symptoms:** `/asset_pose` topic not updating in FMS

**Debug steps:**
1. Check GNSS driver health events: `ctest -R "gnss_driver_health_test" -VV`
2. Verify localiser is running: `ps aux | grep localiser`
3. Check DDS connectivity: verify `vas_domain` participants online
4. Look at raw IMU data: subscribe to `/RawIMUData` and observe publication rate
5. Review localiser logs: `tail -f /var/log/vas/localiser.log`

### High Covariance / Uncertain Pose

**Symptoms:** FMS rejects commands due to "low confidence"

**Check:**
- RTK signal: is receiver locked to base station?
- Antenna setup: is baseline properly configured (dual-antenna systems)?
- Environment: has vehicle recently lost/regained GNSS (INS settling)?

### Position Jumps

**Symptoms:** `/asset_pose` occasionally jumps meters

**Causes:**
- RTK float→fix transition (expected, <0.3m)
- Multipath (poor antenna placement)
- INS gyro drift during turning

**Solutions:**
- Verify antenna is on vehicle roof  (not in cabin)
- Check antenna has clear sky view (90° dome)
- Consider adding inclinometer to vehicle model

## VAS:Precision-Specific: Motium Integration

**VAS:Precision** can integrate wheel encoders (Motium) for:
- Heading assist during INS convergence
- Velocity-aiding during RTK outages
- Dead-reckoning for < 30 second loss events

**Architecture:**
```
      GNSS-INS              Motium (wheel encoder)
           ↓                        ↓
    an-gnss-driver-rtk    motium-driver-rtk
           ↓________________________↓
                  localiser (fused)
                        ↓
                  ComputedPose (higher confidence heading)
```

---

**Want to understand pose covariance propagation? See `references/applied-math.md`**
