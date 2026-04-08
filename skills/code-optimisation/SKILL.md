---
name: code-optimisation
description: >
  Use this skill when reviewing code for optimisation opportunities.
  It provides a structured, checklist-driven workflow for identifying
  performance, memory, I/O, CPU, and structural improvements across any
  language (C++, C#, Python, JavaScript, Java, Go, Rust, etc.).
  Use when asked to "optimise", "find performance issues",
  "reduce memory usage", "improve efficiency", "refactor for performance",
  "find redundant code", or "review for optimisation".
---

# Code Optimisation Reviewer

## When to Use

- Reviewing code for performance and efficiency improvements.
- Identifying redundant, duplicated, or monolithic code that should be
  refactored.
- Identifying unused code that should be removed.
- Auditing memory usage, I/O patterns, CPU usage, and algorithmic choices.
- Pre-merge reviews with a focus on runtime efficiency and resource
  consumption.
- Post-profiling analysis to validate that hotspots are addressed.

## Prerequisites

- Ensure the code compiles/runs and all tests pass **before** starting the
  review.
- Identify the implementation language(s) under review — checklist items
  apply universally, but language-idiomatic suggestions should be tailored
  to the specific language.

## Review Workflow

1. **Scope** – Identify the files or diff under review.
2. **Build & Test** – Confirm the code compiles/runs cleanly and tests pass.
3. **Checklist Pass** – Walk through each section below, annotating findings.
4. **Classify** – Assign an impact to each finding (High / Medium / Low /
   Informational).
5. **Report** – Present findings grouped by impact, linking to file and line.

---

## Checklist

### 1. Code Duplication & Reuse

| # | Check | Details |
|---|-------|---------|
| 1.1 | **Repeated logic** | Identify blocks of identical or near-identical code that appear in multiple locations. These should be extracted into shared utility functions, methods, or classes. |
| 1.2 | **Copy-paste variations** | Look for duplicated blocks that differ only in a parameter, constant, or type. These are candidates for parameterised functions, generics/templates, or configuration-driven approaches. |
| 1.3 | **Reimplemented standard functionality** | Flag hand-rolled implementations of operations already provided by the language's standard library or well-established frameworks (e.g., custom sorting, string manipulation, collection filtering). |
| 1.4 | **Cross-cutting concerns** | Identify duplicated cross-cutting logic (logging, validation, error handling, retry logic) that should be consolidated into shared middleware, decorators, base classes, or aspect-oriented patterns. |

### 2. Modularity & Structure

| # | Check | Details |
|---|-------|---------|
| 2.1 | **Monolithic functions/methods** | Flag functions that perform multiple unrelated tasks. Each function should have a single, well-defined responsibility. As a guideline, consider splitting functions exceeding ~60 lines or containing more than 2–3 distinct logical phases. |
| 2.2 | **Monolithic classes/modules** | Identify classes or modules that aggregate unrelated functionality. These should be decomposed into cohesive units grouped by related responsibility. |
| 2.3 | **God objects / mega-files** | Flag files that have grown to contain disparate concerns. Each file should have a clear, focused purpose. |
| 2.4 | **Deep nesting** | Identify deeply nested control flow (>3 levels). Refactoring via early returns, guard clauses, or extraction into helper functions improves readability and often reveals optimisation opportunities. |
| 2.5 | **Layering violations** | Look for code that bypasses established architectural layers (e.g., UI code directly accessing the database, business logic embedded in presentation). Proper layering enables targeted optimisation of individual tiers. |

### 3. Memory Usage

| # | Check | Details |
|---|-------|---------|
| 3.1 | **Redundant copies** | Identify unnecessary copies of objects, strings, arrays, or collections. Prefer pass-by-reference (or equivalent), move semantics, borrows, or slices where ownership transfer is not required. |
| 3.2 | **Unnecessary data retention** | Flag storage of data that is computed once and never read again, or intermediate results held beyond their useful lifetime. Release references/memory as soon as data is no longer needed. |
| 3.3 | **Pre-allocation** | When the size of a collection, string, or buffer is known or estimable ahead of time, pre-allocate to avoid repeated resizing and reallocation (e.g., `reserve()` in C++, `StringBuilder` capacity in Java/C#, pre-sized lists in Python). |
| 3.4 | **String building in loops** | Identify string concatenation inside loops. Use language-appropriate builders or join patterns (`StringBuilder`, `std::ostringstream`, `''.join()`, template literals, `fmt::format`, etc.). |
| 3.5 | **Large temporaries** | Flag creation of large temporary objects (collections, buffers, strings) that could be avoided by streaming, lazy evaluation, generators, or in-place transformation. |
| 3.6 | **Container choice** | Verify the data structure matches the access pattern. E.g., using a list for frequent random access, using a map when a set suffices, using a sorted container when insertion order is needed. |
| 3.7 | **Object pooling / caching** | For frequently created and destroyed objects of the same type (especially in hot loops), consider object pooling or reuse rather than repeated allocation/deallocation. |

### 4. Disk & Network I/O

| # | Check | Details |
|---|-------|---------|
| 4.1 | **Unnecessary I/O** | Identify reads or writes that are performed more often than necessary. Cache file contents, configuration, or query results rather than re-reading on every access. |
| 4.2 | **Unbuffered I/O** | Flag byte-at-a-time or line-at-a-time I/O where a buffered or bulk read/write would be more efficient. |
| 4.3 | **Chatty network calls** | Identify patterns where multiple small requests could be batched into fewer, larger requests (e.g., N+1 query patterns, per-item API calls inside loops). |
| 4.4 | **Synchronous I/O on hot paths** | Flag blocking I/O on performance-critical paths where asynchronous or non-blocking alternatives exist. |
| 4.5 | **Redundant serialisation** | Look for repeated serialisation/deserialisation of the same data. Cache the serialised or deserialised form as appropriate. |
| 4.6 | **File handle management** | Ensure files, streams, and connections are opened late, closed early, and not held open across long operations unnecessarily. |

### 5. CPU Usage

| # | Check | Details |
|---|-------|---------|
| 5.1 | **Redundant computation in loops** | Identify values that are recomputed on every iteration but do not change. Hoist invariant calculations out of the loop. |
| 5.2 | **Repeated method calls for same result** | Flag repeated calls to the same method/function with the same arguments where the result does not change. Assign the result to a local variable and reuse it. |
| 5.3 | **Cache-unfriendly access patterns** | Identify patterns that defeat CPU cache locality: strided access over large arrays, pointer-chasing through scattered heap allocations, column-major iteration over row-major data (or vice versa). |
| 5.4 | **Expensive operations in hot paths** | Flag use of costly operations (regex compilation, reflection, dynamic dispatch, exception throwing for control flow) inside frequently executed loops where simpler alternatives exist. |
| 5.5 | **Unnecessary locking** | Identify lock acquisitions that protect more scope than necessary, or shared data that is only accessed from a single thread. Narrow lock scopes and eliminate unneeded synchronisation. |
| 5.6 | **Memoisation opportunities** | Look for pure functions with expensive computation called repeatedly with the same inputs. These are candidates for memoisation or lookup tables. |
| 5.7 | **Lazy vs eager evaluation** | Flag eagerly computed values that may never be used. Consider lazy evaluation, short-circuit logic, or deferred initialisation. |

### 6. Algorithmic & Processing Efficiency

| # | Check | Details |
|---|-------|---------|
| 6.1 | **Algorithmic complexity** | Verify that algorithms scale appropriately. Flag O(n²) or worse when O(n log n) or O(n) alternatives exist for the expected data sizes. |
| 6.2 | **Unnecessary sorting** | Identify sorts that are followed by operations that don't require sorted order, or repeated sorts of the same data. Consider partial sorts, nth-element, or maintaining sorted order on insertion. |
| 6.3 | **Premature optimisation vs clarity** | Flag micro-optimisations that harm readability without measured or demonstrable benefit. **Prefer clarity over cleverness** unless the performance improvement is significant and the code path is frequently executed. |
| 6.4 | **Parallelisation opportunities** | Identify embarrassingly parallel operations (independent iterations, map/filter/reduce over large collections) where language-appropriate parallel constructs could be applied (parallel streams, `std::execution::par`, `Parallel.ForEach`, multiprocessing, async/await). |
| 6.5 | **Short-circuit evaluation** | Flag conditions where the cheapest or most-likely-to-fail check is not evaluated first. Place the fastest predicate or the one most likely to short-circuit at the front. |
| 6.6 | **Batch processing** | Identify item-by-item processing that could be converted to batch operations for better throughput (bulk inserts, batch API calls, vectorised operations). |

### 7. Language-Idiomatic Improvements

| # | Check | Details |
|---|-------|---------|
| 7.1 | **Idiomatic constructs** | Identify patterns that could be expressed more naturally using language-specific idioms, built-ins, or standard library features. Examples: list comprehensions (Python), LINQ (C#), streams (Java), range-based for (C++), destructuring (JS/TS), pattern matching (Rust/C#/Python). |
| 7.2 | **Modern language features** | Flag use of deprecated or legacy patterns when a modern equivalent is available and improves both clarity and efficiency (e.g., raw loops vs algorithms, `var`/`auto` type inference, async/await vs callback chains). |
| 7.3 | **Type system leverage** | Identify cases where stronger typing, generics/templates, enums, or sum types could replace stringly-typed or weakly-typed approaches, enabling compile-time/static checking and potentially better codegen. |
| 7.4 | **Built-in optimisations** | Flag cases where the language runtime or compiler can optimise better if code is structured differently (e.g., enabling RVO/NRVO in C++, using `const`/`readonly`/`final` to enable inlining, avoiding boxing in Java/C#). |

---

## Impact Classification

| Impact | Meaning |
|--------|---------|
| **High** | Measurable performance degradation, excessive resource consumption, or algorithmic scaling problem. Address before merge. |
| **Medium** | Suboptimal pattern with moderate impact. Should fix before merge if practical, otherwise track for follow-up. |
| **Low** | Minor inefficiency or style preference. Fix when convenient; no measurable runtime impact expected. |
| **Informational** | Suggestion for future improvement. No current defect. Optional. |

### Guiding Principles

- **Measure before micro-optimising.** Unless an inefficiency is obvious
  or algorithmic, recommend profiling before investing in complex
  optimisations.
- **Favour clarity over cleverness.** An optimisation that makes code
  significantly harder to understand is only justified if it's on a
  demonstrated hot path and provides substantial improvement.
- **Consider the common case.** Focus optimisation effort on code paths
  that execute frequently during normal runtime, not one-time startup or
  teardown logic.
- **Respect language idioms.** The "optimal" approach differs by language.
  A recommendation must be idiomatic for the target language, not a
  transliteration from another language's best practice.

---

## Report Template

```
## Optimisation Review Summary

**Scope**: <files/areas reviewed>
**Language(s)**: <language(s) under review>
**Build/Tests**: PASS / FAIL

### High Impact

| File:Line | Check | Description | Estimated Benefit |
|-----------|-------|-------------|-------------------|
| ...       | ...   | ...         | ...               |

### Medium Impact

| File:Line | Check | Description | Estimated Benefit |
|-----------|-------|-------------|-------------------|
| ...       | ...   | ...         | ...               |

### Low Impact

| File:Line | Check | Description | Estimated Benefit |
|-----------|-------|-------------|-------------------|
| ...       | ...   | ...         | ...               |

### Informational

| File:Line | Check | Description |
|-----------|-------|-------------|
| ...       | ...   | ...         |
```
