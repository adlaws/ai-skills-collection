# VAS Testing Strategy

*How to test VAS components effectively*

## Testing Architecture

VAS employs a **layered testing strategy:**

```
Unit Tests (component in isolation)
    ↓
Integration Tests (components + mock neighbors)
    ↓
System Tests (full VAS + simulated hardware)
    ↓
Hardware-in-Loop Tests (real sensors, real DDS)
```

## Unit Testing

### Scope
- Single class/function
- All dependencies mocked
- Fast (<100ms per test)
- High code coverage target (>80%)

### Tools
- **Framework:** Google Test (gtest)
- **Mocking:** Google Mock (gmock)
- **Build:** CMake with `rtk_enable_gtesting()`

### Example: Testing Localiser

**File:** `stacks/pose-stack/localiser/test/localiser_test.cpp`

```cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "localiser.h"

// Mock the GNSS driver input
class MockGNSSReader : public GNSSReader {
 public:
  MOCK_METHOD(RawIMUData, read_latest, (), (override));
};

// Test fixture
class LocaliserTest : public ::testing::Test {
 protected:
  MockGNSSReader mock_gnss_;
  Localiser localiser_{&mock_gnss_};
};

// Test: Localiser publishes pose at correct rate
TEST_F(LocaliserTest, PublishesPoseAt50Hz) {
  RawIMUData sample = {
    .timestamp_us = now_us(),
    .accel_x = 0.0f, .accel_y = 0.0f, .accel_z = 9.81f,  // 1G down
    .gyro_x = 0.0f, .gyro_y = 0.0f, .gyro_z = 0.0f,
    .lat = 40.7128, .lon = -74.0060, .alt = 10.0f
  };

  EXPECT_CALL(mock_gnss_, read_latest())
    .Times(50)
    .WillRepeatedly(::testing::Return(sample));

  std::vector<ComputedPose> outputs;
  MockPoseSubscriber sub;
  EXPECT_CALL(sub, on_pose)
    .Times(50)
    .WillRepeatedly([&](const ComputedPose& p) { outputs.push_back(p); });

  localiser_.set_subscriber(&sub);
  for (int i = 0; i < 50; ++i) {
    localiser_.step();  // Single iteration
  }

  EXPECT_EQ(outputs.size(), 50);
}

// Test: Localiser accepts valid IMU data
TEST_F(LocaliserTest, AcceptsValidIMUData) {
  RawIMUData valid = create_valid_imu_sample();
  EXPECT_CALL(mock_gnss_, read_latest()).WillOnce(Return(valid));

  EXPECT_NO_THROW(localiser_.step());
}

// Test: Localiser rejects corrupted data
TEST_F(LocaliserTest, RejectsNaNValues) {
  RawIMUData corrupted = create_valid_imu_sample();
  corrupted.lat = NAN;  // Corrupted

  EXPECT_CALL(mock_gnss_, read_latest()).WillOnce(Return(corrupted));

  EXPECT_CALL(mock_health_, on_error("INVALID_GNSS_DATA"));
  localiser_.step();
}
```

### Running Unit Tests

```bash
# Run all tests:
cd build
ctest

# Run specific test file:
ctest -R "localiser_test" -V

# Run with output:
./stacks/pose-stack/localiser/localiser_test --gtest_color=yes

# Run with coverage:
cmake --build . --target coverage
# Report in /build/coverage/index.html
```

## Integration Testing

### Scope
- Multiple components interacting
- Mock external systems (hardware, network)
- Verify data flows through DDS
- Slower but more realistic (<5 sec per test)

### Integration Test Example: GNSS→Localiser→Pose

**File:** `stacks/pose-stack/test/integration_pose_flow_test.cpp`

```cpp
#include <gtest/gtest.h>
#include "gnss_driver.h"
#include "localiser.h"
#include "full_body_pose_translator.h"
#include "dds_test_harness.h"

class PoseFlowIntegrationTest : public ::testing::Test {
 protected:
  MockGNSSHardware mock_gnss_;
  GNSSDriver gnss_driver_{&mock_gnss_};
  MockVehicleModel vehicle_model_;

  DDSTestHarness dds_{DomainID::VAS};

  void SetUp() override {
    // Create DDS participants
    auto pc = dds_.create_participant();

    gnss_driver_.enable_dds_publish(pc);
    localiser_.enable_dds_subscribe(pc);
    translator_.enable_dds_subscribe(pc);
  }
};

// End-to-end test: GNSS data → final pose
TEST_F(PoseFlowIntegrationTest, RawGNSSFlowsToAssetPose) {
  // Simulate GNSS hardware producing 5 samples
  std::vector<RawIMUData> mock_samples = {
    create_gnss_sample(0.0f, 0.0f, time_us=0),
    create_gnss_sample(0.1f, 0.0f, time_us=20000),
    create_gnss_sample(0.2f, 0.0f, time_us=40000),
    create_gnss_sample(0.3f, 0.0f, time_us=60000),
    create_gnss_sample(0.4f, 0.0f, time_us=80000),
  };

  // Feed through the system
  for (const auto& sample : mock_samples) {
    mock_gnss_.simulate(sample);

    gnss_driver_.step();
    localiser_.step();
    translator_.step();

    dds_.spin_once(timeout_ms=100);
  }

  // Verify pose reaches DDS
  auto poses = dds_.get_published<MultiPose>("/MultiPose");
  EXPECT_GE(poses.size(), 3);  // At least 3 poses published

  // Verify pose quality
  const auto& latest = poses.back();
  EXPECT_NEAR(latest.position.latitude, 0.4f, 0.01f);
  EXPECT_GE(latest.covariance[0], 0.0f);  // Valid covariance
}

// Integration test: Health events flow from driver
TEST_F(PoseFlowIntegrationTest, GNSSErrorGeneratesHealthEvent) {
  mock_gnss_.simulate_error(GNSSError::RTK_SIGNAL_LOST);

  gnss_driver_.step();
  dds_.spin_once(timeout_ms=100);

  auto health_events = dds_.get_published<HealthJustification>("/HealthJustification");
  EXPECT_GE(health_events.size(), 1);
  EXPECT_EQ(health_events.back().component_id, "gnss_driver");
  EXPECT_EQ(health_events.back().event, HealthEventType::GNSS_RTK_NO_FIX);
}
```

### Running Integration Tests

```bash
# Run all integration tests:
ctest -R "integration" -V

# Run with DDS debugging:
export NDDS_DISCOVERY_PEERS=127.0.0.1
ctest -R "integration" -V --output-on-failure
```

## System Testing

### Scope
- Full VAS bundle running
- Simulated hardware (sensors via `sensor-emulation-library`)
- Real DDS domains and routing
- Realistic scenarios (RTK loss, multipath, etc.)

### System Test Scenario: RTK Loss Recovery

**File:** `test/system_rtk_recovery_test.cpp`

```cpp
#include <gtest/gtest.h>
#include "vas_bundle_harness.h"

class RTKRecoverySystemTest : public ::testing::Test {
 protected:
  VASBundle vas_;  // Entire VAS running
  SimulatedGNSS gnss_sim_;

  void SetUp() override {
    vas_.start_all_components();
    gnss_sim_.attach_to_via_dds(&vas_.gnss_driver());
  }
};

// Scenario: Vehicle loses RTK, recovers after 30 seconds
TEST_F(RTKRecoverySystemTest, RecoveryAfter30SecondLoss) {
  // Initial: RTK locked
  auto pose_before = vas_.wait_for_pose_update(timeout_ms=1000);
  EXPECT_TRUE(pose_before.has_rtk_fix);

  // Trigger RTK loss
  gnss_sim_.disconnect_base_station();

  // Verify health event published
  auto health = vas_.wait_for_health_event(
    [](const auto& h) { return h.event == HealthEventType::GNSS_RTK_NO_FIX; },
    timeout_ms=5000
  );
  EXPECT_TRUE(health);

  // Pose refinement degrades gracefully (INS fallback)
  for (int i = 0; i < 60; ++i) {
    auto pose = vas_.get_latest_pose();
    EXPECT_LE(pose.covariance[0], 2.0f);  // Uncertainty grows but bounded
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
  }

  // Reconnect RTK
  gnss_sim_.reconnect_base_station();

  // Verify recovery health event
  auto recovery_health = vas_.wait_for_health_event(
    [](const auto& h) { return h.event == HealthEventType::GNSS_RTK_RECOVERED; },
    timeout_ms=10000
  );
  EXPECT_TRUE(recovery_health);

  // Pose should return to high confidence
  auto recovered_pose = vas_.wait_for_condition(
    [&]() {
      auto p = vas_.get_latest_pose();
      return p.has_rtk_fix && p.covariance[0] < 0.1f;
    },
    timeout_ms=5000
  );
  EXPECT_TRUE(recovered_pose);
}

// Scenario: Boundary interaction detection (Precision variant)
TEST_F(RTKRecoverySystemTest, BoundaryDetectionTriggersNearZoneBorder) {
  // Load survey boundary data
  vas_.load_boundary_file("test_data/survey_boundary.xml");

  // Simulate approach to boundary
  gnss_sim_.set_trajectory({
    {40.0, -74.0, alt=10.0},  // 100m from boundary
    {40.01, -74.0, alt=10.0}, // 50m from boundary
    {40.02, -74.0, alt=10.0}, // @ boundary
    {40.03, -74.0, alt=10.0}, // Over boundary (alert!)
  });

  // Run trajectory
  for (int i = 0; i < 4; ++i) {
    vas_.simulate_next_position();
    std::this_thread::sleep_for(100ms);
  }

  // Verify boundary interaction event
  auto boundary_event = vas_.wait_for_event(
    [](const auto& e) { return e.type == EventType::BOUNDARY_CROSSED; },
    timeout_ms=5000
  );
  EXPECT_TRUE(boundary_event);

  // FMS should have received notification
  auto fms_notification = vas_.get_field_domain_notification();
  EXPECT_NE(fms_notification, nullptr);
}
```

### Running System Tests

```bash
# Run all system tests:
ctest -R "system" -V --output-on-failure

# Run specific scenario:
ctest -R "system_rtk_recovery" -V

# Kill any hung processes afterward:
pkill -f "vas_bundle_harness"
```

## Hardware-in-Loop Testing

### Setup

**Real GNSS receiver** connected to devbox + simulated FMS

```bash
# Connect GNSS device:
ls /dev/ttyUSB*  # Find device

# Configure environment:
export VAS_GNSS_PORT="/dev/ttyUSB0"
export VAS_GNSS_BAUDRATE="115200"

# Run VAS in "hardware" mode:
./build/bin/vas_bundle rtk_os/vas.xml
```

### Verification

```bash
# In another terminal, monitor pose
rtiddsspy | grep -i "AssetPose"

# Expected output (every 50ms):
# AssetPose (from vas_interface_stack): lat=40.7128, lon=-74.0060, cov[0]=0.08

# Monitor health events
rtiddsspy | grep -i "HealthEvent"

# Expected: periodic GNSS_RTK_FIX_OK events
```

## Continuous Integration (CI)

VAS CI pipeline runs all tests on every commit:

```bash
# Local simulation of CI:
bash .vscode/clean.sh && bash .vscode/build.sh
ctest -V --output-on-failure

# Expected: ~200 tests passing, <10min runtime
```

## Test Coverage Goals

| Layer | Target Coverage | Tools |
|-------|-----------------|-------|
| Unit | 80%+ | gcov + lcov |
| Integration | 60%+ | manual review |
| System | 40%+ (high-value paths) | manual review |

**Generate coverage report:**
```bash
cmake --build ./build --target coverage
open build/coverage/index.html
```

---

**Questions about testing? Ask vas-expert for examples or troubleshooting tips.**
