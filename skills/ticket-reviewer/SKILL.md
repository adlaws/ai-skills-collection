````skill
---
name: ticket-reviewer
description: 'Review and sanity-check a planned work ticket before implementation. Use when asked to "review a ticket", "check the plan", "sanity check the ticket", "validate the design", "review before implementation", or when verifying that a ticket planned by ticket-planner is logical, complete, and ready for ticket-worker to execute. Checks for missing test coverage, documentation gaps, resource/performance impacts, and breaking API changes. Provides constructive suggestions if issues are found.'
---

# Ticket Reviewer

A skill for reviewing Jira-style markdown work tickets that have been planned by `ticket-planner` and are about to be implemented by `ticket-worker`. It performs a sanity check and basic quality assessment to catch gaps, risks, or oversights in the plan before development effort is invested.

This skill sits between `ticket-planner` and `ticket-worker` in the workflow:

```
ticket-maker → ticket-planner → ticket-reviewer → ticket-worker
```

## When to Use This Skill

- User asks to "review a ticket", "check the plan", or "sanity check the ticket"
- User asks to "validate the design" or "review before implementation"
- User wants a second opinion on whether a planned ticket is ready for implementation
- User asks "is this ticket ready to work on?" or "anything missing from this plan?"
- A ticket has its Design and Estimate sections filled in and needs a quality gate before execution

## Prerequisites

- A work ticket in markdown format following the `ticket-maker` template
- The ticket must have the **Design** and **Estimate** sections filled in (typically by `ticket-planner`)
- Access to the relevant codebase for cross-referencing the plan against the actual code

## What This Skill Does NOT Do

- It does **not** expect or look for complete code outlines, concrete implementation details, or code samples in the plan
- It does **not** rewrite the ticket or fill in sections — it only provides feedback
- It does **not** implement any changes to the codebase
- It does **not** replace a human code review — it reviews the *plan*, not the *code*

## Workflow

### Step 1: Read and Understand the Ticket

Parse the full ticket markdown and extract all sections:

1. **Title** — what is being done
2. **Story** — who benefits, what they need, and why
3. **Description** — detailed context and background
4. **Acceptance Criteria** — the definition of done
5. **Design** — the planned approach, key files, data/interfaces, edge cases, testing strategy
6. **Estimate** — expected effort level

Build a mental model of the intended work: what problem is being solved, what the plan proposes, and what "done" looks like.

### Step 2: Examine the Codebase for Context

Gather enough context to assess the plan's feasibility:

- Read the key files identified in the Design section
- Understand the interfaces, types, and patterns that the plan touches
- Identify existing tests, documentation, and public APIs in the affected areas
- Look for related code that the plan may have overlooked

Do not perform a full codebase audit — focus on the areas the ticket touches and their immediate neighbours.

### Step 3: Assess the Plan

Evaluate the ticket against the following checklist. Each area should be considered, but not every area will have issues — only flag genuine concerns.

#### 3a. Logical Completeness

- Does the Design address all Acceptance Criteria? Is there an Acceptance Criterion with no corresponding design element?
- Is the approach coherent? Do the proposed changes logically achieve the stated goals?
- Are there gaps in the plan where a developer would be left guessing what to do?
- Is the plan sufficient for someone to have enough context and information to complete the work, without requiring further design decisions?

#### 3b. Test Coverage

- Does the Testing section cover the new or changed behaviour described in the Design?
- Are there edge cases called out in the Design that lack corresponding test cases?
- Are existing tests likely to need updating due to behavioural changes, and is this mentioned?
- If new error paths, boundary conditions, or failure modes are introduced, are they tested?

#### 3c. Documentation

- If the change affects user-facing behaviour, APIs, configuration, or workflows, does the plan mention documentation updates?
- Are Doxygen/inline doc updates mentioned for modified public interfaces?
- If the change introduces new concepts or patterns, is there a plan to document them?

#### 3d. Resource and Performance Impact

- Does the change introduce increased memory usage (e.g., new data structures, caching, duplication of data)?
- Does it increase CPU cost (e.g., more expensive comparisons, additional iterations, heavier algorithms)?
- Does it increase the cost of operations that are on hot paths or called frequently?
- If there is a performance trade-off, is it acknowledged and justified in the Design?

#### 3e. External API and Compatibility

- Does the change modify any externally facing APIs, interfaces, data formats, or protocols?
- If so, does the plan consider the impact on consumers outside this project?
- Are breaking changes identified and flagged? Is there a migration path or versioning strategy?
- Does the plan account for backward compatibility where needed?

#### 3f. Estimate Reasonableness

- Does the Estimate seem proportional to the scope of work described in the Design?
- Is the work significantly under- or over-estimated relative to the number of files, tests, and complexity involved?

### Step 4: Produce the Review

Based on the assessment, produce one of two outcomes:

#### If the plan passes review:

State clearly that the ticket is ready for implementation. Briefly note any minor observations that don't block progress but are worth keeping in mind.

**Example:**

> **Review: PASS**
>
> The plan is logical, addresses all acceptance criteria, and includes appropriate test and documentation coverage. The estimate is reasonable for the scope.
>
> Minor observations:
> - The concurrent test could benefit from a note about expected run-time on CI.

#### If the plan has issues:

Provide a concise, numbered list of constructive suggestions. Each suggestion should:

1. **Identify the gap** — what is missing or problematic
2. **Explain why it matters** — the risk or consequence if unaddressed
3. **Suggest a remedy** — a concrete action to resolve it

Keep suggestions actionable and proportionate. Do not nitpick wording or formatting — focus on substance.

**Example:**

> **Review: SUGGESTIONS**
>
> The plan is largely sound but has the following gaps:
>
> 1. **Missing test for error path in `fetchData()`.** The Design adds a new early-return when the cache is empty, but the Testing section has no test for this path. Add a test case that calls `fetchData()` with an empty cache and verifies the return value.
>
> 2. **Potential memory increase not acknowledged.** The new in-memory index duplicates entity keys across two maps. For large simulations (>10k entities), this could meaningfully increase memory usage. Add a note in Edge Cases & Risks acknowledging this trade-off.
>
> 3. **Breaking change to `EntityId::operator<`.** The sort-order change from hash-based to lexicographic will affect any external code that iterates over `std::map<EntityId, ...>` and relies on ordering. The Design should note whether any known consumers depend on the current order.

## Review Principles

- **Be constructive, not pedantic.** The goal is to improve the plan, not to find fault.
- **Focus on what matters.** Missing tests, performance regressions, and API breakage are important. Formatting preferences are not.
- **Respect the plan's level of detail.** A design outline is not a code review. Do not demand implementation specifics, exact function signatures, or code samples.
- **Consider the estimate.** A trivial ticket (estimate 1–2) needs less scrutiny than a large one (estimate 8–10).
- **Flag, don't fix.** Identify issues and suggest remedies, but do not rewrite the ticket's Design or Estimate sections.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Design section is empty or missing | Stop and advise the user to run `ticket-planner` first |
| Estimate section is empty or missing | Stop and advise the user to run `ticket-planner` first |
| Ticket has no Acceptance Criteria | Cannot meaningfully review completeness — ask the user to add criteria |
| Plan looks perfect | Say so briefly — a clean review is a valid outcome |
| Too many issues to list | Focus on the top 5 most impactful; note that additional minor issues exist |
| Unsure whether something is an issue | Flag it as a question rather than a definitive problem |

````
