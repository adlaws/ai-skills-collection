---
name: ticket-maker
description: 'Create Jira-style work tickets in markdown format. Use when asked to "create a ticket", "make a work ticket", "write a Jira ticket", "draft a story", "create a task", "write acceptance criteria", or when structuring work items with story, description, acceptance criteria, design, implementation notes, estimates, and release notes. Generated tickets will be used by the ticket-planner and ticket-worker skills to plan and execute work.'
---

# Work Ticket Maker

A skill for creating structured Jira-style work tickets in markdown format. Produces a complete ticket document with all standard sections needed to plan, estimate, implement, verify, and document a unit of work.

The created ticket can then be analyzed and filled out by the `ticket-planner` skill to determine design and effort, and ultimately executed by the `ticket-worker` skill.

## When to Use This Skill

- User asks to "create a ticket", "make a work ticket", or "draft a story"
- User needs a structured work item with acceptance criteria
- User wants to plan a feature, bug fix, or task in Jira ticket format
- User asks to "write a Jira ticket" or "create a task description"
- User needs to break down work into a trackable, reviewable document

## Prerequisites

- A clear understanding of the work to be done, or enough context for the agent to infer it
- Knowledge of the target audience/user role (for the story statement)

## Workflow
1. Interpret the user’s request.
   - If it’s ambiguous, assume they want a JIRA ticket.
   - Never write or edit code under any circumstance.
2. Extract key details:
   - Persona
   - Goal
   - Benefit
   - Any relevant technical elements
3. Write each section using **only words necessary for clarity**.
4. Ensure the output is executable by a developer with no further clarification needed.
5. Output the formatted JIRA ticket once, without unnecessary commentary.

## Style Rules
- Be **factual, minimal, and explicit**.
- Avoid intros, transitions, or commentary.
- Use **direct, simple sentences**.
- Never include implementation advice or sample code.
- If uncertain, ask only what’s required to remove ambiguity before generating the ticket.

## Behavior
- Always produce one complete, formatted ticket per user request.
- Never modify files, execute tools, or suggest code.
- Never output scaffolding or placeholder templates.
- Assume the goal is ticket generation unless explicitly told otherwise.

## Ticket Structure

Generate a markdown document with the following sections, in order. Use the information provided by the user to fill in as many sections as possible. Sections that are typically filled in later by the developer should be left with a placeholder note.

### Template

```markdown
# [TITLE]

## Story

As a [persona], I want [goal] so that [benefit].

## Description

[2–3 brief sentences describing the problem, solution, and any essential context.]

**Technical Context (if applicable)**

- [File/service/component]

## Acceptance Criteria

- [ ] [Specific, testable condition that must be met]
- [ ] [Another specific condition]
- [ ] ...
- [ ] Documentation updated (if relevant)
- [ ] Unit tests added/updated (if relevant)
- [ ] Project builds successfully
- [ ] All unit tests pass

## Design

_To be completed by the assigned developer before implementation begins._

[Basic description of the plan or approach that will be taken to meet the demands of the ticket.]

## Implementation Notes

_To be completed by the assigned developer after implementation._

[Description of how the job was completed, particularly mentioning any deviations from the design originally drawn up.]

## Estimate

| Estimate | Description |
|----------|-------------|
| 1        | Trivial — minutes of effort |
| 2        | Small — less than half a day |
| 3        | Moderate — roughly half a day |
| 5        | Significant — about a day |
| 8        | Large — a few days |
| 10       | Very large — up to a week |
| **20**   | **Too large — break into smaller tickets** |

**Estimate:** _To be completed by the assigned developer._

## Verification Notes

_To be completed by the assigned developer for the reviewer._

[Notes for a reviewer to verify that the work satisfies the acceptance criteria. Include steps to test, areas of risk, and anything the reviewer should pay special attention to.]

## Technical Release Notes

[Brief technical notes on the feature/capability added or bug fixed. May include implementation details if relevant, particularly if a breaking change was introduced.]

## Customer Release Notes

[Notes on the feature/capability added or bug fixed, written for a non-technical audience. Focus on user-visible changes and benefits.]
```

## Guidelines

### Title
- Keep to **10 words ideally**, 15–20 words maximum.
- Be specific and action-oriented (e.g., "Add CSV export to reports page" not "Reports improvement").

### Story
- Always use the format: **As a [persona], I want [goal] so that [benefit].**
- The persona should be a concrete user type (e.g., "project manager", "API consumer", "end user"), not generic.

### Description
- Provide enough context for a developer unfamiliar with the feature to understand the problem.
- Reference related tickets or documentation if applicable.

### Acceptance Criteria
- Each criterion should be **specific and independently testable**.
- Always include the standard items unless explicitly irrelevant:
  - Documentation updated (if relevant)
  - Unit tests added/updated (if relevant)
  - Project builds successfully
  - All unit tests pass
- Use checkbox format (`- [ ]`) for easy tracking.

### Design & Implementation Notes
- Leave blank by default with placeholder text for the developer.
- If the user provides design direction, include it.

### Estimate
- Leave blank by default with placeholder text for the ticket-planner.
- Use only the Fibonacci-like scale: **1, 2, 3, 5, 8, 10, or 20**.
- If 20, recommend breaking the ticket into smaller tickets.
- Leave blank by default for the developer to fill out.

### Verification Notes
- Leave blank by default with placeholder text for the ticket-worker.
- If the user provides verification guidance, include it.

### Release Notes
- **Technical Release Notes**: Written for developers/ops. May include API changes, breaking changes, migration steps.
- **Customer Release Notes**: Written for end users. Focus on what changed and why it matters to them. Avoid jargon.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Title too long | Shorten to the core action; move detail into Description |
| Story feels forced | Ensure the role is a real user type; if internal tooling, use "developer" or "team member" |
| Acceptance criteria vague | Make each item a pass/fail test; avoid "should work well" |
| Estimate unclear | If unsure, leave blank; if clearly large, recommend splitting |

````
