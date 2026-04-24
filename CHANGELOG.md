# Changelog

Todos los cambios relevantes de este proyecto se documentan aquí.

El formato está basado en [Keep a Changelog 1.1.0](https://keepachangelog.com/es-ES/1.1.0/) y este proyecto sigue [Semantic Versioning 2.0.0](https://semver.org/lang/es/).

---

## [Unreleased]

### Added
- _(pendiente)_

### Changed
- _(pendiente)_

### Deprecated
- _(pendiente)_

### Removed
- _(pendiente)_

### Fixed
- _(pendiente)_

### Security
- _(pendiente)_

---

## [1.0.0] - 2026-04-24

**Released** — Sistema inicial v1.0.0.

### Added
- **188 agentes AI especializados** distribuidos en 17 categorías: `academic`, `design`, `engineering`, `game-development`, `integrations`, `marketing`, `paid-media`, `product`, `project-management`, `sales`, `scripts`, `spatial-computing`, `specialized`, `strategy`, `support`, `testing`, `examples`.
- **Schema v1.0 formal** (`agents/SCHEMA.md`) con frontmatter validado: `name`, `description`, `version`, `status`, `risk_level`, `tags`, `services`, `last_reviewed`, `reviewed_by`.
- **Linter de seguridad** (`scripts/lint-agent.sh`) que detecta:
  - Prompt injection (`ignore previous instructions`, `disregard system`, `forget all prior rules`).
  - Dominios de exfiltración (`webhook.site`, `pastebin.com`, `transfer.sh`, `ngrok.io`).
  - `curl ... | bash` (command piping peligroso).
  - Variantes destructivas de `rm -rf /`, `rm -rf ~`, `sudo rm`.
  - Ejecución oculta vía `base64`.
- **Auditoría completa** (`scripts/audit-all.sh`) con reporte en markdown del estado de los 188 agentes.
- **Auto-generación del índice** (`scripts/build-index.sh`) que lee frontmatter y escribe `AGENTS_INDEX.md` (49 KB).
- **Migración asistida del frontmatter** (`scripts/migrate-frontmatter.sh`) con modo `dry-run` y flag `--apply`.
- **Instalador idempotente** (`install.sh`) con flags `--yes` y `--uninstall`.
- **Mapa de solapamientos** (`OVERLAP_MAP.md`) con matriz de decisión en 6 zonas de solapamiento entre agentes.
- **100% cleanliness del schema** (desde el baseline del 20.7% del upstream).

### Fixed
- El linter ahora detecta variantes de `rm -rf ~/` correctamente (ver commit `7ee7bd2`).
- `install.sh` genera el índice y el reporte automáticamente tras la instalación.

### Credits
- Fork de [`msitarzewski/agency-agents`](https://github.com/msitarzewski/agency-agents) (MIT).

---

[Unreleased]: https://github.com/infofronijimenez-hue/andale-agents-system/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/infofronijimenez-hue/andale-agents-system/releases/tag/v1.0.0
