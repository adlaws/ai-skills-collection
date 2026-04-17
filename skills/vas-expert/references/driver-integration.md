# Driver Integration Checklist

*Guidelines for adding new sensors/hardware to VAS*

## Pre-Integration Review

### 1. Understand the VAS Driver Architecture

Every VAS driver follows this pattern:

```
Hardware Interface (serial, CAN, USB, TCP)
    ↓
RawData parsing & validation
    ↓
DDS Publisher (via RTI Connext)
    ↓
vas_domain subscribers (localiser, other components)
    ↓
Health events (on error/fault conditions)
```

**Example: GNSS Driver Flow**

```cpp
// In an-gnss-driver-rtk/src/driver.cpp
class GNSSDriver {
  GNSSDriver(const std::string& serial_url, RTIDomainParticipant* participant)
    : receiver_(serial_url), writer_(participant->get_gnss_topic_writer()) {}

  void run() {
    while (running_) {
      RawData raw = receiver_.read_frame();  // Serial read
      if (!raw.is_valid()) {
        notify_health_error("GNSS_FRAME_CORRUPT");
        continue;
      }
      IMUData imu = parse_to_imu(raw);
      writer_.publish(imu);  // Publish to vas_domain
    }
  }

  void on_rtk_loss() {
    notify_health_event("RTK_NO_FIX", Level::WARNING);
  }
};
```

### 2. Identify the Input/Output Data Types

**Input:** What raw data format does your sensor produce?
- Serial bytes? CAN frames? Network packets? File?

**Output:** What should VAS consumers see?
- Link to `common_data_types` package to find the matching IDL type
- If no match exists, you'll need to define one (coordinate with system architect)

**Example:**

```yaml
New sensor: Listeering wheel encoder
Input: CAN frame (ID 0x123, bytes [0:2] = tick_count, [3:4] = confidence)
Output: should map to common::motion::WheelEncoder
  msg.ticks = uint32 from bytes [0:2]
  msg.confidence_percent = uint8 from bytes [3:4]
```

### 3. Choose the Publishing Strategy

**Option A: Synchronous publishing** (simple, low throughput)
```cpp
void published() {
  Raw frame = hardware.read();  // blocks
  IMUData msg = parse(frame);
  writer.publish(msg);
}
```
✓ Simple
✗ Blocks entire thread; limited frequency

**Option B: Hardware interrupt + queue** (common)
```cpp
void on_hardware_data_ready(const RawFrame& frame) {
  queue.enqueue(parse(frame));  // ISR-safe
}

void publisher_thread() {
  while (running_) {
    IMUData msg = queue.dequeue_blocking(timeout=1ms);
    writer.publish(msg);
  }
}
```
✓ Low latency, high frequency
✓ ISR safe
✓ Handles backpressure

**Option C: Polling at fixed rate** (timing confidence)
```cpp
void polling_thread() {
  while (running_) {
    IMUData msg = hardware.read_latest();  // non-blocking
    writer.publish(msg);
    std::this_thread::sleep_for(std::chrono::milliseconds(20));  // 50 Hz
  }
}
```
✓ Predictable frequency
✓ Simple
✗ May miss data

**VAS recommendation:** Use Option B (interrupt + queue) for sensors like GNSS/IMU.

### 4. Implement Graceful Shutdown

VAS drivers must support clean termination:

```cpp
class MyDriver {
  volatile bool running_ = true;

  void shutdown() {
    running_ = false;
    hardware_->close();
    // Unblock any blocking I/O
    // Wait for threads to join
  }

  // In main app:
  void on_sigterm() {
    driver_->shutdown();
    // Exit cleanly
  }
};
```

**Why?** ROS/systemd send SIGTERM; VAS must shut down without data corruption or resource leaks.

### 5. Define Health Events

Drivers must report errors as **health events**:

```cpp
enum HardwareError {
  COMM_TIMEOUT,      // No data from device in 5sec
  CRC_FAILURE,       // Corrupted frame
  SIGNAL_LOSS,       // (GNSS) Lost RTK lock
  TEMPERATURE_HIGH,  // Thermal warning
};

void on_error(HardwareError err) {
  HealthJustification just;
  just.event = common::health::HealthEventType::COMPONENT_FAULT;
  just.component_id = "my_driver_v1";
  just.description = error_string(err);
  health_writer_.publish(just);
}
```

## Integration Steps

### Step 1: Create Driver Directory

```bash
drivers/
  my-sensor-driver/
    CMakeLists.txt
    src/
      my_sensor_driver.cpp
      my_sensor_driver.h
    test/
      my_sensor_driver_test.cpp
```

### Step 2: Implement Hardware Abstraction

**File:** `src/my_sensor_driver.h`

```cpp
namespace vas::drivers {

class MySensorDriver {
 public:
  MySensorDriver(const std::string& device_path);

  // Lifecycle
  bool start();
  void stop();
  bool is_running() const;

  // Publishing (called from application)
  void poll_and_publish();

  // Error handling
  void set_health_publisher(HealthPublisher* publisher);

 private:
  std::string device_path_;
  HardwareHandle hardware_;
  HealthPublisher* health_pub_ = nullptr;

  ParsedData read_latest_();
  void handle_error_(ErrorCode code);
};

}  // namespace
```

### Step 3: Wire into VAS Application

Typically done by the **application factory** (see `stacks/pose-stack/localiser/src/main.cpp`):

```cpp
// In localiser main:
auto driver = std::make_unique<MySensorDriver>(config.device_path);
if (!driver->start()) {
  LOG_ERROR("Failed to start my_sensor_driver");
  return EXIT_FAILURE;
}

// Attach to RTI DDS
auto health_pub = dds_factory.create_health_publisher();
driver->set_health_publisher(health_pub.get());

// Main loop
while (running) {
  driver->poll_and_publish();
  // ... other processing ...
  std::this_thread::sleep_for(20ms);
}

driver->stop();
```

### Step 4: Add to CMakeLists.txt

**File:** `CMakeLists.txt`

```cmake
project(my-sensor-driver)

# Declare the library target
add_library(${PROJECT_NAME}
  src/my_sensor_driver.cpp
)

# Link dependencies
target_link_libraries(${PROJECT_NAME}
  PRIVATE
    common_data_types::common_data_types
    rti_dds_utilities_library
    rtidds rt  # RTI Connext
    pthread
)

# (Optional) Add unit tests
if(BUILD_TESTING)
  add_executable(${PROJECT_NAME}_test test/my_sensor_driver_test.cpp)
  target_link_libraries(${PROJECT_NAME}_test
    PRIVATE ${PROJECT_NAME} gtest_main
  )
  add_test(NAME ${PROJECT_NAME}_test COMMAND ${PROJECT_NAME}_test)
endif()
```

### Step 5: Add DDS Topic Registration

**File:** `rtk_os/common.xml`

```xml
<registered_topics>
  <!-- ... existing topics ... -->
  <topic>
    <name>MySensorData</name>
    <type_name>common::sensors::MySensorData</type_name>
    <qos>RELIABLE</qos>
  </topic>
</registered_topics>
```

### Step 6: Unit Testing

**File:** `test/my_sensor_driver_test.cpp`

```cpp
#include <gtest/gtest.h>
#include "my_sensor_driver.h"

class MySensorDriverTest : public ::testing::Test {
 protected:
  MockHardware mock_hw_;
  MySensorDriver driver_{"/dev/mock"};
};

TEST_F(MySensorDriverTest, PublishesDataAtCorrectRate) {
  driver_.set_health_publisher(&mock_health_pub_);
  EXPECT_TRUE(driver_.start());

  EXPECT_CALL(mock_hw_, read).Times(50).WillRepeatedly(
    Return(SensorData{.timestamp_us = now_us(), .value = 1.5f})
  );

  for (int i = 0; i < 50; ++i) {
    driver_.poll_and_publish();
  }

  EXPECT_TRUE(driver_.is_running());
  driver_.stop();
}

TEST_F(MySensorDriverTest, ReportsErrorsAsHealthEvents) {
  MockHealthPublisher health_pub;
  driver_.set_health_publisher(&health_pub);

  EXPECT_CALL(health_pub, publish)
    .Times(1)
    .With(Event type = HealthEventType::COMPONENT_FAULT);

  mock_hw_.simulate_error(ErrorCode::COMM_TIMEOUT);
  driver_.poll_and_publish();

  EXPECT_FALSE(driver_.is_running());
}
```

## Validation Checklist

Before integrating your driver into VAS:

- [ ] Hardware initialization is exception-safe
- [ ] Graceful shutdown (SIGTERM handling)
- [ ] Exceptions caught at publish boundary (no crashes)
- [ ] Health events logged on all error paths
- [ ] Unit tests cover nominal + error cases
- [ ] Publishing rate documented + validated
- [ ] Data types match `common_data_types` IDL
- [ ] CMakeLists.txt links all dependencies
- [ ] rtk_os/*.xml updated with new topic registration
- [ ] Thread-safe (if multiple consumers)
- [ ] Memory not leaked on repeated start/stop cycles
- [ ] Latency within VAS SLA (typically <100ms)

## Common Pitfalls

### ❌ Publishing from ISR context
```cpp
void on_interrupt() {
  writer.publish(msg);  // ✗ RTI DDS not ISR-safe!
}
```

**Fix:** Use lock-free queue, publish from main thread

### ❌ Blocking on hardware I/O forever
```cpp
SensorData device.read();  // ✗ What if device is disconnected?
```

**Fix:** Add timeout, return error on timeout

### ❌ Ignoring data type compatibility
```cpp
common::sensors::IMUData msg;
msg.value = 42.0;  // ✗ What if field is renamed in common_data_types?
```

**Fix:** Use accessor functions or validate type at runtime

### ❌ Not handling DDS participant errors
```cpp
writer->publish(msg);  // ✗ What if DDS participant crashed?
```

**Fix:** Check writer status, handle WRITE_FAILED

---

**Questions?** Ask vas-expert about DDS publisher lifecycle or error handling patterns.
