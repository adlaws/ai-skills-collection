# Patterns And Pitfalls

A practical reference for implementing maintainable, performant Svelte and SvelteKit code.

## Recommended Patterns

- Keep local UI state in the component unless multiple distant consumers need it.
- Use stores for shared state boundaries, not as a default for every value.
- Derive data from source-of-truth values instead of duplicating state.
- Split large components by responsibility (presentation, behavior, data boundary).
- Use keyed each blocks when list identity can change.
- Keep side effects explicit and close to lifecycle boundaries.
- Use form actions and progressive enhancement in SvelteKit for resilient UX.
- Build accessible interactions first with semantic HTML and keyboard support.

## Common Anti-Patterns

- Global store sprawl for state that should stay local.
- Reactive blocks with mixed concerns (compute + side effects + I/O).
- Mutating nested objects/arrays without ensuring updates are tracked.
- Network calls tied directly to reactive statements without guards/debounce/cancelation.
- Unkeyed dynamic lists with reorder/remove behavior.
- Tight coupling between UI components and API transport details.
- Missing cleanup of listeners, subscriptions, intervals, or observers.

## Performance Guardrails

- Avoid heavy computation directly in hot render paths.
- Limit broad invalidation by narrowing store subscriptions.
- Profile before optimization and verify post-change impact.
- Use lazy loading for heavy routes/components when appropriate.
- Keep animation/transition cost low for large lists.
- Avoid re-creating stable objects/functions unnecessarily in frequently updated code paths.

## SSR/CSR Safety Checks

- Ensure browser-only APIs are guarded in SSR contexts.
- Avoid non-deterministic initial output that causes hydration mismatch.
- Keep server-only logic and secrets on the server.
- Validate that load/data boundaries prevent duplicate fetch work.

## Review Checklist

- Is state ownership clear and minimal?
- Is reactive logic deterministic and readable?
- Are async paths race-safe and cancellation-aware when needed?
- Are empty/loading/error/success states present?
- Is keyboard and screen-reader usability intact?
- Are potential hotspots measured, not guessed?
