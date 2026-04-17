#!/bin/bash
# templates/add_new_stack.sh
# Template for scaffolding a new VAS stack (e.g., notification processor, health manager)

# Usage: bash add_new_stack.sh MyFeatureStack

if [ -z "$1" ]; then
  echo "Usage: bash add_new_stack.sh <StackName>"
  echo "Example: bash add_new_stack.sh CustomProcessor"
  exit 1
fi

STACK_NAME="$1"
STACK_DIR_NAME=$(echo "$STACK_NAME" | sed 's/[A-Z]/-\L&/g' | sed 's/^-//')  # kebab-case
STACK_PATH="stacks/${STACK_DIR_NAME}-stack"

echo "Creating new stack: $STACK_NAME"
echo "Directory: $STACK_PATH"

mkdir -p "$STACK_PATH/src"
mkdir -p "$STACK_PATH/test"

# CMakeLists.txt
cat > "$STACK_PATH/CMakeLists.txt" << 'EOF'
project(@STACK_DIR_NAME@-stack)

## Library target
add_library(${PROJECT_NAME}
  src/@STACK_SNAKE@.cpp
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

## Executable (if stack runs as standalone process)
add_executable(${PROJECT_NAME}_app src/main.cpp)
target_link_libraries(${PROJECT_NAME}_app
  PRIVATE ${PROJECT_NAME}
)

## Tests
if(BUILD_TESTING)
  add_executable(${PROJECT_NAME}_test test/@STACK_SNAKE@_test.cpp)
  target_link_libraries(${PROJECT_NAME}_test
    PRIVATE ${PROJECT_NAME} gtest_main
  )
  add_test(NAME ${PROJECT_NAME}_test COMMAND ${PROJECT_NAME}_test)
endif()
EOF

# Header
mkdir -p "$STACK_PATH/include"
cat > "$STACK_PATH/include/${STACK_DIR_NAME}_stack.h" << 'EOF'
#pragma once

#include <memory>
#include <thread>
#include <atomic>
#include <deque>
#include <mutex>

namespace vas::stacks {

/**
 * @brief Brief description of what this stack does
 *
 * This stack subscribes to:
 * - /input_topic_1 (InputDataType1)
 * - /input_topic_2 (InputDataType2)
 *
 * And publishes to:
 * - /output_topic (OutputDataType)
 * - /health_event (if errors occur)
 */
class @STACK_NAME@Stack {
 public:
  @STACK_NAME@Stack();
  ~@STACK_NAME@Stack();

  // Lifecycle
  bool initialize(const std::string& config_file);
  bool start();
  void stop();
  bool is_running() const { return running_; }

  // Step processing (if running as library, call periodically)
  void step();

  // Event processing (called by DDS when data arrives)
  void on_input_message_1(const std::shared_ptr<const InputType1>& msg);
  void on_input_message_2(const std::shared_ptr<const InputType2>& msg);

  // Disabled copy/move
  @STACK_NAME@Stack(const @STACK_NAME@Stack&) = delete;
  @STACK_NAME@Stack& operator=(const @STACK_NAME@Stack&) = delete;

 private:
  std::atomic<bool> running_{false};

  // Configuration
  struct Config {
    // TODO: add stack-specific settings
  } config_;

  // Message queues
  std::deque<std::shared_ptr<const InputType1>> input_queue_1_;
  std::deque<std::shared_ptr<const InputType2>> input_queue_2_;
  std::mutex queue_mutex_;

  // DDS writers
  // Placeholder—implement in .cpp
  void initialize_dds_();
  void process_messages_();
  void publish_output_(const OutputType& msg);
  void publish_health_error_(const std::string& reason);
};

}  // namespace
EOF

# Implementation stub
cat > "$STACK_PATH/src/${STACK_DIR_NAME}_stack.cpp" << 'EOF'
#include "@STACK_DIR_NAME@_stack.h"

#include <iostream>

namespace vas::stacks {

@STACK_NAME@Stack::@STACK_NAME@Stack() = default;

@STACK_NAME@Stack::~@STACK_NAME@Stack() {
  if (running_) {
    stop();
  }
}

bool @STACK_NAME@Stack::initialize(const std::string& config_file) {
  try {
    // TODO: Parse config_file (XML or JSON)
    // TODO: Set up DDS subscribers and publishers
    initialize_dds_();
    return true;
  } catch (const std::exception& e) {
    std::cerr << "Failed to initialize @STACK_NAME@Stack: " << e.what() << std::endl;
    return false;
  }
}

bool @STACK_NAME@Stack::start() {
  running_ = true;
  // TODO: Start processing thread if needed
  return true;
}

void @STACK_NAME@Stack::stop() {
  running_ = false;
  // TODO: Wait for threads to complete
}

void @STACK_NAME@Stack::step() {
  if (!running_) return;

  // Lock queue and process accumulated messages
  {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    process_messages_();
  }
}

void @STACK_NAME@Stack::on_input_message_1(
    const std::shared_ptr<const InputType1>& msg) {
  std::lock_guard<std::mutex> lock(queue_mutex_);
  input_queue_1_.push_back(msg);
}

void @STACK_NAME@Stack::on_input_message_2(
    const std::shared_ptr<const InputType2>& msg) {
  std::lock_guard<std::mutex> lock(queue_mutex_);
  input_queue_2_.push_back(msg);
}

void @STACK_NAME@Stack::process_messages_() {
  // TODO: Process queued messages
  // TODO: Compute output
  // TODO: Publish via publish_output_()
}

void @STACK_NAME@Stack::publish_output_(const OutputType& msg) {
  // TODO: Use DDS writer to publish message to /output_topic
}

void @STACK_NAME@Stack::publish_health_error_(const std::string& reason) {
  // TODO: Create HealthJustification event
  // TODO: Publish to /health_event
}

void @STACK_NAME@Stack::initialize_dds_() {
  // TODO: Create DDS participant / subscriber / writer
  //  - Subscribe to /input_topic_1 and /input_topic_2
  //  - Attach callbacks to on_input_message_N
  //  - Create writer for /output_topic
}

}  // namespace
EOF

# Main application (if stack runs standalone)
cat > "$STACK_PATH/src/main.cpp" << 'EOF'
#include "@STACK_DIR_NAME@_stack.h"

#include <iostream>
#include <signal.h>
#include <thread>
#include <chrono>

using namespace vas::stacks;

static volatile bool g_running = true;

void signal_handler(int signal) {
  g_running = false;
}

int main(int argc, char* argv[]) {
  signal(SIGTERM, signal_handler);
  signal(SIGINT, signal_handler);

  // TODO: Parse command line arguments for config file
  std::string config_file = (argc > 1) ? argv[1] : "/etc/vas/@STACK_DIR_NAME@_config.xml";

  @STACK_NAME@Stack stack;
  if (!stack.initialize(config_file)) {
    std::cerr << "Failed to initialize stack" << std::endl;
    return 1;
  }

  if (!stack.start()) {
    std::cerr << "Failed to start stack" << std::endl;
    return 1;
  }

  std::cout << "@STACK_NAME@ stack running..." << std::endl;

  // Main processing loop
  while (g_running) {
    stack.step();
    std::this_thread::sleep_for(std::chrono::milliseconds(50));  // 20 Hz
  }

  stack.stop();
  std::cout << "@STACK_NAME@ stack stopped" << std::endl;

  return 0;
}
EOF

# Test stub
cat > "$STACK_PATH/test/${STACK_DIR_NAME}_stack_test.cpp" << 'EOF'
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "@STACK_DIR_NAME@_stack.h"

namespace vas::stacks {

class @STACK_NAME@StackTest : public ::testing::Test {
 protected:
  std::unique_ptr<@STACK_NAME@Stack> stack_;

  void SetUp() override {
    stack_ = std::make_unique<@STACK_NAME@Stack>();
  }
};

TEST_F(@STACK_NAME@StackTest, InitializesWithValidConfig) {
  // TODO: Use a test config file
  EXPECT_TRUE(stack_->initialize("test_data/@STACK_DIR_NAME@_config.xml"));
}

TEST_F(@STACK_NAME@StackTest, StartsAndStops) {
  stack_->initialize("test_data/@STACK_DIR_NAME@_config.xml");
  EXPECT_TRUE(stack_->start());
  EXPECT_TRUE(stack_->is_running());
  stack_->stop();
  EXPECT_FALSE(stack_->is_running());
}

TEST_F(@STACK_NAME@StackTest, ProcessesInputMessages) {
  stack_->initialize("test_data/@STACK_DIR_NAME@_config.xml");
  stack_->start();

  // TODO: Create mock InputType1 message
  // auto msg = std::make_shared<InputType1>();
  // msg->value = 42;
  // stack_->on_input_message_1(msg);
  // stack_->step();

  // TODO: Verify output was generated

  stack_->stop();
}

}  // namespace
EOF

echo ""
echo "✓ Stack skeleton created at: $STACK_PATH"
echo ""
echo "Next steps:"
echo "1. Review CMakeLists.txt and replace @STACK_DIR_NAME@ and @STACK_SNAKE@ markers"
echo "2. Implement the stack logic in .h and .cpp"
echo "3. Define input/output data types (link to common_data_types)"
echo "4. Write comprehensive tests in test/ directory"
echo "5. Create config file (XML or JSON)"
echo "6. Add to main CMakeLists.txt: add_subdirectory(stacks/${STACK_DIR_NAME}-stack)"
echo "7. Build and test:"
echo "   cmake -B build ."
echo "   ctest -R \"${STACK_DIR_NAME}.*test\" -V"
