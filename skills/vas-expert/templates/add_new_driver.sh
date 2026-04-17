#!/bin/bash
# templates/add_new_driver.sh
# Template for scaffolding a new VAS driver

# Usage: bash add_new_driver.sh MyNewSensor

if [ -z "$1" ]; then
  echo "Usage: bash add_new_driver.sh <DriverName>"
  echo "Example: bash add_new_driver.sh WheelSpeedSensor"
  exit 1
fi

DRIVER_NAME="$1"
DRIVER_DIR_NAME=$(echo "$DRIVER_NAME" | sed 's/[A-Z]/-\L&/g' | sed 's/^-//')  # Convert to kebab-case
DRIVER_PATH="drivers/${DRIVER_DIR_NAME}-driver"

echo "Creating new driver: $DRIVER_NAME"
echo "Directory: $DRIVER_PATH"

mkdir -p "$DRIVER_PATH/src"
mkdir -p "$DRIVER_PATH/test"

# Generate CMakeLists.txt
cat > "$DRIVER_PATH/CMakeLists.txt" << 'EOF'
project(@DRIVER_DIR_NAME@-driver)

## Library target
add_library(${PROJECT_NAME}
  src/@DRIVER_SNAKE@_driver.cpp
)

target_include_directories(${PROJECT_NAME}
  PUBLIC include
)

target_link_libraries(${PROJECT_NAME}
  PUBLIC
    common_data_types::common_data_types
    rti_dds_utilities_library
    rtidds rt
    pthread
)

## Tests
if(BUILD_TESTING)
  add_executable(${PROJECT_NAME}_test test/@DRIVER_SNAKE@_driver_test.cpp)
  target_link_libraries(${PROJECT_NAME}_test
    PRIVATE ${PROJECT_NAME} gtest_main
  )
  add_test(NAME ${PROJECT_NAME}_test COMMAND ${PROJECT_NAME}_test)
endif()
EOF

# Generate header
mkdir -p "$DRIVER_PATH/include"
cat > "$DRIVER_PATH/include/${DRIVER_DIR_NAME}_driver.h" << 'EOF'
#pragma once

#include <memory>
#include <thread>
#include <atomic>

namespace common::sensor {
// Declare your data type here (or link to common_data_types)
}

namespace vas::drivers {

class @DRIVER_NAME@Driver {
 public:
  explicit @DRIVER_NAME@Driver(const std::string& device_path);
  ~@DRIVER_NAME@Driver();

  // Lifecycle
  bool start();
  void stop();
  bool is_running() const { return running_; }

  // Publishing (call from application)
  void poll_and_publish();

  // Disabled copy/move
  @DRIVER_NAME@Driver(const @DRIVER_NAME@Driver&) = delete;
  @DRIVER_NAME@Driver& operator=(const @DRIVER_NAME@Driver&) = delete;

 private:
  std::string device_path_;
  std::atomic<bool> running_{false};

  struct HardwareHandle;
  std::unique_ptr<HardwareHandle> hw_;

  void hardware_thread_();
  void publish_health_error_(const std::string& reason);
};

}  // namespace
EOF

# Generate implementation stub
cat > "$DRIVER_PATH/src/${DRIVER_DIR_NAME}_driver.cpp" << 'EOF'
#include "@DRIVER_DIR_NAME@_driver.h"

#include <iostream>

namespace vas::drivers {

@DRIVER_NAME@Driver::@DRIVER_NAME@Driver(const std::string& device_path)
    : device_path_(device_path) {}

@DRIVER_NAME@Driver::~@DRIVER_NAME@Driver() {
  if (running_) {
    stop();
  }
}

bool @DRIVER_NAME@Driver::start() {
  // TODO: Open device, initialize hardware
  // TODO: Start hardware thread if needed
  running_ = true;
  return true;
}

void @DRIVER_NAME@Driver::stop() {
  running_ = false;
  // TODO: Gracefully close device
}

void @DRIVER_NAME@Driver::poll_and_publish() {
  if (!running_) return;

  // TODO: Read data from device
  // TODO: Parse into common data type
  // TODO: Publish via DDS writer
}

void @DRIVER_NAME@Driver::publish_health_error_(const std::string& reason) {
  // TODO: Create HealthJustification event
  // TODO: Publish to health topic
}

}  // namespace
EOF

# Generate test stub
cat > "$DRIVER_PATH/test/${DRIVER_DIR_NAME}_driver_test.cpp" << 'EOF'
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "@DRIVER_DIR_NAME@_driver.h"

namespace vas::drivers {

class @DRIVER_NAME@DriverTest : public ::testing::Test {
 protected:
  std::unique_ptr<@DRIVER_NAME@Driver> driver_;

  void SetUp() override {
    driver_ = std::make_unique<@DRIVER_NAME@Driver>("/dev/mock");
  }
};

TEST_F(@DRIVER_NAME@DriverTest, StartsSuccessfully) {
  EXPECT_TRUE(driver_->start());
  EXPECT_TRUE(driver_->is_running());
  driver_->stop();
}

TEST_F(@DRIVER_NAME@DriverTest, StopsGracefully) {
  driver_->start();
  driver_->stop();
  EXPECT_FALSE(driver_->is_running());
}

}  // namespace
EOF

echo ""
echo "✓ Driver skeleton created at: $DRIVER_PATH"
echo ""
echo "Next steps:"
echo "1. Edit CMakeLists.txt and replace @DRIVER_DIR_NAME@ and @DRIVER_SNAKE@ markers"
echo "2. Implement .h and .cpp with your hardware logic"
echo "3. Add unit tests in test/ directory"
echo "4. Link DDS writer in main application"
echo "5. Register topic in rtk_os/common.xml"
echo "6. Build and test:"
echo "   cmake -B build ."
echo "   ctest -R \"${DRIVER_DIR_NAME}.*test\" -V"
