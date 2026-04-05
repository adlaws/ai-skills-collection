---
name: cpp17-code-reviewer
description: >
  Use this skill when performing a code review of source files in this
  repository.  It provides a structured, checklist-driven review workflow
  that is mostly language-agnostic (correctness, security, maintainability,
  performance) with additional C++-specific review points for memory safety,
  resource management, undefined behaviour, and modern idiom usage.
---

# C++ Code Reviewer

## When to Use

- Reviewing pull requests or diffs.
- Auditing an existing codebase for defects, security gaps, or maintainability
  issues.
- Pre-merge quality gates where a structured checklist is needed.
- Post-refactor validation to ensure no regressions were introduced.

## Prerequisites

- Read and understand the project-specific coding guidelines in
  `.agents/skills/cpp17-developer/references/cpp17-guidelines.md`.
- Ensure the code compiles and all tests pass **before** starting the review:
  ```bash
  cmake -S . -B build -DBUILD_TESTING=ON
  cmake --build build -j
  ctest --test-dir build --output-on-failure
  ```

## Review Workflow

1. **Scope** – Identify the files or diff under review.
2. **Build & Test** – Confirm the code compiles cleanly and tests pass.
3. **Checklist Pass** – Walk through each section below, annotating findings.
4. **Classify** – Assign a severity to each finding (Critical / Major / Minor /
   Informational).
5. **Report** – Present findings grouped by severity, linking to file and line.

---

## Part A — Language-Agnostic Review Checklist

These principles apply to any imperative/OOP language.

### A1. Correctness

| # | Check | Details |
|---|-------|---------|
| A1.1 | **Logic errors** | Off-by-one, inverted conditions, short-circuit evaluation misuse, unreachable code. |
| A1.2 | **Boundary / edge cases** | Empty inputs, zero-length containers, maximum-value integers, null/optional values. |
| A1.3 | **Error handling** | Every fallible operation must have an error path; errors must not be silently swallowed. |
| A1.4 | **Return values** | Functions annotated `[[nodiscard]]` (or equivalent) must have their return values used. Ensure newly added functions that return success/failure or computed values are annotated. |
| A1.5 | **Preconditions / postconditions** | Verify callers satisfy documented preconditions; ensure functions deliver promised postconditions. |
| A1.6 | **Arithmetic** | Integer overflow/underflow, division by zero, signed/unsigned mismatch, narrowing conversions. |

### A2. Security & Input Validation

| # | Check | Details |
|---|-------|---------|
| A2.1 | **Input validation** | All external input (files, network, CLI args, environment variables) must be validated before use. |
| A2.2 | **Bounds checking** | Array/container accesses with dynamic indices must be range-checked or use safe accessors (`.at()`, range-for, iterators). |
| A2.3 | **Injection / format strings** | User-supplied data must never flow directly into format strings, SQL, shell commands, or log format specifiers. |
| A2.4 | **Sensitive data** | Passwords, keys, tokens must not be logged or stored in plain text. Ensure buffers holding secrets are cleared after use. |
| A2.5 | **Path traversal** | File-path inputs must be canonicalised and restricted to an expected directory. |

### A3. Maintainability & Readability

| # | Check | Details |
|---|-------|---------|
| A3.1 | **Naming** | Variables, functions, types, and constants follow project naming conventions (see `cpp17-guidelines.md`). Names are descriptive without being excessively long. |
| A3.2 | **Function length** | Prefer short, single-responsibility functions. Flag functions exceeding ~60 lines for possible extraction. |
| A3.3 | **Cognitive complexity** | Deeply nested control flow (>3 levels) warrants refactoring. |
| A3.4 | **Code duplication** | Identical or near-identical blocks should be extracted into shared utilities. |
| A3.5 | **Comments & docs** | Public API functions must have `@brief`, `@param`, `@return`, `@throws` Doxygen documentation. Inline comments explain *why*, not *what*. |
| A3.6 | **Magic values** | Literal numbers/strings should be replaced with named constants. |
| A3.7 | **Dead code** | Unreachable branches, unused variables, commented-out code should be removed. |
| A3.8 | **Consistent style** | Braces, spacing, indentation follow the project style (K&R-derived). |

### A4. Testing

| # | Check | Details |
|---|-------|---------|
| A4.1 | **Test coverage** | New/changed behaviour must have corresponding unit tests. |
| A4.2 | **Edge-case tests** | Tests cover empty, boundary, and error cases, not just the happy path. |
| A4.3 | **Test independence** | Tests must not depend on execution order or shared mutable state. |
| A4.4 | **Assertion quality** | Tests should use specific assertions (`EXPECT_EQ`, `EXPECT_THROW`, etc.) rather than generic `EXPECT_TRUE` where a more precise assertion exists. |

### A5. Performance (General)

| # | Check | Details |
|---|-------|---------|
| A5.1 | **Algorithmic complexity** | Verify that algorithms scale appropriately for expected data sizes. Flag O(n²) or worse when a better alternative exists. |
| A5.2 | **Unnecessary allocation** | Avoid allocating in hot loops or when stack allocation suffices. |
| A5.3 | **Unnecessary copies** | Pass large objects by `const` reference rather than by value when the function does not need ownership. |
| A5.4 | **Premature optimisation** | Flag micro-optimisations that harm readability without measured justification. |

---

## Part B — C++-Specific Review Checklist

These checks layer on top of Part A for C++ code.

### B1. Memory Safety & Resource Management

| # | Check | Details |
|---|-------|---------|
| B1.1 | **RAII everywhere** | Every resource (memory, file handle, mutex, socket) must be managed by a RAII wrapper. No manual `new`/`delete`, `malloc`/`free`, `fopen`/`fclose` outside resource-handle implementations. (CppCoreGuidelines R.1, R.11, P.8) |
| B1.2 | **Smart pointers** | Use `std::unique_ptr` by default; `std::shared_ptr` only when shared ownership is genuinely needed. Construct via `std::make_unique` / `std::make_shared`. (R.20–R.23) |
| B1.3 | **Dangling references** | Returning references/pointers to locals, temporaries, or invalidated iterators. |
| B1.4 | **Ownership clarity** | Raw `T*` must be non-owning. If ownership transfer is intended, use `std::unique_ptr`. (R.3) |
| B1.5 | **Rule of Zero / Five** | Prefer Rule of Zero (rely on RAII members). If any special member is defined or deleted, all five must be addressed. (C.20, C.21) |

### B2. Undefined Behaviour

| # | Check | Details |
|---|-------|---------|
| B2.1 | **Uninitialised variables** | All variables must be initialised at declaration. Use `{}` for value-initialisation. (ES.20) |
| B2.2 | **Null-pointer dereference** | Pointers must be validated before dereference, or passed as references / `not_null<T*>`. |
| B2.3 | **Use-after-move** | Objects must not be read after being moved-from, except to assign or destroy. |
| B2.4 | **Iterator invalidation** | Verify that iterators, references, or pointers into containers are not used after operations that may invalidate them (`push_back`, `erase`, `insert`, `clear`). |
| B2.5 | **Signed integer overflow** | Signed overflow is UB in C++. Check arithmetic on `int`/`long`. Use unsigned only for bit manipulation (ES.101–ES.106). |
| B2.6 | **Evaluation order** | Don't depend on order of evaluation of function arguments or unsequenced side effects within a single expression. (ES.43, ES.44) |
| B2.7 | **Strict aliasing** | Don't access an object through a pointer of incompatible type. Avoid `reinterpret_cast` unless absolutely necessary. |
| B2.8 | **Type punning via union** | Use `std::variant` instead of naked unions. Never read from an inactive union member. (C.181) |

### B3. Modern C++17 Idioms

| # | Check | Details |
|---|-------|---------|
| B3.1 | **`const` / `constexpr`** | Use `const` for values that don't change. Use `constexpr` for compile-time-computable values. (Con.4, Con.5, F.4) |
| B3.2 | **`[[nodiscard]]`** | Apply to functions whose return value must not be ignored (error codes, computed results, factory functions). |
| B3.3 | **`std::string_view`** | Use for read-only string parameters instead of `const std::string&` when no ownership is needed. |
| B3.4 | **`std::optional`** | Prefer `std::optional<T>` over sentinel values, `T*`, or out-parameters for "may not have a value" semantics. |
| B3.5 | **Structured bindings** | Use `auto [key, value] = ...` for readability when decomposing pairs, tuples, or structs. |
| B3.6 | **`if constexpr`** | Prefer over tag dispatch / SFINAE when branching on compile-time conditions. |
| B3.7 | **Range-based `for`** | Prefer `for (const auto& x : container)` over index-based loops unless the index is needed. (ES.55, P.3) |
| B3.8 | **`auto`** | Use `auto` when the type is obvious from the initialiser. Avoid `auto` when the type is important for understanding. |
| B3.9 | **`noexcept`** | Mark move constructors, move-assignment operators, swap, and destructors `noexcept`. (F.6, C.66, C.37, C.85) |

### B4. Concurrency (if applicable)

| # | Check | Details |
|---|-------|---------|
| B4.1 | **Data races** | Any data shared between threads must be protected by a mutex or be `std::atomic`. (CP.2) |
| B4.2 | **Lock scope** | Use `std::lock_guard` or `std::unique_lock` with RAII; never manually call `lock()`/`unlock()`. (CP.44) |
| B4.3 | **Deadlocks** | Acquire multiple locks in a consistent order, or use `std::scoped_lock`. |
| B4.4 | **`volatile` misuse** | `volatile` is not a synchronisation primitive; use `std::atomic` instead. (CP.200) |
| B4.5 | **Thread-local storage** | Prefer passing state through parameters over using mutable global/static data. (CP.3) |

### B5. C++ API Design

| # | Check | Details |
|---|-------|---------|
| B5.1 | **Parameter passing** | Follow the CppCoreGuidelines flowchart: cheap-to-copy → by value; read-only → `const&`; sink → by value + move; in/out → `T&`. (F.15–F.17) |
| B5.2 | **Encapsulation** | Class invariants enforced; data members `private` (structs excepted). `protected` data discouraged. (C.9, NR.7) |
| B5.3 | **Implicit conversions** | Single-argument constructors should be `explicit` unless implicit conversion is intentionally designed. |
| B5.4 | **Virtual destructor** | Polymorphic base classes must have a `public virtual` or `protected non-virtual` destructor. (C.35) |
| B5.5 | **Slicing** | Passing derived objects by value to a base parameter slices. Pass by reference or pointer. (ES.63) |
| B5.6 | **Header hygiene** | Include only what is used. Prefer forward declarations where possible. Use `#pragma once` or include guards. (SF.8–SF.10) |

---

## Severity Classification

| Severity | Meaning |
|----------|---------|
| **Critical** | Undefined behaviour, data loss, security vulnerability, crash. Must fix before merge. |
| **Major** | Resource leak, logic error, missing error handling, missing tests. Should fix before merge. |
| **Minor** | Style violation, suboptimal idiom, missing `const`, naming inconsistency. Fix when convenient. |
| **Informational** | Suggestion for improvement; no defect. Optional. |

---

## Report Template

```
## Code Review Summary

**Scope**: <files/areas reviewed>
**Build**: PASS / FAIL
**Tests**: <n> passed, <m> failed

### Critical

| File:Line | Check | Description |
|-----------|-------|-------------|
| ...       | ...   | ...         |

### Major

| File:Line | Check | Description |
|-----------|-------|-------------|
| ...       | ...   | ...         |

### Minor

| File:Line | Check | Description |
|-----------|-------|-------------|
| ...       | ...   | ...         |

### Informational

| File:Line | Check | Description |
|-----------|-------|-------------|
| ...       | ...   | ...         |
```

## References

- [ISO C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)
  (P, I, F, C, R, ES, Per, CP, E, Con, T, SF, SL sections)
- [SEI CERT C++ Coding Standard](https://wiki.sei.cmu.edu/confluence/display/cplusplus)
  (DCL, EXP, INT, CTR, STR, MEM, FIO, ERR, OOP, CON, MSC rules)
- [OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
- Project guidelines: `.agents/skills/cpp17-developer/references/cpp17-guidelines.md`
