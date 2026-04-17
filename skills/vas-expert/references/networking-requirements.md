# VAS Networking Requirements

*Comprehensive guide to networking, ports, bandwidth, and connectivity for VAS deployment*

## Overview

VAS is fundamentally a **networked system** with dependencies on RTK base station connectivity, DDS middleware communication, and uplinks to FMS. This guide covers all networking aspects: port allocations, bandwidth requirements, latency budgets, firewall rules, and topology considerations for each VAS variant.

## DDS Networking Architecture

### DDS Domains and Network Topology

VAS uses RTI Connext DDS with three logical domains operating on the same physical network or separate networks:

```
┌─────────────────────────────────────────────────────────┐
│ Asset (Vehicle) - RTK-OS Linux machine                  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ VAS Instance (via RTI Connext DDS)              │   │
│  │                                                 │   │
│  │  Domain 1 (vas_domain)                         │   │
│  │  - Participants: GNSS driver, localiser,       │   │
│  │    full_body_pose_translator, routing service  │   │
│  │  - UDP ports: 7410-7415 (local only)           │   │
│  │                                                 │   │
│  │  Domain 2 (field_domain) - EXTERNAL            │   │
│  │  - DDS bridge to FMS / OCS                      │   │
│  │  - UDP ports: 7416-7420                        │   │
│  │                                                 │   │
│  │  Domain 3 (iai_domain) - EXTERNAL              │   │
│  │  - DDS bridge to Instrumented Asset Interface  │   │
│  │  - UDP ports: 7421-7425                        │   │
│  └─────────────────────────────────────────────────┘   │
│           ↓                                             │
│  Serial: /dev/ttyUSB0 (GNSS receiver)                   │
│  CAN: can0 (Motium encoder - Precision only)            │
│  Ethernet: eth0 or wlan0 (network uplink)               │
└─────────────────────────────────────────────────────────┘
          ↓↓            ↓↓           ↓↓
   RTK Server    FMS/OCS Server    IAI Service
   Port 2101     Port 8080+         Port 8081+
   (NTRIP)       (HTTP)             (DDS bridge)
```

### Port Allocation Table

| Port Range | Protocol | Domain | Direction | Purpose | Notes |
|-----------|----------|--------|-----------|---------|-------|
| **7410-7415** | UDP | vas_domain | Intra-asset | DDS discovery, participant communication | Local only (not routed externally) |
| **7416-7420** | UDP | field_domain | Bidirectional | DDS bridge to FMS/OCS | External—requires firewall rules |
| **7421-7425** | UDP | iai_domain | Bidirectional | DDS bridge to IAI service | External—requires firewall rules |
| **2101** | TCP | N/A | Inbound | NTRIP RTK corrections from base station | Standard NTRIP port |
| **80** | TCP | N/A | Inbound | HTTP NTRIP (alternative, non-standard) | Less common; higher latency |
| **443** | TCP | N/A | Inbound | HTTPS NTRIP / secure RTK uplink | Encrypted alternative |
| **9000-9100** | TCP/UDP | N/A | Outbound | RTK base station data (varies by provider) | Site-specific; check provider |
| **20000-20100** | UDP | N/A | Reserved | Potential future extensions | Not currently used |

### DDS Port Allocation Scheme

RTI Connext uses a **predictable port numbering scheme**:

```
Base port = 7400 + (150 × domain_id) + offset
```

For VAS:

```
vas_domain (ID=1):
  Base = 7400 + 150 = 7550
  Participant 0: 7550 + 0   = 7550
  Built-in endpoints: 7550 + 0-5

  ⚠️  BUT: Actual implementation uses 7410-7415 (check rtk_os/common.xml)

field_domain (ID=2):
  Base = 7400 + 300 = 7700
  Actual: 7416-7420 (as configured)

iai_domain (ID=3):
  Base = 7400 + 450 = 7850
  Actual: 7421-7425 (as configured)
```

**Note:** Actual ports are configured in `rtk_os/common.xml`. Always verify before deployment.

## GNSS/RTK Connectivity

### AN GNSS Receiver Connection

**AN (Advanced Navigation) GNSS-INS dual-antenna receivers** support multiple connection methods:

#### Option 1: Serial (RS232/RS485)

```
Hardware:
  - Connector: DB9 or USB-RS232 adapter
  - Baud rate: 115,200 bps (standard)
  - Flow control: None (RTS/CTS optional)
  - Handshake: 8 data, 1 stop, no parity

Data rate:
  - Raw GNSS: ~900 bytes/sec
  - IMU: ~600 bytes/sec
  - Combined: ~1.5 KB/sec

Latency: <20 ms (serial line dominates)

Configuration (rtk_os/vas.xml):
  <SerialURL>serial:///dev/ttyUSB0@115200</SerialURL>
```

#### Option 2: TCP/IP (Ethernet)

```
Hardware:
  - Receiver IP: 192.168.1.100 (example)
  - Port: 5000 (AN receiver default)
  - Protocol: TCP
  - Streaming: Continuous after connect

Data rate:
  - Same as serial (~1.5 KB/sec)
  - Encapsulation overhead: ~40 bytes/packet

Latency: <10 ms (LAN) to <100 ms (WAN)

Configuration:
  <SerialURL>tcp://192.168.1.100:5000</SerialURL>
```

#### Option 3: UDP (Multicast)

```
Hardware:
  - Receiver broadcasts on 224.0.0.1:5000
  - Multicast TTL: 1 (local network)

Latency: <5 ms (multicast)
Reliability: Best-effort (may lose packets)

Configuration:
  <SerialURL>udp://224.0.0.1:5000</SerialURL>  # Non-standard; verify support
```

### RTK Corrections Distribution

RTK corrections flow in the opposite direction: from base station → vehicle

#### NTRIP (Network Transport of RTCM via Internet Protocol)

**Standard protocol for RTK:** NTRIP RFC 2616

```
Connection:
  - Server: ntrip.provider.com:2101 (default)
  - Protocol: TCP (encrypted: TLS port 2101 or custom 443)
  - Authentication: HTTP Basic (username:password)
  - Mount point: /RTCM3_STANDARD (varies by provider)

Data flow:
  NTRIP Server (base station)
    ↓ (RTCM3 format)
  NTRIP Caster (central distributor)
    ↓ TCP 2101
  VAS GNSS Driver
    ↓ (injects into receiver)
  Receiver achieves RTK lock

Data rate:
  - RTCM3: 500-2000 bytes/sec (depends on distance, baseline)
  - Latency budget: <30 seconds (receiver can coast on INS if corrections lost)

Configuration (rtk_os/vas.xml):
  <RTK>
    <CorrectionSource>
      <Protocol>NTRIP</Protocol>
      <Server>ntrip.provider.com</Server>
      <Port>2101</Port>
      <MountPoint>/RTCM3</MountPoint>
      <Username>vehicle_uuid</Username>
      <Password>rtk_password_hash</Password>
    </CorrectionSource>
    <RetryIntervalMs>5000</RetryIntervalMs>
  </RTK>
```

**Common providers:**
- Trimble RTX (www.trimble.com)
- u-blox SPARTN (spartnSSR)
- Emlid Corrections
- OpenRTK

#### Bandwidth & Latency SLA

```
Upload to vehicle:
  ✓ Minimum: 10 kbps (NTRIP comfortable)
  ✓ Typical: 50-100 kbps (with margin for other traffic)
  ✓ Latency: <100 ms (RTK lock at 30-50 cm)

Loss tolerance:
  ✓ Brief loss (<5 sec): Position remains accurate (INS fallback)
  ✓ Prolonged loss (>30 sec): Position degrades to <2 m error
  ✓ Extended loss (>2 min): Switch to dead-reckoning (heading/velocity only)

Alert threshold:
  → Health event triggered: RTK_NO_FIX (after 5 sec loss)
  → FMS notification: "Precision degraded, use caution"
```

## Vehicle Network Uplink

### WiFi/LTE/Cellular Requirements

VAS requires **continuous, low-latency connectivity** to FMS/OCS for:
- Pose publication (50 Hz, ~100 bytes/sample = 5 KB/sec)
- Health events (bursty, ~1 KB each)
- Telemetry (1 Hz, ~200 bytes = 200 B/sec)
- RTK corrections upstream (varies)

#### Bandwidth Budget

```
Typical VAS:
  Pose (50 Hz @ 100 bytes):        5 KB/sec
  Health events (sparse):           1 KB/sec
  Telemetry (1 Hz @ 200 bytes):    200 B/sec
  RTK corrections (if agent):       1 KB/sec
  ────────────────────────────────
  Total nominal:                    7 KB/sec (~56 kbps)

  With overhead & redundancy:      ~100 kbps baseline
  Recommended headroom:            500+ kbps uplink

VAS:Precision (additional):
  Boundary interactions (1 Hz):     500 B/sec
  Precision advisory (2 Hz):        1 KB/sec
  ────────────────────────────────
  Total:                            ~200+ kbps
```

#### Latency Budget

```
Pose publication → FMS display (end-to-end):
  VAS internal processing:          <50 ms
  DDS publish:                       <10 ms
  Network transmission:              <50 ms (LAN) / <200 ms (4G)
  FMS processing:                    <50 ms
  ────────────────────────────────
  Total acceptable:                  <300 ms (operator can perceive >500ms lag)

Critical alert flow (e.g., RTK loss):
  Health event generated:            <20 ms
  DDS publish:                       <10 ms
  Network → FMS:                     <100 ms
  ────────────────────────────────
  Total:                             <150 ms (operator should see within 1 sec)
```

#### Connection Strategy

**Recommended approach:**

```
Primary: WiFi (site network or temporary hotspot)
  - Setup: Connect to site WiFi SSID
  - Benefits: Low latency, high bandwidth
  - Failover: If WiFi signal <-80 dBm, switch to LTE

Secondary: 4G/LTE (cellular modem)
  - Setup: IoT SIM card with RTK provider account
  - Benefits: Reliable backup, works anywhere
  - Drawback: Higher latency (50-200 ms), metered bandwidth
  - Config: Automatic failover in VAS bridge

Tertiary: 5G (future)
  - Emerging: Sub-100ms latency possible
  - Setup: High-speed data plan
  - TBD: Specific VAS support
```

**Network failover configuration:**

```xml
<!-- rtk_os/common.xml -->
<Network>
  <PrimaryInterface>
    <Type>WiFi</Type>
    <SSID>site_network</SSID>
    <Fallback>true</Fallback>
    <FallbackThresholdRSSI>-80</FallbackThresholdRSSI>
  </PrimaryInterface>

  <SecondaryInterface>
    <Type>4G_LTE</Type>
    <ReconnectIntervalSec>30</ReconnectIntervalSec>
  </SecondaryInterface>
</Network>
```

## Variant-Specific Network Requirements

### VAS (Standard)

**Network topology:**

```
        GNSS-INS (serial)
            ↓
    GNSS Driver (via_domain)
            ↓
    Localiser → Pose Stack
            ↓
    VAS Interface Stack
            ↓
    RTI Routing Service
      ↙        ↘
  field_domain  iai_domain
      ↓            ↓
    FMS          IAI Service
```

**Ports required:**

| Type | Port | Direction | Bandwidth | Notes |
|------|------|-----------|-----------|-------|
| RTK corrections (NTRIP) | 2101 | Inbound | 1 KB/sec | From NTRIP server |
| DDS field_domain | 7416-7420 | Bidirectional | ~100 kbps | To FMS |
| DDS iai_domain | 7421-7425 | Outbound | ~50 kbps | To IAI (if connected) |
| Pose feedback | N/A | Inbound | Occasional | FMS may query pose status |

**Firewall rules (asset perspective):**

```
# Outbound (asset → network)
Allow TCP 2101      → NTRIP server (RTK corrections)
Allow UDP 7416:7420 → FMS (DDS field_domain)
Allow UDP 7421:7425 → IAI service (DDS iai_domain)

# Inbound (network → asset)
Allow UDP 7416:7420 from FMS (DDS resp/queries)
Allow UDP 7421:7425 from IAI (DDS resp/queries)
Allow TCP 2101 (NTRIP push data)

# Fully block
Deny all other inbound
```

### VAS:Precision

**Additional network requirements:**

```
        Motium (CAN)     GNSS-INS (serial)
            ↓                  ↓
    Motium Driver      GNSS Driver
            ↓                  ↓
            └────→ Localiser (fused) ←────┘
                      ↓
        Boundary Detection Stack
                      ↓
        Full Body Pose Translator
                      ↓
        VAS Interface Stack + Precision Advisor
              ↙       ↓        ↘
        field_domain         iai_domain    (A470 - optional)
```

**Additional ports:**

| Type | Port | Direction | Bandwidth |
|------|------|-----------|-----------|
| A470 CAN bridge (if used) | 5000+ | TCP/UDP | ~500 B/sec |
| Boundary design data uplink | 443 | HTTPS | Bulk transfer (startup only) |
| Survey data sync | 443 | HTTPS | ~1 MB per operation |

**Bandwidth increase:**

```
Base VAS:           ~100 kbps
Adding Precision:   +100 kbps (boundary interactions, advisory data)
With A470 bridge:   +50 kbps (CAN relay)
────────────────────────────
Total Precision:    ~250 kbps recommended
```

### VAS:AHT

**Minimal network footprint:**

```
OCS (field_domain)
        ↓ (commands)
VAS Interface Stack (bridge only)
        ↓ (status)
        ↓
  field_domain
        ↓
      OCS
```

**Ports required:**

| Type | Port | Direction | Notes |
|------|------|-----------|-------|
| DDS field_domain | 7416-7420 | Bidirectional | Commands from OCS, status queries |
| Heartbeat/keepalive | 7416-7420 | Bidirectional | Every 5 sec |

**Bandwidth:**

```
Minimal: ~20 kbps
  - No pose generation (OCS provides)
  - No GNSS/INS drivers
  - Only DDS bridge + reachability
```

## Network Diagnostics & Troubleshooting

### Verify DDS Connectivity

```bash
# Check if DDS domain participants are online:
rtiddsspy
# Expected output:
# [Participant 1] Domain: 1 (vas_domain)
#   Node id: 1
#   DomainParticipantQos: RELIABLE_READER
# [Participant 2] Domain: 2 (field_domain)
#   ...

# Monitor specific topics:
rtiddsspy -d 2 -t /asset_pose
# Should see pose samples with timestamps < 100ms old

# Check discovery peers:
export NDDS_DISCOVERY_PEERS=192.168.1.100:7400
rtiddsspy
# If FMS not appearing: network down or firewall blocking
```

### Check Firewall Rules

```bash
# On asset (Linux):
sudo ufw status verbose
# Expected: allow from any to any port 7410:7425

# Test outbound connectivity:
nc -u -zv 192.168.1.100 7416  # UDP to FMS
# If timeout: firewall blocking or FMS not listening

# Test NTRIP access:
curl -v -u username:password http://ntrip.server.com:2101/RTCM3
# Should return RTCM3 data stream

# Monitor bandwidth use:
sudo iftop -i eth0  # Real-time interface stats
nethogs -d 2         # Per-process bandwidth
```

### Measure Network Latency

```bash
# Ping FMS:
ping -c 10 192.168.1.100
# rtt min/avg/max = 5/12/25 ms (good LAN)
# rtt min/avg/max = 50/120/300 ms (4G cellular)

# Check DDS latency (pose age):
rtiddsspy | grep -i asset_pose
# timestamp should be < 50ms old (50 Hz = 20ms intervals)

# Trace network path:
mtr 192.168.1.100  # Real-time traceroute + latency
```

### Monitor RTK Connection

```bash
# Check NTRIP connection status:
ps aux | grep gnss_driver
# Should show process running

# Monitor RTK login retry:
journalctl -u vas-gnss-driver -f | grep -i "NTRIP\|RTK\|COR"
# Expected: periodic "RTK correction received" messages

# Check GNSS receiver signal:
# (Assuming hardware-specific tool available)
gnss_signal_monitor /dev/ttyUSB0
# Should show satellite count > 10, RTK status "FIX"
```

## Network Configuration Examples

### Scenario 1: Manned Vehicle at Active Mine Site

```xml
<!-- rtk_os/vas.xml -->
<Network>
  <!-- Primary: Mine WiFi mesh -->
  <WiFiLink>
    <SSID>MineOps_5GHz</SSID>
    <Priority>1</Priority>
    <FailoverThreshold>-80dBm</FailoverThreshold>
  </WiFiLink>

  <!-- Secondary: 4G modem backup -->
  <CellularLink>
    <Provider>Telstra_IoT</Provider>
    <Priority>2</Priority>
  </CellularLink>

  <!-- RTK: Provider's NTRIP network -->
  <RTKCorrections>
    <CorrectionSource>ntrip.fmg.gov.au:2101</CorrectionSource>
    <MountPoint>/AUS_Central</MountPoint>
  </RTKCorrections>
</Network>
```

**Expected latency:** <50 ms pose update → FMS
**Bandwidth per vehicle:** ~150 kbps
**Fleet of 20 vehicles:** 3 Mbps uplink aggregate

---

### Scenario 2: Precision Surveying Operation

```xml
<!-- rtk_os/vas_precision.xml -->
<Network>
  <!-- High-bandwidth LAN (temporary site setup) -->
  <EthernetLink>
    <Interface>eth0</Interface>
    <IP>192.168.100.50</IP>
    <Priority>1</Priority>
  </EthernetLink>

  <!-- RTK: High-precision base station (local) -->
  <RTKCorrections>
    <CorrectionSource>rtk_base_local:2101</CorrectionSource>
    <MountPoint>/RTK_SURVEY</MountPoint>
    <UpdateRate>10Hz</UpdateRate>  <!-- Higher frequency for precision -->
  </RTKCorrections>

  <!-- Boundary data sync -->
  <BoundaryDataSync>
    <Server>survey.fmg.internal</Server>
    <Protocol>HTTPS</Protocol>
    <SyncIntervalSec>300</SyncIntervalSec>
  </BoundaryDataSync>
</Network>
```

**Expected latency:** <20 ms (LAN)
**Bandwidth:** ~250 kbps
**RTK accuracy:** <0.1 m

---

### Scenario 3: Remote AHT Operation

```xml
<!-- rtk_os/vas_aht.xml -->
<Network>
  <!-- Primary: 4G LTE (everywhere coverage) -->
  <CellularLink>
    <Provider>Optus_Premium</Provider>
    <Priority>1</Priority>
    <MinBandwidthKbps>50</MinBandwidthKbps>
  </CellularLink>

  <!-- Failover: Satellite (emergency only) -->
  <SatelliteLink>
    <Provider>Inmarsat</Provider>
    <Priority>2</Priority>
    <ActivateThreshold>LTE_UNAVAILABLE</ActivateThreshold>
  </SatelliteLink>

  <!-- OCS command/control -->
  <CommandLink>
    <Server>ocs.fmgaws.cloud</Server>
    <Protocol>MQTT_over_TLS</Protocol>  <!-- More resilient than DDS over unreliable link -->
  </CommandLink>
</Network>
```

**Expected latency:** 50-200 ms (4G), 500+ ms (satellite)
**Bandwidth:** ~50 kbps minimum
**Reliability:** 99.5% uptime SLA (dual connectivity)

## Network Scaling & Multi-Vehicle Deployments

### Single Asset (VAS Standard)

```
Asset 1 (100 kbps)
        ↓
    WiFi / 4G
        ↓
    FMS Server (1 Mbps uplink capacity)
```

**Bandwidth:** Comfortable, no congestion

### Small Fleet (5 assets)

```
Asset 1 ─┐
Asset 2  ├─→ WiFi mesh (2.4 Mbps)
Asset 3  │
Asset 4  ├─→ Backup: 4G (shared SIM pool)
Asset 5 ─┘
        ↓
    FMS Server
```

**Required uplink:** 500+ kbps per asset × 5 = 2.5 Mbps
**Recommended WiFi:** 5 GHz mesh (300+ Mbps capacity)
**Cellular backup:** Load-balance across 3-4 SIM cards

### Large Fleet (50+ assets)

```
                FMS Server (10 Mbps uplink)
                        ↓
    ┌───────────────────┼───────────────────┐
    ↓                   ↓                   ↓
WiFi Mesh 1        WiFi Mesh 2        WiFi Mesh 3
(Zone A)           (Zone B)           (Zone C)
├─ Asset 1-15      ├─ Asset 16-30     ├─ Asset 31-50
└─ 1.5 Mbps        └─ 1.5 Mbps        └─ 1.5 Mbps

Cellular failover: 4G aggregation (bonded, load-balanced)
```

**Bandwidth planning:** 100-150 kbps per asset × 50 = 5-7.5 Mbps
**Recommended:** Enterprise LTE backhaul (10 Mbps+) + WiFi mesh redundancy

## Common Network Issues & Solutions

### Issue: DDS Participants Don't Discover

**Symptom:** `rtiddsspy` shows only local domain, FMS participants missing

**Root causes & fixes:**

```
1. Firewall blocking UDP 7416-7420:
   $ sudo ufw allow from 192.168.1.100 to any port 7416:7420

2. DDS domain ID mismatch:
   Asset: domain 2 (field_domain)
   FMS:   domain 3 (different!)
   → Fix: Align domain IDs in rtk_os/common.xml

3. Network unreachable:
   $ ping 192.168.1.100  # Should succeed
   → Fix: Check WiFi/LTE connection, verify IP routing

4. DDS discovery peers misconfigured:
   $ export NDDS_DISCOVERY_PEERS=192.168.1.100:7400
   $ rtiddsspy
   → Fix: Update NDDS_DISCOVERY_PEERS env var before starting VAS
```

### Issue: High Pose Latency (>200 ms)

**Symptom:** FMS displays stale positions from 2+ seconds ago

**Root causes & fixes:**

```
1. Network congestion:
   $ iftop -i eth0  # Check if interfacing saturated
   → Fix: Add QoS policy to prioritize DDS traffic

2. 4G uplink saturated:
   $ nethogs -d 2  # Check per-app bandwidth
   → Fix: Reduce telemetry frequency or enable selective publishing

3. DDS latency budget exceeded:
   rtk_os/common.xml: <latency_budget_ms>50</latency_budget_ms>
   → Fix: Increase latency_budget if network slower than LAN

4. RTK corrections blocking:
   $ ps aux | grep gnss_driver  # Check if stuck in RTK retry
   → Fix: Verify NTRIP server reachable, timeout values correct
```

### Issue: RTK Lock Frequently Lost

**Symptom:** Health events: periodic RTK_NO_FIX → RTK_RECOVERED

**Root causes & fixes:**

```
1. Correction server overloaded:
   $ curl -v http://ntrip.server:2101/RTCM3  # Measure response time
   → Fix: Switch to different mount point or provider

2. Network latency > 30 sec:
   $ mtr 192.168.1.100  # Check packet loss / timeouts
   → Fix: Reduce network distance or switch connection type

3. NTRIP credentials expire:
   journalctl -u vas-gnss-driver | grep -i "auth\|401"
   → Fix: Refresh credentials or extend token TTL

4. Receiver decoding corruption:
   $ gnss_stats /dev/ttyUSB0 | grep "RTCM.*error"
   → Fix: Reduce baud rate or check cable quality
```

---

**Have networking questions? Ask vas-expert—this guide covers all major scenarios.**
