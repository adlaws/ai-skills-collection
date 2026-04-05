# Vue.js JavaScript Patterns

This reference captures practical Vue 3 + JavaScript implementation patterns for this repository.

## Quick Checklist

* Keep single-quoted fallback literals on one line, or use template literals (backticks) to avoid invalid compiled JS.
* Keep components focused; extract shared behavior into composables instead of duplicating logic.
* Use `computed` for derived state and `watch` for side effects only.
* Explicitly handle loading, empty, error, and success UI states.
* Verify keyboard accessibility and focus behavior for interactive controls.

## Component Patterns

* Keep components small and single-purpose.
* Use `props` for external inputs and `emits` for outward events; avoid mutating props.
* Move shared logic into composables (`useXxx`) when 2+ components need the same behavior.
* Co-locate UI state near the component that owns the interaction.

## Reactivity Patterns

* Use `ref` for primitive reactive state and `reactive` for structured local objects.
* Prefer `computed` for derived state instead of recalculating in template expressions.
* Use `watch` only for side effects (I/O, persistence, imperative APIs).
* Keep watchers narrowly scoped; avoid `deep: true` unless there is no better option.

## Data and Async Patterns

* Represent request lifecycle explicitly: `idle`, `loading`, `success`, `error`.
* Cancel or ignore stale async results to avoid race conditions.
* Keep API calls in composables or thin service layers, not directly scattered across templates.
* Surface meaningful user-facing errors and preserve recoverable state.

## UI and Accessibility Patterns

* Use semantic elements (`button`, `label`, `fieldset`, `table`) over generic wrappers.
* Ensure keyboard operability for all actionable controls.
* Use clear focus behavior for dialogs, menus, and popovers.
* Add ARIA only where native semantics are insufficient.

## Performance Patterns

* Avoid expensive logic directly in templates.
* Use stable keys in `v-for` to minimize unnecessary re-renders.
* Defer heavy work until needed (lazy initialization, conditional rendering).
* Prevent broad reactive dependencies that trigger unrelated updates.

## Testing Patterns

* Test behavior, not implementation details.
* Validate UI states: loading, empty, error, success.
* Prefer deterministic tests with controlled time/data.
* Cover edge cases around async updates and reactive transitions.

## Anti-Patterns to Avoid

* Business logic embedded in large template expressions.
* Line-wrapped single-quoted fallback literals in template expressions (for example `{{ t(...) || '...` split across lines), which can compile into invalid JavaScript.
* Overuse of global state for component-local concerns.
* Broad watchers and ad-hoc side effects spread across components.
* Direct DOM manipulation as a first resort.
* Silent failures without user feedback.

## Template Fallback Literal Safety

* Keep single-quoted fallback literals on one line in template expressions.
* If wrapping is likely (formatter/editor), prefer template literals (backticks) for fallback text.
* Treat fallback literals as compile-sensitive code, not plain wrapped prose.

Bad (can compile to invalid JS):

```vue
{{ t('tools.listen.noLimitsHint') || 'No duration or message limit set. Recording will continue
until manually stopped.' }}
```

Good (single-line single-quoted fallback):

```vue
{{ t('tools.listen.noLimitsHint') || 'No duration or message limit set. Recording will continue until manually stopped.' }}
```

Good (template literal fallback, safer with wrapping):

```vue
{{ t('tools.listen.noLimitsHint') || `No duration or message limit set. Recording will continue until manually stopped.` }}
```

## Related Skills and References

* JavaScript skill entrypoint: `.agents/skills/javascript-developer/SKILL.md`
* JavaScript development guidance: `.agents/skills/javascript-developer/references/javascript-development-guidelines.md`
* JavaScript testing guidance: `.agents/skills/javascript-developer/references/javascript-testing-guidelines.md`
