---
name: vuejs-developer
description: 'Use this skill when implementing or refactoring Vue.js frontend behavior in this repository, especially Vue 3 Composition API patterns, reactivity, state flows, accessibility, testing, and performance in JavaScript projects.'
---

# Vue.js Developer Skill

Use this skill for source-level Vue.js frontend changes in this repository.

## Pre-Flight Checklist

- Confirm fallback literals in template expressions are safe (single-line single quotes or template literals).
- Keep reactive boundaries clear (`computed` for derived values, `watch` for side effects only).
- Check loading/empty/error/success UI states and keyboard accessibility before finalizing.

For details, see `.agents/skills/vuejs-developer/references/vuejs-javascript-patterns.md` ("Quick Checklist").

## When to Use This Skill

- User asks for Vue component development or refactoring
- User asks to improve reactivity, state handling, or UI architecture
- User asks for Vue performance, accessibility, or testing improvements
- User asks for Vue 2/Options API to Vue 3 migration guidance

## Scope and Context

- This repository’s Vue work is JavaScript-first (not TypeScript-first).
- Prefer Vue 3 idioms and Composition API patterns where practical.
- Keep changes consistent with existing project structure and style.

## Core Guidance

- Prefer focused components with clear responsibilities.
- Extract reusable logic into composables when behavior is shared.
- Keep props/emits contracts explicit and predictable.
- Use `computed` and `watch` intentionally; avoid broad/deep watchers unless justified.
- Handle loading/empty/error/success states explicitly.
- Favor semantic HTML and keyboard-accessible controls.
- Avoid direct DOM manipulation except when necessary and isolated.
- Prefer deterministic rendering and avoid unnecessary reactive churn.
- Do not split single-quoted fallback literals across lines in Vue template expressions (for example `{{ t(...) || '...` on one line and the rest on another), because Vue may compile this into invalid JavaScript.
- Keep fallback literals on one line, or use template literals (backticks) when line wrapping is possible.
- See `.agents/skills/vuejs-developer/references/vuejs-javascript-patterns.md` ("Template Fallback Literal Safety") for bad-vs-good examples.

## JavaScript Requirement

For JavaScript-specific implementation and test expectations, always consult:

- `.agents/skills/vuejs-developer/references/vuejs-javascript-patterns.md`
- `.agents/skills/javascript-developer/SKILL.md`
- `.agents/skills/javascript-developer/references/javascript-development-guidelines.md`
- `.agents/skills/javascript-developer/references/javascript-testing-guidelines.md`

Use this Vue skill for framework architecture and UI patterns, and the JavaScript skill for language-level coding and testing conventions.

## Migration Guidance

- Support incremental migration from Vue 2/Options API toward Vue 3 Composition API.
- Preserve behavior parity first, then modernize internals.
- Avoid full rewrites when targeted migration provides lower risk.

## Response Style

- Provide practical, working Vue + JavaScript examples.
- Include clear file placement and architectural rationale.
- Call out trade-offs and compatibility constraints where relevant.
- Keep solutions minimal before introducing advanced abstractions.
