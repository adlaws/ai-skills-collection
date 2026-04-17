# VAS Variant Configuration Guide

*How to build and deploy different VAS variants*

## Variant Overview

| Aspect | VAS | VAS:Precision | VAS:AHT |
|--------|-----|---------------|---------|
| **Primary use** | Manned vehicles | HiPrecision surveying | Autonomous trucks (AHT) |
| **Sensors** | GNSS-INS (RTK) | GNSS-INS + Motium | None (OCS-driven) |
| **Key components** | Pose stack + bridge | +Boundary detection | Bridge only |
| **Onboard complexity** | Medium | High | Minimal |
| **Config file** | `rtk_os/vas.xml` | `rtk_os/vas_precision.xml` | `rtk_os/vas_aht.xml` |
| **Deployment target** | Manned vehicle | Survey vehicle | AHT asset |

## VAS (Standard) Configuration

### Use Case

Standard manned vehicle requiring reliable positioning and status reporting to FMS.

### Hardware Requirements

* **GNSS/INS:** Advanced Navigation GNSS-INS receiver (e.g., AN-5200)
* **Connection:** Serial (RS232) or TCP/IP to receiver
* **Compute:** Embedded Linux computer (RTK-compatible)
* **Network:** WiFi/LTE to FMS field domain

### Building for VAS

```bash
# Standard build includes only VAS, not Precision/AHT
cd /workspace/vas
cmake -B build -DBUILD_TESTING=ON .
cmake --build build -j8

# Verify VAS-only targets:
ctest -R "^localiser|^gnss_driver|^vas_interface" -V

# Build Debian package (VAS variant):
bash build_deb.sh
# Output: vas_*_amd64.deb, vas-dbgsym_*_amd64.deb
```

### Configuration (rtk_os/vas.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<VAS_Config>
  <!-- Hardware interface -->
  <GNSS>
    <SerialURL>serial:///dev/ttyUSB0@115200</SerialURL>
    <RTKRetryIntervalMs>5000</RTKRetryIntervalMs>
  </GNSS>

  <!-- Positioning engine -->
  <Localiser>
    <OutputFrequencyHz>50</OutputFrequencyHz>
    <RTKTimeoutMs>5000</RTKTimeoutMs>
    <IMUBiasSettleTimeS>30</IMUBiasSettleTimeS>
  </Localiser>

  <!-- DDS connectivity -->
  <DDS>
    <VasDomainID>1</VasDomainID>
    <FieldDomainID>2</FieldDomainID>
    <FieldDomainPeers>192.168.1.100</FieldDomainPeers>
  </DDS>

  <!-- Vehicle model (for bounds computation) -->
  <VehicleModel>
    <Type>CAT390F</Type>  <!-- from robot_model_library -->
    <AntennaOffset_x>-0.5</AntennaOffset_x>
    <AntennaOffset_y>0.0</AntennaOffset_y>
    <AntennaOffset_z>2.1</AntennaOffset_z>
  </VehicleModel>
</VAS_Config>
```

### Deployment

```bash
# Install on manned vehicle:
sudo apt install ./vas_1.2.0_amd64.deb

# Start VAS service:
sudo systemctl start vas
sudo systemctl status vas

# Monitor pose output:
rtiddsspy | grep -i component_pose | tail -5
```

---

## VAS:Precision Configuration

### Use Case

High-precision operations: surveying, wheel-loading coordination, boundary awareness.

**Typical workflow:**

1. Driver/surveyor uploads boundary file to asset
2. VAS computes vehicle bounds relative to boundaries
3. Alerts driver when approaching/exceeding zones
4. Records precise position for later analysis

### Hardware Requirements

**VAS Precision-specific:**

* **Motium wheel encoders** (encoder data via CAN or direct interface)
* **A470 (optional)** — Onboard display for operator feedback
* **Boundary database** — Survey data (polygon coordinates)

**Plus standard VAS:**

* GNSS-INS receiver
* Embedded computer (higher CPU for boundary detection)
* Network connectivity

### Building for VAS:Precision

```bash
# Set build flag to include Precision components:
cmake -B build \
  -DBUILD_TESTING=ON \
  -DENABLE_VAS_PRECISION=ON \
  .

cmake --build build -j8

# Verify Precision-specific targets exist:
ctest -R "boundary_interaction|precision_advisor|motium_driver" -V

# Build Debian package:
bash build_deb.sh
# Same binary; behavior controlled by config
```

### Configuration (rtk_os/vas_precision.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<VAS_Precision_Config>
  <!-- Inherit VAS base config -->
  <import from="common.xml"/>

  <!-- Motium integration -->
  <Motium>
    <CANInterface>can0</CANInterface>
    <CANBaudrate>1000000</CANBaudrate>
    <AidingFrequencyHz>10</AidingFrequencyHz>
  </Motium>

  <!-- Boundary detection -->
  <BoundaryDetection>
    <Enabled>true</Enabled>
    <BuildingCheckFrequencyHz>20</BuildingCheckFrequencyHz>
    <InteractionMarginM>0.5</InteractionMarginM>  <!-- Alert at 0.5m before boundary -->
  </BoundaryDetection>

  <!-- Precision advisor -->
  <PrecisionAdvisor>
    <Enabled>true</Enabled>
    <SurveyDataPath>/var/data/survey_boundaries.xml</SurveyDataPath>
    <PositioningGuidanceFrequencyHz>5</PositioningGuidanceFrequencyHz>
  </PrecisionAdvisor>

  <!-- A470 integration (optional) -->
  <A470Bridge>
    <Enabled>false</Enabled>
    <CANNodeID>0x100</CANNodeID>
  </A470Bridge>

  <!-- Enhanced positioning -->
  <Localiser>
    <OutputFrequencyHz>100</OutputFrequencyHz>  <!-- Higher for precision ops -->
    <UseMotiumHeadingAiding>true</UseMotiumHeadingAiding>
  </Localiser>
</VAS_Precision_Config>
```

### Boundary File Format

**File:** `/var/data/survey_boundaries.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<SurveyBoundaries>
  <Zone name="Load_Point_A">
    <Description>Primary loader position</Description>
    <Boundary>
      <Point lat="40.7128" lon="-74.0060" alt="10.0"/>
      <Point lat="40.7130" lon="-74.0060" alt="10.0"/>
      <Point lat="40.7130" lon="-74.0058" alt="10.0"/>
      <Point lat="40.7128" lon="-74.0058" alt="10.0"/>
    </Boundary>
    <InteractionType>ZONE_OF_INTEREST</InteractionType>
  </Zone>

  <Zone name="No_Go_Area">
    <Description>Hazard zone—do not enter</Description>
    <Boundary>
      <Point lat="40.7135" lon="-74.0065" alt="10.0"/>
      <!-- ... polygon ... -->
    </Boundary>
    <InteractionType>DANGER_ZONE</InteractionType>
    <AlertLevel>CRITICAL</AlertLevel>
  </Zone>
</SurveyBoundaries>
```

### Deployment

```bash
# Install on precision vehicle:
sudo apt install ./vas_1.2.0_amd64.deb

# Upload or provision boundary data:
scp survey_boundaries.xml vas@precision-asset:/var/data/

# Start with Precision config:
sudo systemctl start vas VASCONFIG=vas_precision.xml

# Monitor boundary interactions:
rtiddsspy | grep -i "boundary_interaction"
```

---

## VAS:AHT Configuration

### Use Case

Autonomous Haul Truck (AHT) managed by centralized OCS. VAS runs minimal code—mainly a DDS bridge forwarding OCS commands/status.

**Data flow:**

```
OCS (field_domain)
  ↓ commands
VAS Interface Stack (DDS bridge)
  ↓ internal processing
  ↓ status/pose
field_domain / OCS
```

### Hardware Requirements

**VAS:AHT minimal:**

* **No onboard GNSS/INS** (OCS provides positioning)
* **Embedded computer** (minimal: just DDS)
* **Network** (must maintain link to OCS)

### Building for VAS:AHT

```bash
# Build with minimal components:
cmake -B build \
  -DBUILD_TESTING=ON \
  -DENABLE_VAS_AHT_ONLY=ON \  # Excludes localiser, pose stack
  .

cmake --build build -j8

# Verify AHT-only targets:
ctest -R "vas_interface_stack" -V
# Note: pose_stack tests skipped

# Build Debian package:
bash build_deb.sh
```

### Configuration (rtk_os/vas_aht.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<VAS_AHT_Config>
  <!-- Minimal config—most logic in OCS -->

  <!-- DDS bridge only -->
  <VAS_Interface_Stack>
    <Enabled>true</Enabled>
    <BridgeFieldDomainID>2</BridgeFieldDomainID>
    <BridgeIAIDomainID>3</BridgeIAIDomainID>
  </VAS_Interface_Stack>

  <!-- Not used (but config present for compatibility) -->
  <Localiser>
    <Enabled>false</Enabled>
  </Localiser>

  <GNSS>
    <Enabled>false</Enabled>
  </GNSS>

  <!-- OCS connection -->
  <OCS>
    <ControlDomain>field_domain</ControlDomain>
    <StatusTopic>/aht_status</StatusTopic>
    <CommandTopic>/aht_command</CommandTopic>
  </OCS>

  <!-- Minimal heartbeat to prevent shutdown -->
  <Watchdog>
    <HeartbeatIntervalS>5</HeartbeatIntervalS>
    <TimeoutS>30</TimeoutS>
  </Watchdog>
</VAS_AHT_Config>
```

### Deployment

```bash
# Install on AHT:
sudo apt install ./vas_1.2.0_amd64.deb

# Start with AHT config:
sudo systemctl start vas VASCONFIG=vas_aht.xml

# Verify bridge online:
rtiddsspy | grep -i "vas_interface"
# Expected: minimal output (OCS runs most logic)

# Monitor from OCS:
# (OCS should see AHT status topic)
```

---

## Multi-Variant Build & Deployment

### Build All Variants in CI

```bash
#!/bin/bash
# .vscode/build_all_variants.sh

set -e

for variant in VAS VAS_PRECISION VAS_AHT; do
  echo "Building $variant..."

  rm -rf build
  cmake -B build \
    -DENABLE_${variant}=ON \
    .

  cmake --build build -j8
  ctest -V --output-on-failure

  bash build_deb.sh
  # Output: vas_*_${variant}.deb
done

echo "All variants built successfully"
```

### Selecting Variant at Runtime

On target asset, choose variant before starting service:

```bash
# Option 1: Environment variable
export VAS_VARIANT=VAS_PRECISION
sudo systemctl start vas

# Option 2: Systemd override
sudo systemctl edit vas
# [Service]
# Environment="VAS_VARIANT=VAS_PRECISION"

# Option 3: Command line
vas --config /etc/vas/vas_precision.xml
```

## Troubleshooting Variant Configuration

### Issue: Components not starting (VAS:Precision)

**Symptom:** `sudo systemctl start vas` fails

**Debug:**

```bash
# Check if Motium driver compiled:
ldd build/bin/vas | grep -i motium
# If missing: rebuild with -DENABLE_VAS_PRECISION=ON

# Check config file syntax:
xmllint rtk_os/vas_precision.xml

# Verify CAN interface exists:
ip link | grep -i can0
```

### Issue: OCS can't see AHT status (VAS:AHT)

**Symptom:** OCS shows "AHT offline"

**Debug:**

```bash
# Verify DDS bridge running:
ps aux | grep vas_interface_stack

# Monitor DDS topics:
rtiddsspy | grep -i "/aht_status"
# If not appearing: check DDS domain ID mismatch

# Check network connectivity to OCS:
ping <ocs_ip>
```

---

**Need help choosing a variant? Ask vas-expert for recommendations based on your use case.**

<!-- Copyright 2026 Fortescue Ltd. All rights reserved. -->
