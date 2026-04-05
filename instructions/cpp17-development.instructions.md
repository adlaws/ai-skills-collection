---
applyTo: 'jerrycan/src/**/*.cpp,jerrycan/src/**/*.hpp,jerrycan/include/**/*.hpp,jerrycan/test/**/*.cpp'
description: 'C++17 implementation standards for JerryCAN: style, correctness, testing, and maintainability guidance for AI code generation and refactoring.'
---

# C++17 Development Guidelines

## Mission

Implement or refactor C++ code that is safe, testable, readable and maintainable while using C++17
features intentionally.

## Rules

* Target C++17-compatible implementations only.
* Prefer `constexpr`, `enum class`, and strong types over macros and implicit conversions.
* Prefer standard library containers and algorithms over custom utility code unless justified.
* Use `std::optional` for nullable return values instead of sentinel values.
* Use `std::variant` for tagged unions and explicit state models.
* Keep code AUTOSAR compliant.
* Keep function signatures const-correct and explicit.
* Avoid hidden ownership transfer; use `std::unique_ptr` by default when heap ownership is required.
* Use smart pointers (`std::unique_ptr`, `std::shared_ptr`) instead of raw pointers.
* Use `PascalCase` for classes.
* Use `camelCase` for method and function names; avoid `snake_case` for callable identifiers.
* Use `snake_case` for variable names, and `snake_case_` for member variable names.
* Use `UPPER_SNAKE_CASE` for constants.
* Provide inline commenting where necessary for clarity and maintainability.
* Do not hardcode user-facing UI labels/messages; store them in localization resource files and resolve them through the localization layer.
* Any language-selection UI must be driven from discovered localization resources, not a hardcoded list.

## Architecture Guidelines
* Avoid tight coupling between modules; prefer clear interfaces and dependency injection.
* Keep modules focused on a single responsibility and cohesive in their functionality.
* Use interfaces and abstract base classes where approriate to define clear contracts between components.
* Avoid deep inheritance hierarchies; prefer composition over inheritance where possible.
* Refactor classes that grow large by extracting focused helper modules or reusable free functions.
* Prefer reusable abstractions over copy/paste implementations so other parts of the codebase can consume shared behaviour.
* Periodically review existing code for opportunities to separate concerns and introduce clear utility layers.
* Avoid monolithic classes when rising complexity hurts readability, testability, or maintainability.
* Prefer value semantics and immutability where possible to reduce complexity and improve safety.
* Avoid global state and singletons; prefer explicit dependency management.
* Use the MVC pattern for GUI components to separate concerns and improve testability.
* For CLI components, use a clear separation between command parsing, business logic, and output formatting.

## General Guidelines

* "Less is more". Look for opportunities to simplify code and reduce unnecessary complexity, and consider removal of code that is no longer needed or used rather than always adding more code to solve problems.
* Prefer smart solutions that are easy to understand and maintain over "clever" or overly complex code.
* Keep functions focused and concise; prefer small, single-purpose functions.
* Use meaningful variable and function names that convey intent.
* Avoid deep nesting and long functions; refactor into smaller functions or use early returns to improve readability.
* Use RAII and smart pointers to manage resources safely and avoid memory leaks.
* Avoid raw pointers and manual memory management; prefer smart pointers and standard library containers.
* Use `const` and `constexpr` to express immutability and intent where appropriate.
* prfer fixed width integer types (`std::int32_t`, `std::uint64_t`, etc.) for explicit size requirements, especially in CAN message parsing and serialization.
* Use `std::string_view` for read-only string parameters to avoid unnecessary copying.
* Use `std::filesystem` for file path manipulation and I/O operations to improve portability and safety.
* Use `std::chrono` for time-related operations to improve clarity and correctness.
* Use `std::optional` for functions that may not return a value, instead of using sentinel values or output parameters.
* Use `std::variant` for functions that may return multiple types of values, instead of using unions or ambiguous return types.
* Use `std::any` for functions that may return values of arbitrary types, but prefer more specific types when possible to improve clarity and maintainability.

## Method and Function Documentation

All methods and functions should have clear and concise documentation comments that describe their purpose,
parameters, return values, and any exceptions they may throw. Use Doxygen-style comments for consistency.

For example:

```cpp
/// @brief A short description of what the function does.
/// @note If necessary, any additional notes about the function's behaviour or usage that might be unexpected or non-obvious.
/// @tparam T information about template parameters, if applicable.
/// @param xyz a description of the parameter and its expected values or behaviour. If the parameter is a reference or pointer,
/// specify ownership and mutability semantics.
/// @return details about the return value, including its type and meaning.
/// @throws std::exception_type if certain error conditions occur, with a description of the
/// circumstances under which the exception is thrown.
```

## Error Handling

* Use explicit validation at module boundaries.
* Keep logging meaningful and structured using `spdlog` where runtime diagnostics are needed.
* Return domain-relevant errors or explicit status objects rather than ambiguous booleans.

## Testing Expectations

* Add or update tests in `jerrycan/test/` for each behavior change.
* Cover normal flow and at least one failure/edge case.
* Keep tests deterministic and independent from external systems.

## Definition of Done

* Compiles with C++17 settings from CMake.
* Unit tests pass.
* Documentation is updated if public interfaces change.
* No generated files under `build/` are edited.
