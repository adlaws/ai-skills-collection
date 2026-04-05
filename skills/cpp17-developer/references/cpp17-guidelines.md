# C++17 Guidelines Reference

## Mission

Implement or refactor C++ code that is safe, testable, readable and maintainable while using C++17
features intentionally.

## Preferred Language Features

* Target C++17-compatible implementations only.
* Provide inline commenting where necessary for clarity and maintainability.
* Do not hardcode user-facing UI labels/messages; store them in localization resource files and resolve them through the localization layer.
* Any language-selection UI must be driven from discovered localization resources, not a hardcoded list.
* Structured bindings for tuple-like unpacking.
* `if constexpr` for compile-time branching in templates.
* `std::string_view` for non-owning read-only string parameters.
* `[[nodiscard]]` for return values that must be checked.
* Prefer `constexpr`, `enum class`, and strong types over macros and implicit conversions.
* Prefer standard library containers and algorithms over custom utility code unless justified.
* Avoid over-templating unless it materially improves correctness or reuse.
* Use `std::optional` for nullable return values instead of sentinel values.
* Use `std::variant` for tagged unions and explicit state models.
* Keep function signatures const-correct and explicit.
* Avoid raw pointers and manual memory management; Prefer clear ownership with smart pointers (`std::unique_ptr`, `std::shared_ptr` etc) and standard library containers
* Avoid hidden ownership transfer; use `std::unique_ptr` by default when heap ownership is required.
* Avoid broad catches in `try`/`catch` blocks, and prefer handling of specific exceptions instead.
* Use `const` and `constexpr` to express immutability and intent where appropriate.
* Keep function contracts explicit (`const`, `noexcept` where appropriate).
* Prefer fixed width integer types (`std::int32_t`, `std::uint64_t`, etc.) for explicit size requirements, especially
  in CAN message parsing and serialization.
* Use `std::string_view` for read-only string parameters to avoid unnecessary copying.
* Use `std::filesystem` for file path manipulation and I/O operations to improve portability and safety.
* Use `std::chrono` for time-related operations to improve clarity and correctness.
* Use `std::optional` for functions that may not return a value, instead of using sentinel values or output parameters.
* Use `std::variant` for functions that may return multiple types of values, instead of using unions or ambiguous return types.
* Use `std::any` for functions that may return values of arbitrary types, but prefer more specific types when possible to
  improve clarity and maintainability.
* Use `PascalCase` for classes.
* Use `camelCase` for method names.
* Use `snake_case` for variable names, and `snake_case_` for member variable names.
* Use `UPPER_SNAKE_CASE` for constants.

## API Design

* Keep headers small and focused.
* Minimize transitive includes; prefer forward declarations where safe.
* Return values should encode success/failure clearly.

## Testing Guidance

* Add tests for each changed behavior.
* Include at least one edge case.
* Keep fixtures simple and deterministic.

## Architecture Guidelines

* Avoid tight coupling between modules; prefer clear interfaces and dependency injection.
* Keep modules focused on a single responsibility and cohesive in their functionality.
* Use interfaces and abstract base classes where approriate to define clear contracts between components.
* Avoid deep inheritance hierarchies; prefer composition over inheritance where possible.
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

In inline comments, avoid the use of "special" characters, such as arrows and emdashes. Prefer the
use of "typeable" characters - for example an 'arrow' could be constructed from `->` or `=>` rather
than using `→`, diagonal lines should use `/` and `\`, and so on.

An exception may be made for...

* The multiplication character `×` may be used
* Box drawing characters such as `┌──┐├──┤└──┘│` and related may be used for ASCII diagrams
* Greek letters may be used where it corresponds directly to an established or wll known formula
  in maths, geometry, physics, chemistry etc and so may improve legibility.
* fractions such as `½`, `¼`, `¾` etc, though these may be hard to read at small font sizes and for
  legibility `1/2`, `1/4`, `3/4` would normally be preferred, unless the use of the fraction
  contributes to the meaning of the
* `²` and `³` may also be used, but these may be also hard to read at small font sizes and for
  legibility the `^2` and `^3` notation would normally be preferred unless the use of the squared
  or cubed character contributes the meaning of the comment.

## File Documentation and Copyright Notice

All files must have a copyright notice as the first line.

The copyright notice format for newly created files is as follows:

```cpp
// Copyright 2026 Fortescue Ltd. All rights reserved.
```

...where the current year must be subtituted for `2026`.

If a file with an existing copyright notice is modified, and the current year is after the
existing year, the format of the cpoyright notice changes to:

```cpp
// Copyright 2026 - 2027 Fortescue Ltd. All rights reserved.
```

...where `2026` is the creation year and `2027` is the most recent year the file was modified.

All files must have an `@brief` comment at the top of the file (following the copyright notice).

```cpp
/// @brief A general description that talks about the purpose and intent of
/// the source code contained in this file, and any external references that
/// may serve to help understand any advanced approaches or algorithms used,
/// particularly aimed at benefiting newcomers to the codebase who are familiar
/// with C++ in general, but perhaps not this specific project.
```

The `@file` documentation is *not* required, as the file name is self evident.

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
* Appropriate unit tests are present, build successfully, and pass.
* Documentation in code (methods, functions, classes, and file copyright etc) is updated to track
  with any changes made.
* User facing documentation is updated to track with changes, particularly if public interfaces change.
* No generated files under `build/` are edited.
