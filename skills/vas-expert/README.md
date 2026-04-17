# VAS Expert Skill — Complete Documentation

## Overview

The **`vas-expert`** skill is a comprehensive knowledge base for the **Vehicle Awareness System (VAS)** repository. It provides in-depth expertise on VAS architecture, components, configuration, and best practices at multiple expertise levels.

## Skill Structure

```
.agents/skills/vas-expert/
├── SKILL.md                           # Main skill file with frontmatter and full documentation
├── references/                        # Detailed technical reference documents
│   ├── pose-stack-architecture.md    # Understanding VAS positioning system
│   ├── dds-routing.md                # DDS domain design and troubleshooting
│   ├── driver-integration.md         # Guidelines for adding new sensors
│   ├── testing-strategy.md           # Unit/integration/system testing approaches
│   ├── variant-configuration.md      # Configuration for VAS, Precision, AHT variants
│   └── troubleshooting.md            # Common problems and solutions
└── templates/                         # Scaffolding scripts for new development
    ├── add_new_driver.sh             # Generate driver skeleton
    └── add_new_stack.sh              # Generate stack skeleton
```

## What This Skill Provides

### 1. **Authoritative VAS Knowledge**

- **Architecture overview** — How VAS components fit together
- **Three variants explained** — VAS, VAS:Precision, VAS:AHT and their differences
- **Component relationships** — How drivers, stacks, and libraries interact
- **DDS data flows** — Understanding pub/sub communication patterns

### 2. **Technical Depth at Multiple Levels**

The skill explains concepts for:
- **Beginners** → "What is RTK GNSS-INS? Why does VAS care about accuracy?"
- **Developers** → "How do I integrate a new sensor? Write tests for my stack?"
- **Architects** → "What are the domain boundaries? How do we scale to 100 vehicles?"
- **Operators** → "Why is pose stale? How do I debug DDS connectivity?"

### 3. **Practical Development Guidance**

- Driver integration checklist with code examples
- Stack development patterns and templates
- Testing strategies (unit → integration → system)
- Troubleshooting guide with root cause analysis

### 4. **Configuration & Deployment**

- Step-by-step variant configuration
- Build commands and expected outputs
- Hardware requirements for each variant
- CI/CD pipeline understanding

## How to Use This Skill

### Via GitHub Copilot Chat

Ask questions with natural language that triggers this skill:

```
"What is VAS and how does it work?"
"Explain the pose stack architecture"
"I'm getting stale asset poses in FMS—how do I debug?"
"Show me how to add a new GNSS driver"
"What are the differences between VAS variants?"
"How do DDS publishers work in VAS?"
"Walk me through the testing strategy"
```

The skill will:
✓ Provide authoritative, fact-based answers
✓ Admit when uncertain rather than speculate
✓ Link to relevant reference documents
✓ Suggest constructive next steps
✓ Offer code examples when appropriate

### Via Direct Reference Files

Navigate to `references/` for in-depth documentation:

- **`pose-stack-architecture.md`** → Understand positioning system
- **`dds-routing.md`** → Learn DDS domain design + debugging
- **`driver-integration.md`** → Follow checklist for new drivers
- **`testing-strategy.md`** → See testing pyramid and examples
- **`variant-configuration.md`** → Configure VAS for your use case
- **`troubleshooting.md`** → Resolve common deployment issues

### Via Template Scripts

Use templates to scaffold new components:

```bash
# Create a new driver:
bash templates/add_new_driver.sh WheelSpeedSensor
# Generates: drivers/wheel-speed-sensor-driver/ with CMakeLists, header, impl, tests

# Create a new stack:
bash templates/add_new_stack.sh MotionPlanner
# Generates: stacks/motion-planner-stack/ with full structure
```
### Networking Questions?

For networking topology, port allocation, bandwidth planning, RTK connectivity, and firewall rules, see **`references/networking-requirements.md`**.
## Knowledge Domains Covered

| Domain | Documents | Expertise |
|--------|-----------|-----------|
| **Positioning** | pose-stack-architecture.md | Deep: Kalman filters, covariance, RTK corrections |
| **Networking** | networking-requirements.md | Deep: Ports, bandwidth, RTK/NTRIP, DDS topology, firewall |
| **DDS/Comms** | dds-routing.md | Deep: Domain design, QoS, reliability patterns |
| **Driver Dev** | driver-integration.md | Deep: Hardware abstraction, ISR safety, testing |
| **Testing** | testing-strategy.md | Deep: Unit/integration/system testing pyramid |
| **Configuration** | variant-configuration.md | Deep: All three VAS variants, XML configs |
| **Troubleshooting** | troubleshooting.md | Broad: 20+ common issues with root causes |
| **Architecture** | SKILL.md (overview) | High-level: Component organization, data flows |

## Limitations & Honesty

This skill **will admit when it doesn't know:**

- ❌ Proprietary OCS/FMS internals (not in VAS repo)
- ❌ Real-world GPS-denied scenarios (beyond documented INS fallback)
- ❌ Specific customer site configurations
- ❌ Future roadmap features
- ❌ Non-VAS external projects

When encountering unknown territory, the skill will:
1. State clearly what it doesn't know
2. Suggest where to find the answer
3. Offer constructive alternatives or related information

## Key Updates & Maintenance

This skill is based on:
- **VAS repository analysis** (drivers, libraries, stacks)
- **VAS documentation** (docs/index.md, design notes)
- **RTI Connext DDS patterns** (best practices for pub/sub)
- **C++17 development practices** (memory safety, modern idioms)

**To keep this skill current:**

1. Monitor VAS repository changes (new drivers, stacks, libraries)
2. Update reference docs when architecture evolves
3. Add new troubleshooting entries as issues are discovered
4. Enhance templates with lessons learned

## Integration with Other Skills

This skill **complements** existing repository skills:

- **`cpp17-developer`** ← Use for C++ implementation details
- **`cpp17-code-reviewer`** ← Use for code review of drivers/stacks
- **`markdown-formatter`** ← Use for documentation formatting
- **VAS Expert** ← Use for VAS-specific architecture & guidance

## Example Workflows

### Workflow 1: Add New Sensor

```
1. Ask: "How do I add a wheel speed sensor to VAS?"
   → Skill directs to driver-integration.md

2. Use template: bash templates/add_new_driver.sh WheelSpeedSensor
   → Generates scaffold

3. Ask: "Show me how to publish data safely from ISR"
   → Skill provides code example, explains queue pattern

4. Ask: "How do I test this driver?"
   → Skill references testing-strategy.md, shows unit test example

5. Ask: "Is my driver ready for integration?"
   → Skill uses driver-integration.md checklist to review
```

### Workflow 2: Troubleshoot Deployment

```
1. Symptom: "Asset pose is stale in FMS after deployment"

2. Ask: "How do I debug stale poses?"
   → Skill references troubleshooting.md, walk through diagnosis steps

3. Follow diagnostic steps:
   - Check GNSS health events
   - Verify localiser running
   - Confirm DDS connectivity
   - Check routing service

4. Ask: "What if the issue is domain mismatch?"
   → Skill explains DDS domain IDs, shows config fix
```

### Workflow 3: Understand Variant Differences

```
1. Ask: "Should we use VAS or VAS:Precision for surveying?"
   → Skill compares variants (variant-configuration.md)

2. Ask: "What hardware does Precision need?"
   → Skill lists Motium, A470, additional compute

3. Ask: "How do boundary interactions work?"
   → Skill explains boundary detection architecture

4. Ask: "Show me a sample boundary config"
   → Skill provides XML example from variant-configuration.md
```

## Quick Reference

### VAS Variants at a Glance

| Feature | VAS | Precision | AHT |
|---------|-----|-----------|-----|
| GNSS-INS | ✓ | ✓ | ✗ (OCS) |
| Wheel Encoders | ✗ | ✓ | ✗ |
| Boundary Detection | ✗ | ✓ | ✗ |
| Onboard Compute | Medium | High | Minimal |

### Core Components

- **Drivers** — GNSS, Motium, CAN bridges
- **Libraries** — Mathematics, DDS utilities, HTTP client, robot model
- **Stacks** — Pose, notification, boundary detection, precision advisor
- **Interface** — VAS interface stack (DDS bridge to FMS)

### Key DDS Topics

| Topic | Direction | Variant | Content |
|-------|-----------|---------|---------|
| `/asset_pose` | Out | All | Vehicle position + heading |
| `/health_event` | Out | All | System health / faults |
| `/boundary_interaction` | Out | Precision | Vehicle bounds vs. zone |
| `/gnss_rtk_corrections` | Out | VAS/Precision | RTK data to fleet |
| `/virtual_boundary_control` | In | All | Commands from FMS |

---

**Created:** April 15, 2026
**Skill Status:** Ready for use
**Expertise Level:** Expert (VAS developers and operators)
**Maintainer:** See CODEOWNERS in VAS repository
