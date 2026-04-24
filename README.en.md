# Andale Agents System

> 🇲🇽 **Versión en español:** [README.md](./README.md)

> **188 specialized AI agents for Claude Code + industrialization tooling (lint, audit, build-index, migration).**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agents: 188](https://img.shields.io/badge/agents-188-indigo)](./AGENTS_INDEX.md)
[![Cleanliness: 100%](https://img.shields.io/badge/schema-100%25-brightgreen)](./agents/SCHEMA.md)

---

## What is this?

A library of **188 specialized AI agents** in Markdown format. Each agent has a personality, mission, technical deliverables, and success metrics defined in structured frontmatter. Claude Code reads the `.md`, detects the `name`, and assumes the role — giving you consistent, versioned, auditable agents instead of scattered prompts.

What makes it different from a plain prompt collection: **formal Schema v1.0** validated by a linter, **security scanner** that detects prompt injection and exfiltration domains, **auto-generated catalog** rebuilt from frontmatter on demand, and a **migration tool** with dry-run. The fork of [`msitarzewski/agency-agents`](https://github.com/msitarzewski/agency-agents) took schema compliance from 20.7% to **100%**.

---

## Quick install

```bash
git clone https://github.com/infofronijimenez-hue/andale-agents-system
cd andale-agents-system
./install.sh
```

Copies agents to `~/.claude/agents/` and scripts to `~/.claude/scripts/`. Does **not** touch your `CLAUDE.md` or other config.

Verify: `~/.claude/scripts/audit-all.sh --report` should show `188 agents · 0 critical · 0 warnings`.

---

## Agent categories

| Category | Agents | Examples |
|---|---|---|
| `academic/` | 5 | Anthropologist, Geographer, Historian, Psychologist |
| `design/` | 8 | UI Designer, UX Architect, Brand Guardian, Whimsy Injector |
| `engineering/` | 26 | Backend Architect, Frontend Developer, SRE, Security Engineer |
| `game-development/` | 20 | Unity, Unreal, Godot, Roblox, Blender specialists |
| `marketing/` | 29 | Content Creator, TikTok, LinkedIn, China specialists |
| `paid-media/` | 7 | PPC Strategist, Paid Social, Programmatic Buyer |
| `product/` | 5 | Product Manager, Sprint Prioritizer, Trend Researcher |
| `project-management/` | 6 | Studio Producer, Project Shepherd, Experiment Tracker |
| `sales/` | 8 | Deal Strategist, Discovery Coach, Outbound, Proposal |
| `spatial-computing/` | 6 | visionOS, XR Immersive, macOS Spatial |
| `specialized/` | 28 | Agentic Identity, Compliance Auditor, MCP Builder, ZK Steward |
| `strategy/` | 16 | NEXUS playbooks, runbooks, executive briefs |
| `support/` | 6 | Analytics Reporter, Finance Tracker, Legal Compliance |
| `testing/` | 8 | Reality Checker, Evidence Collector, API Tester |

Full catalog in [`AGENTS_INDEX.md`](./AGENTS_INDEX.md).

---

## Usage

**Activate an agent in Claude Code:**

```
Hey Claude, activate Frontend Developer mode and help me build a React component
```

**Validate a single agent:**

```bash
~/.claude/scripts/lint-agent.sh ~/.claude/agents/engineering/engineering-backend-architect.md
```

Exit codes: `0` = clean, `1` = warnings, `2` = critical (do not use).

**Regenerate the catalog:**

```bash
~/.claude/scripts/build-index.sh   # writes ~/.claude/AGENTS_INDEX.md
```

---

## Schema summary

Each agent has a formal frontmatter contract. See [`agents/SCHEMA.md`](./agents/SCHEMA.md) for full details.

**Required:** `name`, `description` (≤160 chars).

**Recommended:** `version`, `status` (`active | beta | deprecated | superseded`), `risk_level` (`low | medium | high | critical`), `tags`, `services`, `last_reviewed`, `reviewed_by`, `color`, `emoji`, `vibe`.

---

## Security

- **Linter detects critical patterns:** prompt injection (`ignore previous instructions`), exfiltration domains (webhook.site, pastebin.com), `curl … | bash`, `rm -rf`, hidden base64 payloads. Matches inside code blocks ``` ``` are ignored to avoid false positives in didactic security agents.
- **Secret scanning on every PR** via automated audit (`audit-all.sh --fail-on-critical`).
- **Branch protection on `main`** — all changes go through PR + passing lint + passing audit.

---

## "When to use X vs Y" guide

With 188 agents, overlaps are inevitable. See [`agents/OVERLAP_MAP.md`](./agents/OVERLAP_MAP.md) for decision matrices across 6 zones (Architects, Security, Content & Marketing, Orchestrators, Code Quality, Sales).

---

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md). TL;DR: fork → add agent following schema → `./scripts/lint-agent.sh` → `./scripts/build-index.sh` → `./scripts/audit-all.sh` → PR. Must pass lint + audit with exit 0.

---

## Credits

- Base: [`msitarzewski/agency-agents`](https://github.com/msitarzewski/agency-agents) (MIT)
- Industrialization + linting + schema: [`infofronijimenez-hue`](https://github.com/infofronijimenez-hue)
- Powered by [Claude Code](https://claude.com/claude-code)

## License

[MIT](./LICENSE) — use, fork, modify.
