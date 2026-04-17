---
name: research-buddy
description: 'Running investigation log skill. Use when asked to "take notes", "track this investigation", "keep a running log", "document what we found", "add that to the notes", "create an investigation doc", or "update the research notes". Maintains a structured markdown log of an ongoing investigation — appending findings, decisions, root causes, workarounds, and revert instructions as they are discovered. Keeps entries organised by topic with status tracking. Designed for multi-session work where context needs to survive across conversations.'
---

# Research Buddy

A skill for maintaining a living investigation log during exploratory or debugging work. Creates a structured markdown file and keeps it up to date as new findings emerge, scope changes, or items are resolved.

## When to Use This Skill

- User starts an investigation and wants notes kept
- A new finding changes the scope or understanding of an earlier finding
- A workaround is applied and needs a revert path documented
- A root cause is confirmed
- The user says "add that to the notes", "update the log", "note that down"
- Resuming work from a previous session and needing a recap

## Log File Conventions

- Place the log file in the most relevant folder (e.g. `docker_bench/` for a Docker Bench investigation).
- Name it descriptively in kebab-case: `<topic>-investigations.md`
- Never delete entries — mark them as superseded or resolved instead.
- Keep a **Status table** at the top as a quick summary of open/resolved items.

## Log Structure

### Required Sections

```markdown
# <Topic> Investigations

Running log of changes, findings and decisions made while investigating <topic>.

---

## Status

| Topic | Status |
|-------|--------|
| <Item> | **Open** / **In progress** / **Resolved** |

---

## N. <Finding Title>

### Symptom
What was observed.

### Root Cause
What caused it (once known; omit or mark TBD if still unknown).

### Investigation Findings
Structured evidence: test results, commands run, outputs observed.

### Resolution / Workaround
What was done to fix or work around it.

### To Revert
Step-by-step instructions to undo any changes made. Always include this when code or config was modified.

### Status
Open / In progress / Resolved
```

### Optional Sections

- **Longer-term fix needed** — when a workaround was applied but a proper fix is still required
- **Compatibility / Version Notes** — when version relationships are a key part of the investigation

## Workflow

### Starting a New Investigation Log

1. Ask (or infer) the investigation topic and target folder.
2. Create the log file with the standard structure.
3. Populate the first finding from the current conversation context.

### Appending a New Finding

1. Read the existing log to understand current state.
2. Add a new numbered section at the bottom.
3. Update the Status table at the top.
4. Do NOT renumber existing sections — always append.

### Updating an Existing Finding

1. Read the existing log.
2. Edit the relevant section in place (e.g. fill in Root Cause once confirmed, or change status to Resolved).
3. Add a `> Updated <date>:` callout if the change is significant.

### Scope Changes

When a finding turns out to be broader or narrower than first thought, add a `### Scope Update` subsection to the relevant entry rather than rewriting it.

## Quality Rules

- **Always include a "To Revert" section** when config or code was changed as a workaround.
- **Do not summarise away detail** — preserve exact version strings, file paths, and error messages.
- **Mark unknowns explicitly** (e.g. `Root Cause: TBD`) rather than omitting sections.
- **Keep the Status table accurate** — it is the first thing a returning reader sees.
- Link to external resources (Confluence, Jira, GitHub) wherever relevant.
