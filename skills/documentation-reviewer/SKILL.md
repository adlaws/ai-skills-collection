---
name: documentation-reviewer
description: 'Quality control and assurance for documentation. Use when asked to "review documentation", "do a documentation pass", "check the docs", "audit documentation quality", "proofread the docs", or when performing editorial review of markdown files. Checks informational completeness and accuracy, tonal and phrasing consistency, terminology consistency, appropriate technicality for the target audience, and formatting correctness. Uses the /markdown-formatter skill for formatting rules. Can propose changes for user approval or apply edits directly when instructed.'
---

# Documentation Reviewer

A quality-control skill for reviewing and improving documentation. Performs a comprehensive
editorial pass covering formatting, accuracy, consistency, and audience-appropriateness.

## When to Use This Skill

- User asks to "review documentation", "do a documentation pass", or "check the docs"
- User asks for "proofreading", "editorial review", or "quality check" on docs
- User asks to "audit" or "improve" documentation quality
- User says "update and correct as appropriate" (implies immediate edit permission)

## Prerequisites

- Read the `/markdown-formatter` skill (`references/markdown-formatting-guidelines.md`)
  before starting any review. The formatting rules defined there are the source of truth
  for all formatting checks.
- Read every file in scope before proposing any changes. A full read is essential for
  assessing cross-file consistency.

## Edit Permission

This skill operates in one of two modes:

1. **Review and propose** (default): Report findings and ask the user for confirmation
   before making edits.
2. **Review and edit**: Apply corrections immediately. This mode is activated when the
   user's request includes language such as "update and correct as appropriate",
   "fix what you find", "do a documentation pass and make changes", or any phrasing
   that grants upfront edit permission.

When in doubt, ask before editing.

## Review Process

### Step 1 - Scope

Confirm which files are in scope. If the user specifies a directory or file set, use
that. Otherwise, ask.

### Step 2 - Read the Formatting Rules

Read the `/markdown-formatter` skill and its `references/markdown-formatting-guidelines.md`
file. These rules are the formatting source of truth.

### Step 3 - Read All Files in Scope

Read every in-scope file in full before starting the audit. Do not begin reporting
findings until all files have been read. Cross-file consistency cannot be assessed
from partial reads.

### Step 4 - Audit

Check every file against the criteria below. Organise findings by category, not by file,
so that systemic issues are visible.

### Step 5 - Report or Edit

- In **review and propose** mode: present a summary of findings grouped by category,
  with file and line references. Ask the user which to fix.
- In **review and edit** mode: apply all corrections, then present a summary of what
  was changed.

## Audit Criteria

### 1 - Formatting (via /markdown-formatter)

Apply every rule from the `/markdown-formatter` skill. Key checks:

- [ ] ATX headings (`#`), ordered levels (MD001, MD003)
- [ ] Single H1 per file (MD025)
- [ ] No duplicate heading text within a file (MD024)
- [ ] No heading-ending punctuation (MD026)
- [ ] `*` for unordered lists (MD004)
- [ ] Fenced code blocks with language string (MD040, MD046, MD048)
- [ ] Blank line spacing around headings, lists, and fences (MD022, MD031, MD032)
- [ ] No trailing spaces or multiple consecutive blank lines (MD009, MD012)
- [ ] No bare URLs (MD034)
- [ ] No raw HTML except `<br>` (MD033)
- [ ] No em dashes; use `-`, comma, semicolon, or colon instead
- [ ] 120-character line limit (code blocks and tables exempt) (MD013)
- [ ] Callout blocks use the emoji blockquote style (`> ⚠️`, `> ℹ️`, etc.)
- [ ] Final newline (MD047)

### 2 - Informational Completeness and Accuracy

- [ ] Are there gaps in coverage? Topics mentioned but not explained, sections that
      trail off, or areas where a reader would be left with unanswered questions.
- [ ] Is every factual claim accurate? Cross-reference against source files
      (Dockerfiles, compose files, config files, source code) where possible.
- [ ] Are cross-references and "see also" links present where a reader would
      benefit from them?
- [ ] Do "Related Documentation" or equivalent sections exist where appropriate,
      and are they consistent across peer files?

### 3 - Tonal and Phrasing Consistency

- [ ] Is the voice consistent across all files? (e.g., imperative vs. descriptive,
      second person vs. third person)
- [ ] Is the same concept described the same way everywhere? Watch for synonyms
      that create ambiguity (e.g., "container" vs. "service" vs. "image" used
      interchangeably when they mean different things).
- [ ] Are spelling conventions consistent? (e.g., British English: "initialise",
      "synchronise", "colour"; or American English - but not a mix)
- [ ] Is punctuation style consistent? (e.g., Oxford comma usage, list
      punctuation, sentence-ending in list items)

### 4 - Terminology Consistency

- [ ] Are proper nouns, product names, and technical terms spelled and capitalised
      identically everywhere? (e.g., "Docker Bench" not "docker bench" or
      "DockerBench"; "FMS Bridge" not "fms bridge")
- [ ] Are abbreviations introduced on first use and then used consistently?
- [ ] Do code-formatted terms (backtick-wrapped) match the actual identifiers in
      the codebase?

### 5 - Audience Appropriateness

- [ ] Is the assumed level of technical knowledge consistent across all files?
      One file should not assume deep Docker expertise while a peer file explains
      what a container is.
- [ ] Are explanations pitched at the right level for the target audience?
      Neither too basic (patronising) nor too advanced (alienating).
- [ ] Is jargon either avoided or explained, depending on the audience?

### 6 - Link Validity

- [ ] Do all internal markdown links resolve to existing files?
- [ ] Do all anchor links (e.g., `#some-heading`) resolve to existing headings?
- [ ] Are relative paths correct given each file's location?
- [ ] Are external URLs plausible and well-formed? (Do not fetch them, but check
      for obvious typos or broken patterns.)

## Reporting Format

When reporting findings (in review-and-propose mode), use this structure:

```markdown
## Documentation Review: <scope>

### Formatting
- **file.md line N**: <issue description>

### Informational Accuracy
- **file.md**: <issue description>

### Consistency
- **file.md, other-file.md**: <issue description>

### Audience
- <observation>

### Links
- **file.md line N**: <broken link description>

### Summary
- N formatting issues
- N accuracy issues
- N consistency issues
- N link issues
```

## Tips

- Use `grep` and `awk` for bulk checks (em dashes, bare URLs, list markers, line
  length) before reading files individually. This catches systemic issues fast.
- When checking line length, remember that tables, code blocks, and long URLs are
  exempt.
- When checking link validity, extract all internal links with grep, then verify
  targets exist. This is faster than reading every file looking for broken links.
- For anchor links, remember that MkDocs generates anchors from heading text by
  lowercasing, replacing spaces with hyphens, and stripping punctuation.
