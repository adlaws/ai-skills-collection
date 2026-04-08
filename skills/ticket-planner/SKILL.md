````skill
---
name: work-ticket-planner
description: 'Analyze and plan work tickets created by ticket-maker. Use when asked to "plan a ticket", "estimate a ticket", "fill out the design", "analyze a work ticket", "plan implementation", or when a developer needs to understand approach and effort for a Jira-style markdown ticket. Reads the ticket Title, Story, Description, and Acceptance Criteria, examines the current codebase for context, then fills in the Estimate and Design sections. The completed ticket will be used by the ticket-worker skill to execute the work.'
---

# Work Ticket Planner

A skill for analyzing Jira-style markdown work tickets (as produced by the `ticket-maker` skill) and filling in the **Estimate** and **Design** sections. It reads the ticket's intent, examines the relevant parts of the codebase, and produces a design outline and effort estimate that give a developer a clear starting point for implementation.

## When to Use This Skill

- User asks to "plan a ticket", "estimate a ticket", or "fill out the design"
- User has a work ticket markdown file open and wants the Design and Estimate completed
- User asks to "analyze this ticket" or "figure out how to implement this"
- User wants a development approach and effort estimate for a piece of work
- User says "plan implementation" or "what would it take to do this ticket"

## Prerequisites

- A work ticket in markdown format following the `ticket-maker` template (must have Title, Story, Description, and Acceptance Criteria sections)
- Access to the relevant codebase so the skill can examine existing code, architecture, and patterns

## Workflow

### Step 1: Read and Understand the Ticket

Parse the ticket markdown and extract:

1. **Title** — the concise summary of the work
2. **Story** — the user role, desired capability, and motivation
3. **Description** — the detailed problem context, examples, and workflows
4. **Acceptance Criteria** — the specific conditions that define "done"

Synthesize these into a clear understanding of **what** needs to be built or changed and **why**.

### Step 2: Examine the Codebase

Using the ticket's intent as a guide, search the codebase to understand:

- **Where** the change will land — which files, modules, layers, or services are involved
- **What exists** — current implementations, patterns, conventions, and data structures relevant to the ticket
- **What's adjacent** — related features, shared utilities, or abstractions that can be reused or must be respected
- **What's affected** — downstream consumers, tests, documentation, or configuration that may need updates

Focus the investigation on building enough context to describe a credible approach. Do not attempt to read the entire codebase — target the areas the ticket touches.

### Step 3: Determine the Estimate

Assign an estimate using the standard scale:

| Estimate | Meaning |
|----------|---------|
| 1        | Trivial — minutes of effort, a one-line change or config tweak |
| 2        | Small — under half a day, a few files touched |
| 3        | Moderate — roughly half a day, some thought required |
| 5        | Significant — about a day, multiple files or a new minor feature |
| 8        | Large — a few days, cross-cutting changes or a substantial feature |
| 10       | Very large — up to a week, significant new functionality or refactor |
| 20       | Too large — recommend breaking into smaller tickets |

Consider:

- Number of files/modules that need changes
- Whether new abstractions, APIs, or data structures are needed
- Testing complexity (new test infrastructure vs. adding cases to existing suites)
- Risk of regressions or breaking changes
- Whether the work is routine (following existing patterns) or novel

If the estimate is **20**, explicitly recommend how to split the ticket.

### Step 4: Write the Design Section

Fill in the **Design** section of the ticket with a clear, concise plan. The design should give a developer enough direction to begin implementation without ambiguity about the general approach. It need not be a line-by-line implementation plan, but it must answer:

1. **Approach** — What is the high-level strategy? (e.g., "Add a new service class that…", "Extend the existing handler to…", "Refactor X into Y so that…")
2. **Key files / modules** — Which specific files or areas of the codebase will be created or modified?
3. **Data & interfaces** — Are there new types, interfaces, APIs, or schema changes? Briefly describe them.
4. **Behavioral changes** — How will the system behave differently after this work? Any new user-facing flows?
5. **Edge cases & risks** — Are there known edge cases, backward-compatibility concerns, or risks to call out?
6. **Testing strategy** — What kinds of tests are needed? (unit, integration, manual verification) Which existing test patterns to follow?
7. **Documentation** — What documentation needs updating? (README, inline docs, config schema descriptions, user facing documentation, AI facing documentation, etc.)

#### Design Writing Guidelines

- **Be concrete.** Name files, functions, types, and config keys where known. Reference what you found in the codebase.
- **Be proportional.** A trivial ticket (estimate 1–2) needs only a sentence or two. A large ticket (estimate 8–10) warrants a more detailed breakdown.
- **Follow existing patterns.** If the codebase has established conventions (naming, architecture, error handling), note that the implementation should follow them.
- **Flag unknowns.** If something needs further investigation or a decision from the team, call it out explicitly rather than guessing.
- **Use lists and short paragraphs.** The design should be scannable, not a wall of text.

### Step 5: Update the Ticket

Replace the placeholder text in the **Estimate** and **Design** sections of the ticket markdown with the completed content. Do not modify any other sections.

## Output Format

When updating the ticket, the Design section should look like:

```markdown
## Design

### Approach

[1–3 sentences describing the high-level strategy]

### Key Changes

- **`path/to/file.ts`** — [what changes and why]
- **`path/to/other.ts`** — [what changes and why]
- [New file] **`path/to/new.ts`** — [purpose]

### Data & Interfaces

- [New type/interface/schema description, if any]

### Edge Cases & Risks

- [Known risks, backward-compatibility notes, or decisions needed]

### Testing

- [What to test and how, following existing patterns]

### Documentation

- [What docs to update]
```

And the Estimate section:

```markdown
**Estimate:** **[N]** — [one-sentence justification]
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Ticket has no clear acceptance criteria | Ask the user to complete the acceptance criteria before planning |
| Codebase is too large to understand quickly | Focus on the modules/files mentioned or implied by the ticket; use grep and file search to narrow scope |
| Estimate is 20 | Recommend splitting; suggest 2–4 sub-tickets with rough scope for each |
| Design feels too speculative | Flag unknowns explicitly; a design with called-out unknowns is better than a falsely confident one |
| Ticket is a bug fix | Look for the likely source of the bug first; design should describe the fix and how to verify it |

````
