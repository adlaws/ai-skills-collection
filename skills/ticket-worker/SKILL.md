````skill
---
name: ticket-worker
description: 'Implement work described in a planned ticket created by ticket-maker and filled out by ticket-planner. Use when asked to "implement a ticket", "do the ticket", "work on a ticket", "execute the plan", "implement the design", or when a developer wants to carry out the work described in a Jira-style markdown ticket. Reads the full ticket including Design and Estimate, implements the changes in the codebase, then fills in Implementation Notes, Verification Notes, Technical Release Notes, and Customer Release Notes.'
---

# Ticket Worker

A skill for implementing the work described in a Jira-style markdown ticket (as produced by `ticket-maker` and planned by `ticket-planner`). It reads the ticket, understands the requirements, executes the implementation following the design, and completes the post-implementation sections of the ticket.

## When to Use This Skill

- User asks to "implement this ticket", "do the ticket", or "work on this ticket"
- User asks to "execute the plan" or "implement the design"
- User has a fully planned ticket open and wants the work carried out
- User says "build this feature" or "fix this bug" while referencing a ticket
- User asks to "complete the ticket" or "do the work described here"

## Prerequisites

- A work ticket in markdown format following the `ticket-maker` template
- The ticket must have the **Design** and **Estimate** sections filled in (typically by `ticket-planner`)
- Access to the codebase where the changes will be made
- The project should be in a buildable/testable state before starting

## Workflow

### Step 1: Read and Understand the Full Ticket

Parse the ticket markdown and extract all sections:

1. **Title** — what is being done
2. **Story** — who benefits, what they need, and why
3. **Description** — detailed context and background
4. **Acceptance Criteria** — the definition of done (the checklist to satisfy)
5. **Design** — the planned approach, key files, data/interfaces, edge cases, testing strategy
6. **Estimate** — expected effort level

The **Acceptance Criteria** are the primary measure of success. Every criterion must be met. The **Design** section is the roadmap — follow it unless there is a good reason to deviate.

### Step 2: Examine the Codebase

Before writing any code, gather context:

- Read the key files identified in the Design section
- Understand existing patterns, conventions, naming, error handling, and architecture
- Identify existing tests and test patterns to follow
- Check for related configuration, documentation, or schema files that may need updates

### Step 3: Implement the Changes

Work through the Design systematically:

1. **Follow the Design.** Implement changes in the order and manner described. If the Design identifies key files and approaches, follow them.
2. **Work incrementally.** Make changes file by file, verifying correctness as you go. Don't try to change everything at once.
3. **Follow existing patterns.** Match the codebase's coding style, naming conventions, error handling patterns, and architectural decisions.
4. **Handle edge cases.** Address the edge cases and risks called out in the Design section.
5. **Track deviations.** If you must deviate from the Design (e.g., discover a better approach, find the Design was based on incorrect assumptions, or encounter an obstacle), note the deviation and the reason.

#### Implementation Principles

- **Do the simplest thing that satisfies the acceptance criteria.** Don't over-engineer or add unrequested features.
- **Don't break existing functionality.** Be careful with refactors; ensure existing tests still pass.
- **Create clean, readable code.** Future developers will maintain this. Use clear names, add comments for non-obvious logic.
- **Respect scope boundaries.** If you discover work that should be done but is outside this ticket's scope, note it as a follow-up rather than doing it now.

### Step 4: Add or Update Tests

Following the testing strategy from the Design section:

- Add unit tests for new functionality
- Update existing tests if behavior has changed
- Follow the existing test patterns and frameworks in the codebase
- Ensure all tests pass — both new and existing

### Step 5: Update Documentation

If acceptance criteria or the Design section call for documentation updates:

- Update README files, inline documentation, or configuration schema descriptions
- Keep documentation consistent with the implemented behavior

### Step 6: Verify Against Acceptance Criteria

Go through every acceptance criterion one by one and verify it is met:

- [ ] Each specific criterion from the ticket — confirmed working
- [ ] Documentation updated (if the criterion was present)
- [ ] Unit tests added/updated (if the criterion was present)
- [ ] Project builds successfully
- [ ] All unit tests pass

If any criterion is not met, go back and address it before proceeding.

### Step 7: Fill In Post-Implementation Sections

Update the ticket markdown with the following sections. **Do not modify** the Title, Story, Description, Acceptance Criteria, Design, or Estimate sections.

#### Implementation Notes

Describe what was actually done:

- Summarize the changes made, file by file or feature by feature
- **Explicitly call out any deviations from the Design** — what changed, why, and what the actual approach was
- Note any surprises, difficulties, or decisions made during implementation
- If the work was straightforward and followed the Design exactly, say so briefly

#### Verification Notes

Provide clear guidance for a reviewer to verify the work:

- **How to test** — specific steps a reviewer can follow to verify the feature works (e.g., "Run the app, navigate to X, click Y, expect Z")
- **What to look for** — areas of risk or places where regressions are most likely
- **Test commands** — exact commands to run the test suite or specific test files
- **Edge cases to check** — any non-obvious scenarios the reviewer should verify
- **Configuration** — any settings, environment variables, or setup needed to test

#### Technical Release Notes

Write concise notes for a technical audience (developers, ops, architects):

- What was added, changed, or fixed
- Any new APIs, configuration keys, or interfaces introduced
- Breaking changes and migration steps (if any)
- Performance implications (if any)
- Dependencies added or updated (if any)

#### Customer Release Notes

Write concise notes for a non-technical audience (end users, product managers, stakeholders):

- What the user can now do that they couldn't before (or what bug was fixed)
- How it benefits them
- Any changes to existing workflow they should be aware of
- Avoid jargon — use plain language

### Step 8: Final Review

Before declaring the ticket complete:

1. Re-read the Acceptance Criteria one final time — every item should be satisfied
2. Ensure the project builds cleanly
3. Ensure all tests pass
4. Ensure the four post-implementation sections are filled in
5. Confirm no unintended changes were made to files outside the ticket's scope

## Output Expectations

When the ticket is complete, the post-implementation sections should look like:

```markdown
## Implementation Notes

[Summary of what was done]

- **`path/to/file.ts`** — [what was changed]
- **`path/to/new-file.ts`** — [new file, purpose]
- ...

**Deviations from Design:** [None / description of deviations and reasons]

## Verification Notes

### How to Test

1. [Step-by-step verification instructions]
2. ...

### Test Commands

- `npm test` (or equivalent)
- `npm run build` (or equivalent)

### Areas of Risk

- [Specific areas a reviewer should scrutinize]

## Technical Release Notes

- [Concise technical description of changes]

## Customer Release Notes

- [Plain-language description of what changed for end users]
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Design section is empty or missing | Stop and ask the user to run `ticket-planner` first |
| Acceptance criteria are ambiguous | Interpret them in the most reasonable way; note your interpretation in Implementation Notes |
| Tests fail after changes | Debug and fix before proceeding; do not leave broken tests |
| Design approach doesn't work as expected | Deviate and document the deviation clearly in Implementation Notes |
| Scope creep discovered during implementation | Note it as a follow-up item in Implementation Notes; don't expand the ticket's scope |
| Build fails | Fix build errors before completing; they are part of the acceptance criteria |

````
