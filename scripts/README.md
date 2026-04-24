# 🛠️ Scripts — Sistema de Industrialización de Agentes Andale

> Tooling propio para validar, auditar e indexar los ~201 agentes en `~/.claude/agents/`.
> Creado: 2026-04-24 (Sprint 1) | Owner: Froni Jimenez

---

## 📦 Contenido

| Script | Propósito | Ejecución |
|---|---|---|
| `lint-agent.sh` | Lintea 1 agente: valida frontmatter + detecta prompt injection | Por archivo |
| `audit-all.sh` | Corre lint sobre los 201 agentes, reporta stats | Semanal / on-demand |
| `build-index.sh` | Auto-genera `~/.claude/AGENTS_INDEX.md` desde frontmatter | Tras cambios |

**Schema de referencia:** [`~/.claude/agents/SCHEMA.md`](../agents/SCHEMA.md)

---

## 🚀 Primer uso (tras instalación)

```bash
# 1. Hacer ejecutables
chmod +x ~/.claude/scripts/*.sh

# 2. Baseline — audit completo con reporte escrito
~/.claude/scripts/audit-all.sh --report

# 3. Generar índice inicial
~/.claude/scripts/build-index.sh

# 4. Ver reporte
open ~/.claude/AUDIT_REPORT.md
open ~/.claude/AGENTS_INDEX.md
```

---

## 🔍 Uso diario

### Validar un agente antes de usarlo
```bash
~/.claude/scripts/lint-agent.sh ~/.claude/agents/engineering/engineering-security-engineer.md
```

Exit codes:
- `0` = limpio
- `1` = warnings (revisar)
- `2` = críticos (NO usar hasta fix)

### Antes de añadir un agente nuevo de terceros
```bash
# Siempre linteá un agente externo ANTES de copiarlo a ~/.claude/agents/
~/.claude/scripts/lint-agent.sh /ruta/descargada/nuevo-agente.md

# Si exit 0 o 1 revisable → OK copiar
# Si exit 2 → RECHAZAR
```

### Output JSON para integración con otros scripts
```bash
~/.claude/scripts/lint-agent.sh --json agente.md | jq .
```

---

## 🛡️ Qué detecta el linter

### Frontmatter (schema-level)
- ❌ Campos obligatorios faltantes (`name`, `description`, `color`, `vibe`)
- ⚠️ `description` >160 chars
- ⚠️ `status` no-enum (debe ser `active|beta|deprecated|superseded`)
- ⚠️ `risk_level` no-enum (`low|medium|high|critical`)
- ⚠️ `version` no-semver
- ❌ `status=superseded` sin `supersededBy`

### Prompt injection (body-level)
**Críticos (exit 2):**
- Instruction hijacking: `ignore previous instructions`, `disregard system`, `forget everything prior`
- Exfiltration domains: webhook.site, pastebin, transfer.sh, ngrok, requestcatcher, beeceptor, hookb.in, postb.in, pipedream, dnslog, burpcollaborator
- Command piping: `curl ... | bash`, `wget ... | sh`
- Destructive: `rm -rf /`, `rm -rf ~`, `sudo rm -rf`
- Base64 execution: `base64 -d | bash`

**Warnings (exit 1):**
- Role spoofing en líneas: `system:`, `assistant:`
- `curl -X POST` activo sin contexto
- `eval($variable)`
- Base64 >500 chars (payload oculto potencial)

---

## 🔄 Mantenimiento

### Semanal
```bash
~/.claude/scripts/audit-all.sh --report
```
Revisa `AUDIT_REPORT.md` — cualquier crítico nuevo = investigar.

### Tras recibir un agente de fuente externa
1. `lint-agent.sh` sobre el archivo descargado
2. Si exit ≠ 0, revisar manualmente el body
3. Solo entonces `cp` a `~/.claude/agents/<categoría>/`

### Tras modificar SCHEMA.md
1. Actualizar `lint-agent.sh` si hay campos nuevos
2. Re-correr `audit-all.sh --report`
3. Regenerar índice: `build-index.sh`

---

## 🚨 Qué hacer si el linter detecta CRÍTICO

1. **NO usar el agente.** Sácalo de `~/.claude/agents/` temporalmente: `mv agente.md /tmp/`
2. Abre el archivo y localiza el patrón (el linter da número de línea)
3. Evalúa: ¿es un ejemplo didáctico dentro de bloque de código, o una instrucción activa?
4. Si es didáctico (ej. agente Security que muestra ejemplo de ataque): envuelve en code block claro + comentario `# ejemplo didáctico, no ejecutar`
5. Si es activo y malicioso: **no restaurar**; anotar en `~/.claude/QUARANTINE.log`

---

## 🧪 Falsos positivos conocidos

Agentes legítimos que pueden disparar warnings:
- `engineering-security-engineer.md` — muestra patrones de ataque como ejemplo
- `engineering-threat-detection-engineer.md` — reglas SIEM referencian IoCs
- `specialized-compliance-auditor.md` — puede citar comandos sensibles

Estos agentes son válidos; el linter hace flag defensivo pero revísalos al menos 1 vez.

---

## 📈 Roadmap (sprints siguientes)

| Sprint | Estado | Entregable |
|---|---|---|
| 1 | ✅ | Schema + linter + build-index + audit-all |
| 2 | ✅ | Migración asistida (99.5% → 100% cleanliness) |
| 3 | ✅ | Git repo + .bak cleanup + shellcheck (bash -n) + backup-claude gate + OVERLAP_MAP |
| 4 | ⏳ | Git hook pre-commit + shellcheck real (requiere brew) |
| 5 | ⏳ | IR JSON (`build/agents.json`) + caching incremental |
| 6 | ⏳ | Fork privado `agency-agents-pinned` + bump semver automatizado |

## 🔗 Integración con backup-claude.sh

En Sprint 3 se modificó `~/backup-claude.sh` (fuera de este repo) para:

1. **Gate pre-backup**: corre `audit-all.sh --fail-on-critical` antes de respaldar
2. **Regenera índice**: corre `build-index.sh` si audit OK
3. **Copia al backup**: AGENTS_INDEX.md, AUDIT_REPORT.md, SCHEMA.md, TRIGGERS_DICTIONARY.md, scripts/, agents/

El script live está en `~/backup-claude.sh`. Si lo modificas, considera también respaldar el diff en este repo con `cp ~/backup-claude.sh ~/.claude/scripts/backup-claude-snapshot.sh` para historial.

---

## 🔒 Seguridad del propio tooling

- Todos los scripts usan `set -euo pipefail`
- Sin `curl | bash`, sin `eval` dinámico
- Quoting defensivo en todas las expansiones
- Atomic writes con `mktemp` + `mv` en `build-index.sh`
- Sin escritura fuera de `~/.claude/`

Probar manualmente con shellcheck:
```bash
shellcheck ~/.claude/scripts/*.sh
```
