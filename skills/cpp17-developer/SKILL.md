---
name: cpp17-developer
description: Use this skill when implementing or refactoring C++ application logic in this repository, especially for C++17 features, API design, and unit-test-backed changes in jerrycan/src and jerrycan/test.
---

# C++17 Developer Skill

Use this skill for source-level C++ changes.

## Workflow

1. Read target files under `jerrycan/src/`, `jerrycan/include/`, and related tests.
2. Confirm behavior expectations from existing code and tests.
3. Implement minimal C++17-compliant changes.
4. Add or update tests in `jerrycan/test/`.
5. Run local build and tests.

## Validation

* Configure: `cmake -S . -B build`
* Build: `cmake --build build -j`
* Test: `cd build && ctest --output-on-failure`

## References

* For repo-specific coding and testing expectations, read `references/cpp17-developer.md`.
