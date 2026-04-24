# Contribuir a Andale Agents System

Gracias por querer aportar. Este repo vive de agentes bien definidos y código seguro. Antes de abrir un PR, revisa esta guía completa — te ahorra rebotes en review.

> Todo PR pasa por dos filtros automáticos: `lint-agent.sh` (exit 0) y `audit-all.sh --fail-on-critical` (exit 0). Sin eso, no hay merge.

---

## 1. Clonar y entrar al proyecto

```bash
# Fork en GitHub, después:
git clone https://github.com/TU-USUARIO/andale-agents-system
cd andale-agents-system

# Sincroniza tu fork con upstream
git remote add upstream https://github.com/infofronijimenez-hue/andale-agents-system
git fetch upstream
```

---

## 2. Agregar un agente nuevo

### 2.1 Ubicación

El archivo `.md` va en la carpeta de la categoría correcta:

```
agents/engineering/engineering-mi-agente.md
agents/marketing/marketing-mi-agente.md
agents/specialized/specialized-mi-agente.md
...
```

Categorías disponibles: `academic`, `design`, `engineering`, `game-development`, `integrations`, `marketing`, `paid-media`, `product`, `project-management`, `sales`, `scripts`, `spatial-computing`, `specialized`, `strategy`, `support`, `testing`, `examples`.

Si no tienes claro dónde encaja, revisa [`agents/OVERLAP_MAP.md`](./agents/OVERLAP_MAP.md).

### 2.2 Frontmatter

**Obligatorio** (sin esto el linter falla):

```yaml
---
name: mi-agente-descriptivo
description: Una línea clara de ≤160 caracteres explicando qué hace.
---
```

**Recomendado** (el audit te marca warning si falta):

```yaml
---
name: mi-agente-descriptivo
description: Una línea clara de ≤160 caracteres explicando qué hace.
version: 1.0.0
status: active            # active | beta | deprecated | superseded
risk_level: low           # low | medium | high | critical
tags: [engineering, backend, performance]
services: []              # o ej: [{ name: "GitHub", url: "https://github.com", tier: "free" }]
last_reviewed: 2026-04-24
reviewed_by: tu-usuario
---
```

Ver el contrato completo en [`agents/SCHEMA.md`](./agents/SCHEMA.md).

### 2.3 Contenido mínimo del agente

Después del frontmatter, todo agente debe incluir:

- **Vibe** — la personalidad en una frase (ej. "pragmatic, no-BS, ship-it").
- **Color y emoji** — identidad visual (ej. `indigo` + `🏗️`).
- **Misión** — 2-3 líneas que expliquen el rol y cuándo activarlo.
- **Entregables** — lista concreta de lo que produce (código, specs, reportes, etc.).
- **Stack** — tecnologías o servicios que maneja.
- **Métricas de éxito** — cómo se sabe que el agente hizo bien su trabajo.

---

## 3. Correr el linter antes de commit

```bash
./scripts/lint-agent.sh agents/engineering/engineering-mi-agente.md
```

**Exit codes:**
- `0` → limpio, listo para commit.
- `1` → warnings. Revisa manualmente (normalmente es metadata recomendada ausente o servicios fuera de allowlist).
- `2` → **crítico**. No commits hasta resolverlo (prompt injection, comandos destructivos, exfiltración).

---

## 4. Correr el audit completo

Antes de abrir el PR:

```bash
./scripts/audit-all.sh --fail-on-critical
```

El audit lintea los 188+ agentes y escribe un reporte markdown. Con `--fail-on-critical` el script devuelve exit `2` si cualquier agente tiene críticos — útil para integrarlo en CI.

---

## 5. Regenerar el índice

El catálogo `AGENTS_INDEX.md` **no se edita a mano**: se regenera desde el frontmatter.

```bash
./scripts/build-index.sh
```

Commitea el índice actualizado junto con tu agente nuevo. Si no lo haces, CI te lo va a reclamar.

---

## 6. Convenciones de naming

Formato: `categoria-nombre-descriptivo.md`, todo en minúsculas con guiones.

```
Bueno:
  engineering-backend-architect.md
  marketing-tiktok-strategist.md
  specialized-compliance-auditor.md

Malo:
  BackendArchitect.md            # sin categoría prefix, mayúsculas
  engineering_backend.md         # guion bajo en vez de guion
  ai-agent-super-mega-pro.md     # sin categoría, nombre genérico
```

El `name` en el frontmatter debe coincidir con el nombre del archivo (sin `.md`).

---

## 7. Proceso de Pull Request

```
1. Fork → branch desde main
2. git checkout -b feat/marketing-mi-agente
3. Commits pequeños y enfocados (uno por cambio lógico)
4. git push origin feat/marketing-mi-agente
5. Abre el PR usando el template (.github/PULL_REQUEST_TEMPLATE.md)
6. Espera review de maintainer
7. Responde comentarios → push → re-review
8. Merge (squash) cuando lint + audit pasen en CI
```

**Checklist antes de abrir PR:**

- [ ] `./scripts/lint-agent.sh` exit 0 sobre el/los agente(s) modificado(s).
- [ ] `./scripts/audit-all.sh --fail-on-critical` exit 0.
- [ ] `AGENTS_INDEX.md` regenerado.
- [ ] Commits con mensajes claros (ej. `feat(marketing): add TikTok Strategist agent`).
- [ ] Sin archivos `.bak` ni artefactos locales.

---

## 8. Política de versionado

Seguimos [SemVer 2.0.0](https://semver.org/lang/es/) en el repo completo:

- **patch** (`1.0.0 → 1.0.1`) — fixes del linter, audit, docs, typos, bugs en scripts.
- **minor** (`1.0.0 → 1.1.0`) — agentes nuevos, flags adicionales en scripts, nuevas categorías.
- **major** (`1.0.0 → 2.0.0`) — **breaking changes del schema** (campos obligatorios nuevos, renombres, remoción). Requiere migración documentada.

Cada release se documenta en [`CHANGELOG.md`](./CHANGELOG.md) bajo el formato Keep a Changelog.

---

## 9. Code of Conduct

Este proyecto se construye con respeto e inclusividad:

- Críticas al código, nunca a la persona.
- Español e inglés bienvenidos.
- Cero tolerancia a acoso, discriminación o lenguaje excluyente.
- Discusiones técnicas con evidencia, no con opiniones sin fundamento.
- Los maintainers pueden remover comentarios, commits o contribuidores que violen estas normas.

---

## 10. Reportar bugs y proponer agentes

- **Bugs** → abre un issue con el template [`bug_report.md`](./.github/ISSUE_TEMPLATE/bug_report.md). Incluye pasos para reproducir, exit code observado y exit code esperado.
- **Proponer un agente nuevo** → usa el template [`new_agent_request.md`](./.github/ISSUE_TEMPLATE/new_agent_request.md). Describe la misión, entregables, en qué categoría encaja y qué solapamiento tiene con agentes existentes (ver `OVERLAP_MAP.md`).

Para reportes de seguridad sensibles, revisa [`.github/SECURITY.md`](./.github/SECURITY.md) en vez de abrir issue público.

---

## How to contribute in English

1. Fork and clone: `git clone https://github.com/YOUR-USER/andale-agents-system`.
2. Add a new agent under `agents/<category>/<category>-<name>.md` with the required frontmatter (see `agents/SCHEMA.md`).
3. Run `./scripts/lint-agent.sh <file>` (expect exit 0) and `./scripts/audit-all.sh --fail-on-critical`.
4. Regenerate the index with `./scripts/build-index.sh` before committing.
5. Open a PR using the template. Follow SemVer (patch/minor/major) and Keep a Changelog entries.
