---
name: make-expert-skill
description: 'Create expert-level knowledge skills for GitHub Copilot. Use when asked to "create an expert skill", "make a repo expert", "make an expert for these documents", "scaffold a project knowledge skill", or when building a comprehensive expert skill with bundled reference documents. Works with codebases, document collections (Markdown, Word, PowerPoint, PDF), datasets (Excel, CSV, JSON), or any combination. Generates SKILL.md files plus reference documents following proven patterns. Handles architecture documentation, content structure, troubleshooting guides, data dictionaries, and domain glossaries.'
---

# Make Expert Skill

A meta-skill for creating **expert-level knowledge skills** - comprehensive skills that enable answering questions about a specific software project, document collection, dataset, or domain at any level of detail. Expert skills serve both humans asking conversational questions and AI agents performing tasks.

## When to Use This Skill

* User asks to "create an expert skill" or "make a repo expert"
* User wants to build a comprehensive knowledge skill for a codebase, document set, or dataset
* User wants a skill that can answer questions at any level, from beginner to deep technical
* User is scaffolding a skill with bundled reference documents
* User wants to replicate the pattern of existing expert skills
* User has a collection of documents (Markdown, Word, PowerPoint, PDF) and wants an expert that can answer questions about them
* User has datasets (Excel, CSV, JSON, database exports) and wants an expert that understands the data

## What Makes an Expert Skill Different

Expert skills differ from regular utility skills in several ways:

| Aspect | Regular Skill | Expert Skill |
|--------|--------------|--------------|
| **Scope** | Specific task or tool | Entire project, document collection, or domain |
| **Knowledge** | How to do X | Everything about project Y |
| **Audience** | AI agent performing a task | Humans AND agents at any expertise level |
| **Structure** | Single SKILL.md | SKILL.md + reference documents |
| **Description** | Task-focused triggers | Broad domain keywords |
| **Detail levels** | One level | Multiple (beginner → deep technical) |
| **Response style** | Fixed depth | Adaptive: concise by default, detailed on request |
| **Follow-ups** | None | Suggests related topics and natural next questions |
| **References** | Optional | Required (architecture, structure, troubleshooting) |

## Step-by-Step: Create an Expert Skill

### Step 0: Identify the Source Type

Before exploring, determine what kind of material you are working with. This shapes everything that follows.

| Source Type | Indicators | Primary Goal |
|-------------|------------|--------------|
| **Codebase** | Source files, build configs, test suites, deployment scripts | Explain architecture, help build/test/debug |
| **Document collection** | Markdown, Word, PowerPoint, PDF, HTML, wiki exports | Explain content, find information, summarise, cross-reference |
| **Dataset** | CSV, Excel, JSON, database exports, Parquet files | Explain schema, relationships, meaning of fields, data quality |
| **Mixed** | Combination of the above | Adapt per-section; do not force one lens on everything |

**Context sensitivity is critical.** A folder of Word documents is not a codebase. A CSV file is not documentation. Detect the type and adapt:

* Do not describe documents as "stacks" or "components" - describe them as documents, sections, and topics
* Do not describe datasets as code - describe them as tables, fields, relationships, and measures
* Do not add build commands or troubleshooting for document-only collections
* For mixed sources, clearly separate code sections from documentation sections from data sections

### Step 1: Deep Exploration

Before writing anything, thoroughly explore the source material. What you gather depends on the source type.

#### For codebases

1. **Purpose and overview** - README, docs/index, high-level documentation
2. **Architecture** - How major components connect, data flows, deployment model
3. **Source structure** - Directory tree (2-3 levels deep), key files, entry points
4. **Build system** - CMake/Make/Gradle/npm configuration, build targets, dependencies
5. **Technology stack** - Languages, frameworks, middleware, databases, protocols
6. **Configuration** - Config formats, environment variables, deployment configs
7. **Testing** - Test frameworks, test categories, how to run tests
8. **Deployment** - Packaging, installation, runtime requirements
9. **Key terminology** - Domain-specific terms, acronyms, naming conventions
10. **Troubleshooting patterns** - Common failure modes and debugging approaches

**Exploration commands:**

```bash
# Repository structure
tree -L 3 -d src/
find . -name "CMakeLists.txt" -o -name "package.json" -o -name "*.csproj" | head -30

# Key documentation
cat README.md
ls docs/

# Build configuration
cat src/CMakeLists.txt  # or package.json, build.gradle, etc.

# Dependencies
grep -r "find_package\|dependencies\|requires" src/CMakeLists.txt

# Tests
find . -path "*/test*" -name "*.cpp" -o -name "*.py" -o -name "*.cs" | head -20
```

#### For document collections

1. **Scope and purpose** - What domain do the documents cover? Who is the intended audience?
2. **Document inventory** - File types, count, total size, date ranges
3. **Topic structure** - Major themes, categories, or sections
4. **Relationships** - Cross-references between documents, logical reading order, dependencies
5. **Key terminology** - Domain-specific terms, acronyms, abbreviations
6. **Authorship and versioning** - Who wrote them, how they are maintained, currency
7. **Gaps** - Known missing topics, outdated sections, contradictions

**Exploration commands:**

```bash
# Document inventory
find . -type f \( -name "*.md" -o -name "*.docx" -o -name "*.pptx" -o -name "*.pdf" \) | wc -l
find . -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20

# Topic structure from filenames and folder names
tree -L 3

# Headings in markdown files (topic extraction)
grep -rn '^#' --include="*.md" | head -50
```

#### For datasets

1. **Scope and purpose** - What does this data represent? What questions can it answer?
2. **File inventory** - File types, sizes, row/column counts, date ranges
3. **Schema** - Column names, data types, units of measurement
4. **Relationships** - Foreign keys, join fields, parent-child hierarchies between files/tables
5. **Data quality** - Completeness, known issues, null patterns, valid value ranges
6. **Key terminology** - Field name meanings, coded values, domain abbreviations
7. **Provenance** - Where the data comes from, how often it is refreshed, extraction method

**Exploration commands:**

```bash
# File inventory
find . -type f \( -name "*.csv" -o -name "*.xlsx" -o -name "*.json" -o -name "*.parquet" \) | wc -l

# CSV structure (first file found)
head -5 $(find . -name "*.csv" | head -1)

# Column counts
head -1 *.csv | tr ',' '\n' | wc -l
```

### Step 2: Design the Skill Structure

The structure depends on the source type. Pick the template that best fits.

#### Codebase structure

```text
<project>-expert/
├── SKILL.md                              # Main skill document
└── references/
    ├── core-stacks-and-components.md     # Architecture and components
    ├── codebase-structure.md             # Repository layout and build targets
    ├── build-test-and-deploy.md          # Development workflow
    ├── <domain>-communication.md         # Communication patterns (if applicable)
    ├── troubleshooting.md                # Common issues and fixes
    └── glossary-and-domain-concepts.md   # Domain terminology (if needed)
```

#### Document collection structure

```text
<domain>-expert/
├── SKILL.md                              # Main skill document
└── references/
    ├── content-overview.md               # Document inventory and topic map
    ├── key-topics.md                     # Summaries of major themes/sections
    ├── cross-references.md               # How documents relate to each other
    └── glossary-and-domain-concepts.md   # Domain terminology and abbreviations
```

#### Dataset structure

```text
<domain>-expert/
├── SKILL.md                              # Main skill document
└── references/
    ├── data-dictionary.md                # Schema, field definitions, data types, units
    ├── data-relationships.md             # Foreign keys, joins, hierarchies
    ├── data-quality-and-provenance.md    # Sources, freshness, known issues
    └── glossary-and-domain-concepts.md   # Coded values, domain abbreviations
```

#### Mixed source structure

Combine references from the relevant types above. Keep them clearly separated; do not merge code references and data dictionaries into the same document.

**Choose reference documents based on project complexity:**

| Source Type | Recommended References |
|-------------|----------------------|
| Small library | `codebase-structure.md`, `build-test-and-deploy.md` |
| Medium service | Above + `troubleshooting.md` |
| Large system | Above + `core-stacks-and-components.md`, communication patterns |
| Document collection | `content-overview.md`, `key-topics.md`, `glossary.md` |
| Dataset | `data-dictionary.md`, `data-relationships.md`, `data-quality-and-provenance.md` |
| Domain-heavy (any type) | Add `glossary-and-domain-concepts.md` |
| Multi-variant | Add `configuration.md` or `variant-configuration.md` |

### Step 3: Write the SKILL.md

The main SKILL.md should contain:

#### 3a. Frontmatter

```yaml
---
name: <project>-expert
description: '<WHAT the project is>. Use when asked about <BROAD KEYWORD LIST covering all aspects of the project>. Explains at any level from non-technical overview to deep technical detail.'
license: '<license>'
compatibility: '<key tech requirements>'
metadata:
  project: <Full Project Name>
  organization: <Organization>
  language: English
  expertise-level: expert
  focus-areas: <comma-separated key areas>
---
```

**Description best practices for expert skills:**

* Start with what the project IS
* List ALL major components and concepts as keywords
* Include domain-specific terms users might ask about
* End with "Explains at any level from non-technical overview to deep technical detail"
* Aim for 200-800 characters

#### 3b. Body Sections

Follow this template for the SKILL.md body. **Omit sections that do not apply** to the source type; do not force codebase sections into a document-only skill or vice versa.

```markdown
# <Project> Expert

One-sentence overview. Use this skill to answer questions about <project> at any level.

## When to Use This Skill

* <10-15 bullet points covering all trigger scenarios>
* For codebases, cover: architecture, components, building, testing, deploying, debugging, configuration, code review
* For documents, cover: finding information, summarising, cross-referencing, explaining concepts
* For datasets, cover: schema, field meanings, relationships, data quality, querying

## Communication Style

### Adaptive Detail Level

Match the depth of the answer to what the user is actually asking for:

* **Beginner / "what is"**: Plain-language explanation of purpose and relevance. No jargon. One or two sentences may be enough.
* **Overview / "how does"**: Architecture, components, how they connect. Keep it concise, a short paragraph or diagram.
* **Technical / "how do I"**: Specific APIs, data flows, configuration, commands. Actionable and concrete.
* **Deep technical / "explain in detail"**: Code structure, protocol internals, edge cases. Go deep ONLY when explicitly asked.

**Default to concise.** Start with the simplest useful answer. If the user wants more depth, they will ask. Do not front-load every answer with exhaustive detail.

### Suggesting Follow-Ups

After answering, suggest 1-3 related topics the user might want to explore next. Frame these as natural follow-on questions:

> You might also want to know:
> * How does <related component> interact with this?
> * What configuration options are available for <topic>?
> * How do you troubleshoot <common issue related to the question>?

Only suggest follow-ups that are genuinely related to the question asked, not a generic list.

### Knowledge Boundaries

Be honest about limits. If asked about something outside the documented scope:

* Say so clearly
* Point to where the answer might be found (another team, another repo, external docs)
* Do not speculate or fabricate

## System Overview (codebases)

### What <Project> Does

<Numbered list of 4-6 core responsibilities>

### Architecture Diagram

<Mermaid diagram or ASCII art showing major components and data flows>

### Technology Stack

<Bullet list of languages, frameworks, middleware>

### Key Dependencies

<Table of external dependencies and their purpose>

### Deployment

<Where it runs, how it's installed, key paths>

## Content Overview (document collections)

### Scope

<What these documents cover and who they are for>

### Topic Map

<Mermaid diagram, table, or list showing how topics relate>

### Document Inventory

<Table of documents, their purpose, and currency>

## Data Overview (datasets)

### Scope

<What this data represents and what questions it can answer>

### Schema Summary

<Table of tables/files, key fields, row counts>

### Relationship Diagram

<Mermaid ER diagram or table showing how tables/files connect>

## References

<Links to all reference documents>
```

#### 3c. Critical Content Rules

1. **Relationship diagram** - Always include a Mermaid diagram or ASCII art showing how things connect. For codebases: component architecture. For documents: topic map. For datasets: ER diagram. Prefer Mermaid for flowcharts, sequence diagrams, and ER diagrams; use ASCII art where Mermaid is impractical.
2. **Tables over prose** - Use tables for dependencies, file listings, command references, field definitions
3. **Concrete paths** - Reference actual file paths in the source material
4. **Actionable instructions** - For codebases: copy-pasteable build/test commands. For datasets: example queries. For documents: navigation guidance.
5. **No speculation** - Only document what exists in the source material; admit knowledge limits
6. **Keyword-rich** - The description and "When to Use" sections are discovery mechanisms
7. **Concise by default** - Write reference material so answers can be given at any depth; do not force every answer to be exhaustive
8. **Follow-up guidance** - Include a "Communication Style" section instructing the expert to suggest related topics after answering
9. **Knowledge boundaries** - Explicitly state what the skill knows and what it does not; honesty builds trust
10. **Markdown formatting** - Follow repository markdown formatting rules. Use `*` for unordered lists, fenced code blocks with language tags, and Mermaid for diagrams where appropriate
11. **Context sensitivity** - Do not apply codebase patterns to document collections or datasets. Match the language and structure to the source type.

### Step 4: Write Reference Documents

Each reference document should be self-contained and focused on one aspect. Choose from the templates below based on source type.

#### For codebases

##### core-stacks-and-components.md

Document every major component:

* What it does (purpose)
* Where it lives (file path)
* What it depends on
* Key source files
* Configuration schema (if any)

Use this structure per component:

```markdown
### <Component Name>

**Location:** `path/to/component/`
**Type:** <executable/library/service/etc.>
**Purpose:** <one sentence>

<2-3 sentences of detail>

**Key files:**

* `file1.cpp` - description
* `file2.cpp` - description
```

##### codebase-structure.md

* Full directory tree (ASCII art, 2-3 levels)
* Build target table (target name, location, description)
* Configuration files table
* Packaging metadata

##### build-test-and-deploy.md

* Prerequisites and environment setup
* Build commands (development + production)
* Test commands by category
* CI/CD pipeline (if applicable)
* Deployment procedures

##### troubleshooting.md

Organise by problem category:

```markdown
### <Problem Category>

**Symptom:** <what the user observes>

**Steps:**

1. <diagnostic step>
2. <diagnostic step>
3. <fix>
```

End with a "Useful Diagnostic Commands" table.

#### For document collections

##### content-overview.md

* Document inventory table (filename, format, topic, date, audience)
* Topic map showing how documents relate
* Reading order or navigation guide if applicable

##### key-topics.md

* One section per major theme or subject area
* Brief summary of what is covered and where to find detail
* Cross-references to specific documents and sections

##### cross-references.md

* Relationships between documents (which reference each other, which supersede others)
* Version lineage if documents have evolved
* Known contradictions or gaps

#### For datasets

##### data-dictionary.md

* One section per table or file
* Field name, data type, description, units, valid values, nullable
* Example values for non-obvious fields

Use this structure:

```markdown
### <Table/File Name>

**Source:** <where this data comes from>
**Row count:** <approximate>
**Refresh frequency:** <how often updated>

| Field | Type | Description | Units | Example |
|-------|------|-------------|-------|---------|
| `id` | integer | Primary key | - | 42 |
| `temperature` | float | Ambient temp at measurement time | Celsius | 35.2 |
```

##### data-relationships.md

* Foreign key relationships between tables/files
* Mermaid ER diagram showing connections
* Join fields and cardinality (one-to-one, one-to-many, many-to-many)

##### data-quality-and-provenance.md

* Data sources and extraction methods
* Known quality issues (missing values, outliers, stale records)
* Refresh schedule and latency
* Historical changes to schema

#### For any source type

##### glossary-and-domain-concepts.md

For domain-heavy projects, define all acronyms, domain terms, and project-specific vocabulary.

### Step 5: Validate

* [ ] Folder name matches `name:` field in frontmatter
* [ ] Description is 200-800 chars with broad keyword coverage
* [ ] "When to Use" has 10+ trigger scenarios
* [ ] Relationship diagram is included (Mermaid or ASCII art) - architecture, topic map, or ER diagram as appropriate
* [ ] All referenced file paths exist in the source material
* [ ] Actionable instructions are correct and copy-pasteable (build commands, queries, navigation)
* [ ] Reference documents are linked from SKILL.md
* [ ] Each reference document is self-contained
* [ ] Tables are used for structured data (not prose)
* [ ] No speculation - only documented facts
* [ ] Markdown follows repository formatting rules
* [ ] Source type is correctly identified; codebase patterns are not applied to documents or datasets

## Proven Patterns

Effective expert skills share common structural patterns. These are documented with concrete examples in:

* [Proven Patterns and Examples](./references/proven-patterns-and-examples.md) - Reusable patterns extracted from successful expert skills, covering codebases (multi-variant, microservice, embedded, simulation), document collections, datasets, and more

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Do Instead |
|-------------|-------------|-----------|
| Vague description | Skill won't be discovered | Pack with keywords and trigger scenarios |
| No relationship diagram | Hard to understand system | Always include a Mermaid or ASCII art overview (architecture, topic map, or ER diagram) |
| Prose instead of tables | Hard to scan | Use tables for structured data |
| Speculative content | Misleads users and agents | Only document verified facts; admit uncertainty |
| Missing file paths | Can't navigate source material | Always reference actual paths |
| Single monolithic SKILL.md | Too long, hard to maintain | Split into SKILL.md + references |
| No troubleshooting | Can't help debug | Include common issues (codebases) or gaps/contradictions (documents) |
| No actionable instructions | Can't help users act | Include copy-pasteable commands (codebases), example queries (datasets), or navigation guidance (documents) |
| Always-verbose answers | Overwhelms users asking simple questions | Default to concise; go deep only when asked |
| No follow-up suggestions | Conversation dead-ends | Suggest 1-3 related topics after answering |
| No knowledge boundaries | Fabricates answers when unsure | Explicitly state what the skill knows and doesn't |
| Wrong lens for source type | Confuses documents with code or data | Detect the source type first; adapt structure and language accordingly |
