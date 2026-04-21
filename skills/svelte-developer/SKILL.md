---
name: svelte-developer
description: "Expert guidance for building production-grade Svelte applications with maintainable architecture, strong reactivity patterns, and high performance. Use when asked to create or review Svelte/SvelteKit components, stores, forms, routing, transitions, accessibility, or state management; optimize render behavior; prevent anti-patterns; and apply modern Svelte best practices backed by official docs."
license: Complete terms in LICENSE.txt
---

# Svelte Developer

A specialist skill for designing, implementing, and reviewing Svelte code with an emphasis on correctness, maintainability, and performance.

When uncertainty exists, consult the bundled reference docs first, then prefer official Svelte guidance and examples from:

- `references/official-docs-map.md`
- `references/patterns-and-pitfalls.md`

- https://svelte.dev/docs
- https://svelte.dev/tutorial
- https://svelte.dev/playground

## Bundled References

- `references/official-docs-map.md`: Fast map of official Svelte and SvelteKit documentation.
- `references/patterns-and-pitfalls.md`: Practical implementation patterns, anti-patterns, and review checklist.

## Multi-Skill Collaboration

For mixed frontend/backend work, use the `/code-optimisation` skill with the `/go-developer` and `/svelte-developer` skills.

- Use `/svelte-developer` to implement or review Svelte and SvelteKit UI architecture, reactivity, and accessibility.
- Use `/go-developer` to implement or refactor Go service logic, APIs, tests, and packaging.
- Use `/code-optimisation` to run a structured performance pass across both layers (CPU, memory, I/O, duplication, and algorithmic efficiency).

Recommended order for cross-stack tasks:

1. Build or refactor functionality with `/svelte-developer` and `/go-developer`.
2. Confirm behavior and correctness with tests/checks in each layer.
3. Apply `/code-optimisation` as a final review to identify measurable performance and structural improvements.

## When to Use This Skill

Use this skill when the request involves:

- Building or editing Svelte components (`.svelte`)
- SvelteKit pages/layouts/endpoints and data loading
- Reactivity issues (`$:` / runes / derived values)
- Store architecture (`writable`, `readable`, `derived`, custom stores)
- Forms, validation, controlled/uncontrolled input behavior
- Event propagation, bindings, context, slots/snippets, composition
- Animations/transitions/motion and perceived performance
- Accessibility and semantic HTML in interactive UI
- Refactoring for testability and long-term maintainability
- Diagnosing performance regressions or hydration/rendering issues

## Core Principles

- Prefer clarity over cleverness. Optimize only after identifying measurable bottlenecks.
- Keep components focused and small; extract reusable behavior into utilities or stores.
- Minimize global mutable state and avoid hidden coupling between components.
- Preserve one-way data flow unless two-way bindings are clearly justified.
- Treat accessibility as a baseline quality requirement, not an afterthought.
- Keep side effects explicit and lifecycle-aware.

## Implementation Workflow

1. Understand scope and runtime context.

- Confirm whether the code is Svelte-only or SvelteKit.
- Identify server-only vs browser-only logic.
- Confirm expected UX behavior and error states.

2. Model state deliberately.

- Keep ephemeral UI state local to components.
- Promote shared state to stores only when multiple consumers need it.
- Use derived/computed state instead of duplicating source-of-truth values.

3. Build predictable reactivity.

- Keep reactive calculations deterministic and side-effect free where possible.
- Isolate side effects from pure value computation.
- Avoid chained reactive statements that obscure update order.

4. Design component interfaces.

- Keep props minimal, explicit, and well-named.
- Prefer events/callbacks for upward communication instead of mutating external objects.
- Use composition (slots/snippets/children patterns) to avoid prop explosion.

5. Validate UX quality.

- Keyboard navigation and focus states are required.
- Loading, empty, error, and success states should all be represented.
- Motion should support comprehension and respect reduced-motion preferences.

6. Review and harden.

- Remove dead code and unnecessary reactivity.
- Ensure no accidental SSR/CSR boundary violations.
- Verify maintainability: naming, cohesion, and testability.

## Svelte Best Practices

- Use semantic HTML first; only add ARIA where semantics are insufficient.
- Favor computed values over ad hoc mutation during rendering.
- Keep expensive operations outside hot render paths.
- Use keyed `each` when identity matters and list order can change.
- Avoid excessive prop drilling; use context or stores with clear boundaries.
- Co-locate component styles unless shared tokens/utilities are required.
- Avoid premature abstractions; extract only after repeated use patterns emerge.

## SvelteKit Best Practices

- Put data fetching at the correct layer (`load`, server endpoints, or actions).
- Keep secrets and privileged logic on the server side.
- Avoid duplicate fetches between server and client during hydration.
- Use progressive enhancement where possible for forms/actions.
- Handle expected failure paths explicitly with user-facing feedback.

## Anti-Patterns To Avoid

- Overusing global stores for state that should remain local.
- Reactive blocks that both compute values and perform side effects.
- Mutating nested objects/arrays in ways that do not trigger intended updates.
- Passing large mutable objects through many component boundaries.
- Unkeyed dynamic lists where item identity changes.
- Triggering network calls directly from reactive statements without guards.
- Tight coupling between UI components and transport/client details.
- Ignoring cleanup for subscriptions, listeners, timers, or observers.
- Hiding critical behavior in CSS-only interactions without keyboard equivalence.

## Performance Checklist

- Verify list rendering strategy and key stability.
- Minimize avoidable recomputation in reactive code paths.
- Defer non-critical work and lazily load heavy modules/components.
- Reduce unnecessary store subscriptions and broad invalidation.
- Keep transitions/animations lightweight on large collections.
- Profile before and after optimization; keep optimizations evidence-driven.

## Common Pitfalls

- SSR-only APIs used in browser code or browser-only APIs used during SSR.
- Hydration mismatches caused by non-deterministic initial values.
- Inconsistent state after async operations resolve out of order.
- Form behavior diverging between native submission and enhanced submission.
- Event handlers relying on stale closures after state changes.

## Code Review Focus

When reviewing Svelte code, prioritize:

- Correctness of reactive logic and update timing
- State ownership and data-flow clarity
- Accessibility and keyboard behavior
- SSR/CSR correctness in SvelteKit contexts
- Performance hotspots in lists, stores, and derived computations
- Readability, cohesion, and testability of component boundaries

## Documentation-First Rule

If behavior is ambiguous or version-sensitive:

- Consult official Svelte docs before implementing assumptions.
- Prefer patterns shown in current docs/tutorial examples.
- Note any version-dependent behavior in comments or review notes.

## Troubleshooting Guide

- UI not updating as expected:
  - Check whether reactive dependencies are explicit and mutation is tracked.
- Duplicate fetches or odd hydration behavior:
  - Verify data-loading boundaries and SSR/client responsibilities.
- Sluggish interactions:
  - Inspect list rendering, transition cost, and unnecessary recomputation.
- Accessibility regressions:
  - Validate semantic structure, keyboard flows, labels, and focus management.

## Output Expectations

When applying this skill, produce:

- Production-ready Svelte/SvelteKit code aligned with current best practices
- Concise rationale for non-obvious architectural choices
- Clear mention of trade-offs (simplicity vs flexibility, performance vs complexity)
- Explicit call-outs for residual risks and suggested follow-up tests
