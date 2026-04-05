````skill
---
name: ha-integration-developer
description: >
  Use this skill when developing, maintaining, or releasing a Home Assistant
  custom integration distributed via HACS.  It covers integration file
  structure, manifest requirements, config flow design, entity patterns,
  HACS compatibility, semantic versioning, GitHub release and tag
  management, and lessons learned from this repository.  Reference this
  skill when asked to "create an integration", "add an entity", "bump the
  version", "make a release", or any Home Assistant integration development
  task.
---

# Home Assistant Integration Developer

## When to Use

- Creating or scaffolding a new Home Assistant custom integration.
- Adding entities (climate, switch, sensor, etc.) to an integration.
- Implementing or modifying a config flow.
- Preparing a release — bumping versions, creating tags, publishing to HACS.
- Reviewing or refactoring integration code for HA best practices.
- Troubleshooting HACS validation or `hassfest` failures.

## Prerequisites

- Familiarity with the `python-developer` skill for Python coding standards.
- Familiarity with the `python-reviewer` skill for code review checklists.
- Familiarity with the `markdown-formatter` skill for documentation.
- Home Assistant 2024.1+ (HA evolves rapidly — check the developer docs for
  breaking changes when targeting a specific minimum version).

---

## Part 1 — Integration File Structure

### 1.1 Required Layout

HACS requires exactly **one** integration directory under
`custom_components/`:

```text
custom_components/<domain>/
├── __init__.py          # Entry point — async_setup_entry / async_unload_entry
├── manifest.json        # Integration metadata (REQUIRED)
├── config_flow.py       # UI configuration flow
├── const.py             # Domain constants
├── strings.json         # Default UI strings
├── translations/
│   └── en.json          # English translations
├── climate.py           # Entity platforms (one file per platform)
├── switch.py
├── sensor.py
└── brand/
    ├── icon.png         # Square icon (min 256×256, preferably 512×512)
    └── logo.png         # Optional landscape logo
```

### 1.2 Mandatory Files

| File | Purpose |
|------|---------|
| `__init__.py` | Integration setup/teardown; defines `async_setup_entry` and `async_unload_entry`. |
| `manifest.json` | All metadata — domain, name, version, codeowners, etc. |
| `config_flow.py` | UI config flow (if `config_flow: true` in manifest). |
| `const.py` | Shared constants — domain name, config keys, protocol values. |
| `strings.json` | Default translation strings for the config flow. |

### 1.3 Brand Assets

HACS requires at least an `icon.png` in a `brand/` directory inside
the integration folder, or matching branding in the
[home-assistant/brands](https://github.com/home-assistant/brands)
repository.

---

## Part 2 — manifest.json

### 2.1 Required Fields for HACS

```json
{
    "domain": "my_integration",
    "name": "My Integration",
    "codeowners": ["@your_github_username"],
    "config_flow": true,
    "dependencies": [],
    "documentation": "https://github.com/user/repo",
    "issue_tracker": "https://github.com/user/repo/issues",
    "iot_class": "local_push",
    "requirements": [],
    "version": "0.1.0"
}
```

| Field | Notes |
|-------|-------|
| `domain` | Lowercase with underscores; must match the directory name. |
| `name` | Human-readable name shown in the HA UI and HACS. |
| `version` | **Required** for custom integrations (not for core). Must be valid SemVer or CalVer recognised by [AwesomeVersion](https://github.com/ludeeus/awesomeversion). |
| `codeowners` | GitHub usernames prefixed with `@`. |
| `config_flow` | Set to `true` if the integration has a `config_flow.py`. |
| `documentation` | URL to the user-facing documentation. |
| `issue_tracker` | URL to the GitHub issues page. |
| `iot_class` | One of: `local_push`, `local_polling`, `cloud_push`, `cloud_polling`, `assumed_state`, `calculated`. |
| `requirements` | PyPI packages the integration depends on. Custom integrations should not list packages already in HA core's `requirements.txt`. |
| `dependencies` | Other HA integration domains that must be loaded first. |
| `integration_type` | Recommended: `hub`, `device`, `service`, `entity`, `helper`. Defaults to `hub` if omitted. |

### 2.2 Consistency Checks

- The `domain` field **must** match the directory name under
  `custom_components/`.
- The `documentation` and `issue_tracker` URLs **must** point to the
  correct repository. A common mistake is leaving placeholder URLs from
  a template or using a shortened repo name.
- The `version` field **must** be updated whenever a new release is
  published. Keep `manifest.json` and the git tag in sync.

---

## Part 3 — hacs.json

The HACS manifest lives at the repository root:

```json
{
    "name": "My Integration",
    "render_readme": true
}
```

| Field | Notes |
|-------|-------|
| `name` | **Required** — the display name in HACS. |
| `render_readme` | When `true`, HACS renders `README.md` on the integration page. Set `false` to render nothing, or omit the key for default behaviour. |
| `content_in_root` | Set to `true` only if integration files live at the repo root (unusual). |
| `country` | ISO country codes if the integration is region-specific. |

---

## Part 4 — Config Flow Best Practices

### 4.1 Structure

```python
from homeassistant.config_entries import ConfigFlow, ConfigFlowResult

class MyConfigFlow(ConfigFlow, domain=DOMAIN):
    VERSION = 1

    async def async_step_user(
        self, user_input: dict[str, Any] | None = None
    ) -> ConfigFlowResult:
        errors: dict[str, str] = {}
        if user_input is not None:
            # Validate input
            # Set unique ID and abort if already configured
            await self.async_set_unique_id(unique_value)
            self._abort_if_unique_id_configured()
            return self.async_create_entry(title=name, data=user_input)

        return self.async_show_form(
            step_id="user", data_schema=schema, errors=errors
        )
```

### 4.2 Key Rules

- **Always set a unique ID** — use the entity ID, MAC address, serial
  number, or other stable identifier. Call `self._abort_if_unique_id_configured()`
  to prevent duplicate entries.
- **Validate input** in the config flow, not during integration setup.
  Check that referenced entities exist, devices are reachable, etc.
- **Use selectors** (`EntitySelector`, `DeviceSelector`, `TextSelector`)
  for a native HA UI experience.
- **Provide translations** — define all step titles, descriptions,
  field labels, errors, and abort reasons in `strings.json`.
- **Config entry migration** — set `VERSION` on the flow class. If the
  schema changes, bump the version and implement `async_migrate_entry`
  in `__init__.py`.

### 4.3 strings.json / translations

```json
{
    "config": {
        "step": {
            "user": {
                "title": "Set up My Integration",
                "data": {
                    "name": "Display name",
                    "device": "Device"
                }
            }
        },
        "error": {
            "entity_not_found": "Entity not found"
        },
        "abort": {
            "already_configured": "This device is already configured"
        }
    }
}
```

Copy `strings.json` content into `translations/en.json` (Home Assistant
uses the translations directory at runtime).

---

## Part 5 — Entity Implementation Patterns

### 5.1 General Rules

- Inherit from the appropriate HA base class (`ClimateEntity`,
  `SwitchEntity`, `SensorEntity`, etc.).
- Use `_attr_*` class attributes for static properties (reduces
  boilerplate).
- Set `_attr_has_entity_name = True` and provide `_attr_name` for
  proper entity naming under the device.
- Set `_attr_unique_id` to a deterministic, stable string.
- Call `self.async_write_ha_state()` after updating attributes.

### 5.2 Shared State Pattern

When multiple entities share state (e.g. a climate entity and a switch
entity both need the current AC state), use a shared dataclass stored
in `hass.data[DOMAIN][entry_id]`:

```python
@dataclass
class MyIntegrationData:
    state: MyDeviceState
    device_entity: str

hass.data[DOMAIN][entry.entry_id] = MyIntegrationData(...)
```

Both entity platforms retrieve this object during their
`async_setup_entry` and reference the same mutable state.

### 5.3 Service Calls

When sending commands to a device, always:
- Log the command at `DEBUG` level before sending.
- Catch exceptions and log at `ERROR` / `WARNING`; do not let a
  failed send crash the entity.
- Update HA state optimistically, then confirm if possible.

---

## Part 6 — Versioning and Releases

### 6.1 Semantic Versioning

Use [SemVer](https://semver.org/) — `MAJOR.MINOR.PATCH`:

| Bump | When |
|------|------|
| **MAJOR** | Breaking changes — config entry schema change requiring migration, removed features. |
| **MINOR** | New features, new entity types, new config options — backwards compatible. |
| **PATCH** | Bug fixes, documentation improvements — backwards compatible. |

### 6.2 Version Locations

The version number appears in **one** authoritative place:

| File | Field | Example |
|------|-------|---------|
| `custom_components/<domain>/manifest.json` | `"version"` | `"0.2.0"` |

### 6.3 Version Bump Workflow

When the version number in `manifest.json` is changed:

1. **Commit** the version bump with a message like
   `chore: bump version to 0.2.0`.
2. **Ask the user** if they would like a git tag created for this
   version. If yes:
   ```bash
   git tag -a v0.2.0 -m "Release v0.2.0"
   git push origin v0.2.0
   ```
3. **Remind the user** that HACS displays version names from **GitHub
   Releases**, not just tags. A release should be created on GitHub
   (either manually or via GitHub Actions) from the new tag for HACS
   to show a clean version string instead of a commit hash.

### 6.4 IMPORTANT — Always Prompt on Version Change

**Whenever you modify the `version` field in `manifest.json`, you MUST
ask the user:**

> "The version has been bumped to X.Y.Z. Would you like me to create a
> git tag `vX.Y.Z` for this release?"

If the user confirms, create the annotated tag and push it. Then remind
them to create a GitHub Release from the tag for HACS visibility.

### 6.5 GitHub Release Best Practices

- Use the tag name as the release title (e.g. `v0.2.0`).
- Include a changelog in the release description summarising what
  changed.
- Mark pre-release versions appropriately (e.g. `0.1.0-beta.1`).
- HACS shows the 5 most recent releases plus the default branch.

---

## Part 7 — HACS Compatibility Checklist

### 7.1 Repository Requirements

| Requirement | Details |
|-------------|---------|
| **Public GitHub repo** | Must not be private or archived. |
| **Repository description** | Set in GitHub repo settings. |
| **Issues enabled** | GitHub issues must be turned on. |
| **Topics defined** | Add relevant GitHub topics (e.g. `home-assistant`, `hacs`, `custom-component`). |
| **Single integration** | Only one subdirectory under `custom_components/`. |
| **`hacs.json` at root** | Must contain at least `"name"`. |
| **`manifest.json`** | Must contain `domain`, `name`, `version`, `documentation`, `issue_tracker`, `codeowners`. |
| **Brand assets** | `brand/icon.png` inside the integration directory. |
| **At least one release** | For inclusion in the HACS default list, a GitHub Release (not just a tag) is required. |

### 7.2 GitHub Actions for Validation

Add these workflows to `.github/workflows/`:

**HACS Validation** (`hacs.yml`):
```yaml
name: HACS Validation
on: [push, pull_request]
jobs:
  hacs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hacs/action@main
        with:
          category: integration
```

**Hassfest** (`hassfest.yml`):
```yaml
name: Hassfest
on: [push, pull_request]
jobs:
  hassfest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: home-assistant/actions/hassfest@master
```

### 7.3 Common HACS Validation Failures

| Failure | Cause | Fix |
|---------|-------|-----|
| Missing `version` in manifest | Custom integrations require it | Add `"version": "X.Y.Z"` |
| No brand assets | Missing `icon.png` | Add `brand/icon.png` to integration dir |
| Multiple integrations | More than one dir under `custom_components/` | Keep exactly one |
| No releases | HACS default list requires a release | Create a GitHub Release |
| Manifest URL mismatch | `documentation`/`issue_tracker` point to wrong repo | Fix the URLs |

---

## Part 8 — Testing

### 8.1 Test Structure

```text
tests/
├── conftest.py             # Shared fixtures
├── test_config_flow.py     # Config flow tests (REQUIRED for core)
├── test_climate.py         # Entity platform tests
├── test_switch.py
└── test_init.py            # Setup/teardown tests
```

### 8.2 Testing Without Home Assistant Installed

For custom integrations that can be tested outside of a full HA
environment, stub the HA package imports:

```python
import sys
import types

# Create minimal stub package
pkg = types.ModuleType("my_integration")
pkg.__path__ = [str(path_to_integration)]
pkg.__package__ = "my_integration"
sys.modules["my_integration"] = pkg
```

This allows testing pure-Python codec/protocol logic without installing
Home Assistant.

### 8.3 Test Requirements

- All config flow paths must be tested (success, error, abort).
- Entity state changes must be tested.
- Service calls and their side effects must be tested.
- Round-trip encoding/decoding must be tested if the integration
  involves protocol encoding.

See the `python-developer` skill's testing guidelines for detailed
pytest conventions.

---

## Part 9 — Lessons Learned from This Repository

These are specific patterns and pitfalls discovered during the
development of the `fujitsu_ac_ir` integration in this repository.

### 9.1 Self-Contained Integration Code

The HA integration under `custom_components/` duplicates the standalone
library code rather than importing from `src/`. This is intentional —
a HACS integration must be a single self-contained directory that works
when dropped into any HA installation. Never import from paths outside
`custom_components/<domain>/`.

### 9.2 URL Consistency

Ensure `manifest.json` fields `documentation` and `issue_tracker` point
to the **correct** GitHub repository URL. If the repo is renamed, these
must be updated. The same applies to HACS installation instructions in
`README.md` and `DETAILS.md`.

### 9.3 Full State Commands

For IR-based integrations (or any stateless protocol), encode the
**complete device state** in every command rather than tracking
incremental changes. This avoids state drift between the integration and
the physical device.

### 9.4 Shared Mutable State Between Entities

When multiple entity platforms (e.g. `climate.py` and `switch.py`) need
to read and write the same device state, store a shared `@dataclass`
instance in `hass.data[DOMAIN][entry_id]`. Both platforms reference
the same object, so changes are immediately visible.

### 9.5 Graceful IR Send Failures

IR blaster commands can fail silently. Always wrap `hass.services.async_call`
in a try/except, log the failure, but do **not** crash the entity. The
user can retry.

### 9.6 Outside-Quiet as a Separate Entity

Features that are boolean toggles orthogonal to the main entity (like
outside-unit quiet mode) are better exposed as separate `switch` entities
rather than crammed into the climate entity's attributes. This provides
a cleaner HA UI and allows automation triggers.

### 9.7 Documentation Typos and Completeness

Proofread documentation carefully. Markdown rendering issues (e.g.
"natire" instead of "nature", missing "not" changing the meaning of a
sentence) confuse users. Use the `markdown-formatter` skill when editing
docs.

### 9.8 Broadlink Entity Selection

Use `EntitySelector(EntitySelectorConfig(domain="remote"))` in the
config flow to let users pick the correct Broadlink remote entity.
This is more user-friendly than a free-text entity ID field.

---

## Part 10 — Documentation for HA Integrations

### 10.1 Required Documentation Files

| File | Audience | Content |
|------|----------|---------|
| `README.md` | End users (GitHub + HACS) | Installation, features, dashboard card examples, troubleshooting. |
| `DETAILS.md` | (Optional) HACS detail page | Extended info rendered by HACS if `render_readme` is `true`. |
| `docs/integration.md` | End users | Detailed integration-specific usage and configuration. |

### 10.2 Documentation Checklist

- [ ] Prerequisites (hardware, HA version, dependencies)
- [ ] HACS installation instructions
- [ ] Manual installation instructions
- [ ] Configuration flow walkthrough
- [ ] Supported features table
- [ ] Lovelace card examples (minimal + customised)
- [ ] Troubleshooting section
- [ ] Limitations section
- [ ] Removal instructions
- [ ] Changelog or link to releases

Use the `markdown-formatter` skill for consistent formatting.

---

## Quick Reference Commands

```bash
# Run tests
python -m pytest tests/ -v

# Run pylint
pylint custom_components/my_domain/

# Run mypy
mypy custom_components/my_domain/

# Create an annotated version tag
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin v0.2.0

# Validate HACS compatibility locally (requires Docker)
docker run --rm -v $(pwd):/github/workspace ghcr.io/hacs/action:main
```

---

## References

- [HA Developer Docs — Integration Manifest](https://developers.home-assistant.io/docs/creating_integration_manifest)
- [HA Developer Docs — Config Flow](https://developers.home-assistant.io/docs/config_entries_config_flow_handler)
- [HA Developer Docs — Development Checklist](https://developers.home-assistant.io/docs/development_checklist)
- [HA Developer Docs — Integration Quality Scale](https://developers.home-assistant.io/docs/core/integration-quality-scale)
- [HACS — Publishing an Integration](https://hacs.xyz/docs/publish/integration/)
- [HACS — General Publishing Requirements](https://hacs.xyz/docs/publish/start/)
- [HACS — Include in Default Repositories](https://hacs.xyz/docs/publish/include/)
- [HACS — GitHub Action for Validation](https://github.com/hacs/action)
- [Hassfest GitHub Action](https://github.com/home-assistant/actions#hassfest)
- [Blueprint — HACS Integration Template](https://github.com/custom-components/blueprint)
- [Cookiecutter HA Custom Component](https://github.com/oncleben31/cookiecutter-homeassistant-custom-component)
- [SemVer Specification](https://semver.org/)
- Project skill: `python-developer` — Python coding standards
- Project skill: `python-reviewer` — Python code review checklist
- Project skill: `markdown-formatter` — Documentation formatting

````
