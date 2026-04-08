````skill
---
name: ticket-a-z
description: 'End-to-end ticket workflow from description to done. Use when asked to "do everything", "ticket A to Z", "full ticket workflow", "create and implement", "handle this end to end", "take this from idea to done", or when the user provides a task description and wants the full cycle: create ticket, plan it, review the plan, address review feedback, and implement the work. Orchestrates ticket-maker, ticket-planner, ticket-reviewer, and ticket-worker in sequence.'
---

# Ticket A-Z

An orchestration skill that drives a task from a brief description all the way to a completed implementation. It chains the four ticket skills in sequence, handling the feedback loop between review and planning automatically.

```
User description → ticket-maker → ticket-planner → ticket-reviewer → (address feedback) → ticket-worker
```

## When to Use This Skill

- User provides a task description and wants the entire workflow handled
- User asks to "do this end to end", "handle this A to Z", or "take this from idea to done"
- User wants to skip manually invoking each ticket skill in sequence
- User says "create a ticket and do the work" or "full ticket workflow"

## Prerequisites

- A clear description of the work to be done (can be as brief as a sentence)
- Access to the relevant codebase
- The project should be in a buildable/testable state

## Workflow

### Step 1: Create the Ticket

Read the `ticket-maker` skill instructions and follow them to create a ticket from the user's description.

- Extract the persona, goal, benefit, and technical context from the user's input
- Produce a complete ticket markdown file with all standard sections
- Save the ticket to the `.tickets/` directory using a descriptive kebab-case filename

At the end of this step, confirm the ticket location to the user and briefly summarise what was created.

### Step 2: Plan the Ticket

Read the `ticket-planner` skill instructions and follow them to fill in the Design and Estimate sections of the ticket created in Step 1.

- Examine the codebase to understand the affected areas
- Write the Design section with approach, key changes, data/interfaces, edge cases, testing strategy, and documentation
- Assign an Estimate using the standard scale

At the end of this step, briefly summarise the planned approach and estimate.

### Step 3: Review the Plan

Read the `ticket-reviewer` skill instructions and follow them to review the planned ticket.

- Assess the plan for logical completeness, test coverage, documentation gaps, resource/performance impacts, external API compatibility, and estimate reasonableness
- Produce either a PASS or a list of constructive suggestions

At the end of this step, share the review outcome with the user.

### Step 4: Address Review Feedback

If the review produced suggestions:

1. Evaluate each suggestion against the ticket and codebase
2. For suggestions that are valid and actionable, update the ticket's Design, Acceptance Criteria, or Testing sections accordingly
3. For suggestions that are not applicable (e.g., based on incorrect assumptions or already addressed), note why they were skipped
4. Briefly summarise what was updated and what was skipped, with reasons

If the review was a PASS, proceed directly to Step 5.

**Do not re-run the reviewer after addressing feedback.** A single review pass is sufficient. The goal is to catch obvious gaps, not to iterate to perfection.

### Step 5: Implement the Work

Read the `ticket-worker` skill instructions and follow them to implement the changes described in the (now reviewed and updated) ticket.

- Implement the changes following the Design section
- Add or update tests as specified
- Update documentation as needed
- Build and run all tests to confirm everything passes
- Fill in the post-implementation sections: Implementation Notes, Verification Notes, Technical Release Notes, and Customer Release Notes

At the end of this step, confirm the implementation is complete with a summary of what was done and the test results.

## Communication

At each stage transition, provide a brief status update to the user so they can follow the progress:

- After Step 1: "Ticket created at `[path]`."
- After Step 2: "Plan complete. Estimate: [N]. Approach: [one-sentence summary]."
- After Step 3: "Review: [PASS / N suggestions]." and list any suggestions.
- After Step 4: "Addressed [N] of [M] suggestions. [brief summary]." (only if suggestions existed)
- After Step 5: "Implementation complete. [N] tests pass."

## Error Handling

| Situation | Action |
|-----------|--------|
| User description is too vague to create a ticket | Ask clarifying questions before starting Step 1 |
| Estimate comes back as 20 (too large) | Stop after Step 2, advise the user to split the work, and suggest sub-tickets |
| Review finds critical issues with the plan | Address them in Step 4; if an issue fundamentally invalidates the approach, stop and consult the user |
| Build or tests fail during implementation | Debug and fix as part of Step 5 (per ticket-worker workflow) |
| A skill's instructions conflict with this orchestration | Follow the individual skill's instructions for that step; this skill only defines the sequence and transitions |

## Principles

- **Each step follows its own skill's rules.** This skill defines the orchestration order and transitions, not the internal behaviour of each step. Read and follow each skill's SKILL.md for the detailed workflow.
- **Keep the user informed.** Brief status updates at each transition prevent the user from wondering what's happening.
- **Don't over-iterate.** One review pass is enough. Address valid feedback and move on.
- **Respect scope.** If the review reveals the ticket is fundamentally wrong or too large, stop and consult the user rather than silently expanding the scope.

````

<!-- Copyright 2026 Fortescue Ltd. All rights reserved. -->
