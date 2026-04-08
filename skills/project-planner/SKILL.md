````skill
---
name: project-planner
description: 'Generate a detailed project plan from high-level requirements. Use when asked to "plan a project", "create a project plan", "write an architecture document", "design a system", "plan an application", "create a high-level design", or when the user provides feature requirements and wants a comprehensive implementation plan covering architecture, components, phasing, and build strategy. Produces a structured markdown document. May ask clarifying questions before generating.'
---

# Project Planner

A skill for turning high-level requirements into a detailed, actionable project plan. The user provides a description of what they want to build — features, constraints, technology preferences — and this skill produces a comprehensive markdown document that a development team can use to implement the system.

## When to Use This Skill

- User describes an application or system they want to build and asks for a plan
- User asks to "plan a project", "design a system", or "create an architecture document"
- User provides a list of features and wants a high-level implementation approach
- User says "how would I build this?" or "create a project plan for this"
- User wants a structured document covering architecture, components, phasing, and build strategy

## Prerequisites

- A description of what the user wants to build (can range from a few sentences to a detailed feature list)
- Any technology preferences or constraints the user has mentioned
- Knowledge of the target audience and deployment environment (or enough context to infer them)

## Workflow

### Step 1: Understand the Requirements

Parse the user's input and extract:

1. **What** is being built — the core product or system
2. **Why** — the problem it solves or the value it provides
3. **Features** — specific capabilities the user has listed
4. **Constraints** — technology requirements, platform targets, performance needs, things explicitly excluded
5. **Future scope** — features mentioned as "later" or "future" that should be designed for but not built immediately

### Step 2: Ask Clarifying Questions (if needed)

If the requirements are ambiguous or incomplete in ways that would materially affect the plan, ask clarifying questions **before** generating. Focus on questions that change the architecture, not details that can be decided during implementation.

Good reasons to ask:
- The deployment model is unclear (single process vs distributed, local vs cloud)
- The primary language or framework is unspecified and multiple valid choices exist
- A listed feature could mean fundamentally different things
- Critical constraints are missing (e.g., "real-time" without specifying what that means)

Do not ask about:
- Implementation details that can be deferred (exact library versions, minor API naming)
- Things that can be reasonably inferred from context
- Preferences that have obvious defaults

If the requirements are clear enough to proceed, skip this step entirely.

### Step 3: Generate the Project Plan

Produce a structured markdown document covering the sections described below. The plan should be:

- **Concrete** — name specific technologies, file structures, APIs, and data formats
- **Proportional** — more detail for complex or novel components, less for straightforward ones
- **Actionable** — a developer should be able to start implementation from this document without needing to make major architectural decisions
- **Honest about unknowns** — call out open questions and trade-offs rather than making arbitrary choices silently

### Step 4: Save the Document

Save the generated plan to the location specified by the user (or a sensible default like `docs/`). Use a descriptive filename in kebab-case.

## Document Structure

The generated plan should include the following sections, adapted to the scale and complexity of the project. Not every section is required for every project — omit sections that don't apply.

### Required Sections

#### Overview
Two to three paragraphs describing what the system is, what problem it solves, and the major components at a high level. This should be understandable by someone with no prior context.

#### Goals
A numbered table of specific, measurable goals the system must achieve. These are the success criteria for the project.

#### Non-Goals
Explicitly state what the system will *not* do in the initial release. This prevents scope creep and sets expectations.

#### System Architecture
A high-level diagram (ASCII art or text description) showing the major components and how they interact. Include data flow direction and key interfaces.

#### Component Descriptions
For each major component, describe:
- **Responsibilities** — what it does
- **Technology** — language, framework, key libraries
- **Public interfaces** — APIs, data formats, protocols it exposes
- **Internal structure** — key subsystems or modules within the component

Use tables for API surfaces, configuration options, and other structured information.

#### Repository Layout
A proposed directory structure showing where code, tests, documentation, and configuration live.

#### Build & Integration
How the project is built, tested, and integrated. Cover:
- Build system (CMake, pip, npm, etc.)
- Test framework and strategy
- CI pipeline structure
- How the components are used by consumers / integrated into existing systems

#### Phased Delivery
Break the work into phases, from MVP to full feature set. Each phase should be independently deliverable and valuable. Include:
- Phase name and number
- Deliverables for that phase
- Rough scope (which components and features)

#### Open Questions
A numbered list of unresolved decisions that should be made before or during implementation. For each, briefly describe the trade-offs.

### Optional Sections (include when relevant)

#### API Compatibility Strategy
When the system must be compatible with an existing API or protocol, describe the compatibility approach, what level of compatibility is targeted, and how it will be validated.

#### Determinism / Concurrency Design
When the system has specific requirements around determinism, thread safety, or concurrency, describe the design approach and how the requirements are met.

#### Data Formats
When the system defines new file formats, wire protocols, or data schemas, describe them with examples.

#### Security Considerations
When the system handles sensitive data, authentication, or runs in a networked environment.

#### Performance Considerations
When the system has specific performance requirements or known scalability concerns.

## Style Guidelines

- **Use tables** for structured comparisons (API surfaces, QoS policies, configuration options, phase deliverables).
- **Use ASCII diagrams** for architecture overviews — they render in any markdown viewer and diff cleanly.
- **Use code blocks** for API examples, directory structures, and data format samples.
- **Be specific** — name files, classes, functions, and formats. "A configuration file" is less useful than "`config.yaml` with a `scheduler.strategy` key".
- **Write for developers** — assume the reader is technically competent but unfamiliar with the specific domain.
- **Keep sections independent** — a reader should be able to jump to any section without reading the whole document.
- **Flag trade-offs** — when there are multiple valid approaches, briefly describe the options and state which one the plan recommends and why.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Requirements are a single sentence | Ask 2-3 targeted clarifying questions before generating |
| Project is too large to plan in one document | Produce a top-level architecture document and recommend separate detailed plans for each major component |
| User specifies contradictory requirements | Call out the contradiction in Open Questions and propose a resolution |
| Technology choice is unclear | Default to the most common/practical option in the domain; note it as a decision point in Open Questions |
| User wants code, not a plan | This skill produces plans only; direct them to implementation skills or workflows |

````
