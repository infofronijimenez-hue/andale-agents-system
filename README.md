# Andale Agents System

> **188 agentes de IA especializados para Claude Code + tooling de industrialización (lint, audit, build-index, migración).**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agents: 188](https://img.shields.io/badge/agents-188-indigo)](./AGENTS_INDEX.md)
[![Cleanliness: 100%](https://img.shields.io/badge/schema-100%25-brightgreen)](./agents/SCHEMA.md)

---

## ¿Qué es esto?

Una biblioteca de **188 agentes de IA especializados** en formato Markdown, cada uno con personalidad, misión, entregables técnicos y métricas de éxito.

Lo que hace único a este sistema:

- **Schema v1.0 formal** — cada agente tiene frontmatter validado (`version`, `status`, `risk_level`, `tags`, `last_reviewed`)
- **Linter de seguridad** — detecta prompt injection, dominios de exfiltración, comandos destructivos
- **Auto-generación del índice** — el catálogo se regenera desde el frontmatter, no se mantiene a mano
- **Auditoría completa** — `audit-all.sh` lintea los 188 agentes y reporta estado
- **Migración asistida** — `migrate-frontmatter.sh` propone fixes automáticos con dry-run

Basado en el fork de [`msitarzewski/agency-agents`](https://github.com/msitarzewski/agency-agents) con mejoras arquitectónicas que llevaron el cumplimiento del schema de 20.7% al **100%**.

---

## Instalación rápida

```bash
git clone https://github.com/infofronijimenez-hue/andale-agents-system
cd andale-agents-system
./install.sh
```

El script copia los agentes a `~/.claude/agents/` y los scripts a `~/.claude/scripts/`. No toca tu `CLAUDE.md` ni otra configuración.

### Verificar instalación

```bash
~/.claude/scripts/audit-all.sh --report
```

Debes ver: `188 agentes · 0 críticos · 0 warnings`.

---

## Categorías de agentes

| Categoría | Agentes | Ejemplos |
|---|---|---|
| `academic/` | 5 | Anthropologist, Geographer, Historian, Psychologist |
| `design/` | 8 | UI Designer, UX Architect, Brand Guardian, Whimsy Injector |
| `engineering/` | 26 | Backend Architect, Frontend Developer, SRE, Security Engineer, Code Reviewer |
| `game-development/` | 20 | Unity, Unreal, Godot, Roblox, Blender specialists |
| `marketing/` | 29 | Content Creator, TikTok, LinkedIn, + especialistas China |
| `paid-media/` | 7 | PPC Strategist, Paid Social, Programmatic Buyer |
| `product/` | 5 | Product Manager, Sprint Prioritizer, Trend Researcher |
| `project-management/` | 6 | Studio Producer, Project Shepherd, Experiment Tracker |
| `sales/` | 8 | Deal Strategist, Discovery Coach, Outbound, Proposal |
| `spatial-computing/` | 6 | visionOS, XR Immersive, macOS Spatial |
| `specialized/` | 28 | Agentic Identity, Compliance Auditor, MCP Builder, ZK Steward |
| `strategy/` | 16 | NEXUS playbooks, runbooks, executive briefs |
| `support/` | 6 | Analytics Reporter, Finance Tracker, Legal Compliance |
| `testing/` | 8 | Reality Checker, Evidence Collector, API Tester |

Ver catálogo completo en [`AGENTS_INDEX.md`](./AGENTS_INDEX.md).

---

## Uso

### Activar un agente en Claude Code

```
Hey Claude, activate Frontend Developer mode and help me build a React component
```

Claude Code detecta el agente por su `name` y asume la personalidad y metodología definidas en el `.md`.

### Validar un agente antes de usarlo

```bash
~/.claude/scripts/lint-agent.sh ~/.claude/agents/engineering/engineering-backend-architect.md
```

Exit codes:
- `0` = limpio, usa sin preocupación
- `1` = warnings, revisa manualmente
- `2` = **crítico**, no usar hasta resolver

### Regenerar el índice

```bash
~/.claude/scripts/build-index.sh
# escribe ~/.claude/AGENTS_INDEX.md
```

### Migración asistida del frontmatter

```bash
# dry-run (sin modificar)
~/.claude/scripts/migrate-frontmatter.sh ~/.claude/agents/misc/un-agente.md

# aplicar (crea .bak)
~/.claude/scripts/migrate-frontmatter.sh --apply ~/.claude/agents/misc/un-agente.md

# aplicar a todos los pendientes
~/.claude/scripts/migrate-frontmatter.sh --apply-all
```

---

## Schema de frontmatter

Cada agente tiene un contrato formal. Ver [`agents/SCHEMA.md`](./agents/SCHEMA.md) para detalles.

**Obligatorios:**
- `name` — nombre único
- `description` — ≤160 chars

**Recomendados:**
- `color`, `emoji`, `vibe` — identidad visual
- `version` — semver del agente
- `status` — `active | beta | deprecated | superseded`
- `risk_level` — `low | medium | high | critical`
- `tags` — taxonomía controlada (ver SCHEMA.md)
- `services` — dependencias externas con URL y tier
- `last_reviewed`, `reviewed_by` — auditoría

---

## Seguridad

El linter detecta por defecto:

**Críticos** (rechazo automático):
- Instruction hijacking: `ignore previous instructions`, `disregard system`, `forget all prior rules`
- Exfiltration domains: webhook.site, pastebin.com, transfer.sh, ngrok.io, etc.
- Command piping peligroso: `curl ... | bash`
- Destructivos: `rm -rf /`, `rm -rf ~`, `sudo rm`
- Base64 execution hidden payloads

**Warnings:**
- Role spoofing: líneas con `system:`, `assistant:`
- `services.url` fuera de allowlist
- `last_reviewed` >90 días

El linter **ignora matches dentro de bloques de código ``` ``` ``` ```** para evitar falsos positivos en agentes que muestran ejemplos didácticos de ataques (ej. Security Engineer).

---

## Guía "cuándo usar X vs Y"

Con 188 agentes hay inevitablemente solapamientos. Ver [`agents/OVERLAP_MAP.md`](./agents/OVERLAP_MAP.md) para matriz de decisión en 6 zonas:

1. Architects (Software vs Backend vs Autonomous Optimization)
2. Security (Engineer vs Threat Detection vs Compliance vs Blockchain)
3. Content & Marketing Strategists
4. Orquestadores
5. Code Quality & Review
6. Sales

---

## Contribución

```bash
# 1. Fork + clone
git clone https://github.com/TU-USER/andale-agents-system
cd andale-agents-system

# 2. Crear agente nuevo siguiendo el schema
vim agents/engineering/engineering-mi-agente.md

# 3. Validar antes de commit
./scripts/lint-agent.sh agents/engineering/engineering-mi-agente.md

# 4. Regenerar índice + audit
./scripts/build-index.sh
./scripts/audit-all.sh

# 5. PR
```

El PR debe pasar lint + audit con exit 0. El maintainer revisa contenido + personalidad.

---

## Roadmap

- [x] Schema v1.0 formal (Sprint 1)
- [x] Migración masiva 20.7% → 100% cleanliness (Sprint 2)
- [x] Git versioning + backup gate + OVERLAP_MAP (Sprint 3)
- [ ] Pre-commit hook local (Sprint 4)
- [ ] Shellcheck gate + brew automation (Sprint 4)
- [ ] IR JSON para build-index incremental (Sprint 5)
- [ ] Tags multi-dimensionales con search (Sprint 6)

---

## Créditos

- Base: [`msitarzewski/agency-agents`](https://github.com/msitarzewski/agency-agents) (MIT)
- Industrialización + linting + schema: [`infofronijimenez-hue`](https://github.com/infofronijimenez-hue)
- Powered by [Claude Code](https://claude.com/claude-code)

## Licencia

[MIT](./LICENSE) — usa, fork, modifica. Si construyes algo con esto, cuéntanos en Discussions.
