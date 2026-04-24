# Rotación y Mantenimiento del Sistema

> Cómo rotar credenciales, actualizar agentes, sincronizar upstream, deprecar y auditar.
> Owner: Froni Jimenez · Última revisión: 2026-04-24 · v1.0.0

---

## A. Rotación de credenciales (si tokens se comprometen)

**Cuándo hacerlo:** push accidental de `.env`, repo privado expuesto, sospecha de fuga, colaborador que deja el equipo.

### A.1 GitHub PAT (Personal Access Token)

1. Ir a https://github.com/settings/tokens
2. Localizar el token comprometido → click **Delete** (revoca inmediato)
3. **Generate new token (classic)** o **fine-grained**
4. Scopes mínimos: `repo`, `workflow` (solo si lo necesitas), `read:packages`
5. Expiración: **90 días máximo** (nunca "no expiration")
6. Copiar el token una sola vez y guardarlo en el gestor de secretos (1Password / macOS Keychain)
7. Actualizar donde se usa: `~/.gitconfig`, GitHub Actions secrets, `.env` local, Vercel env vars

### A.2 GitHub CLI re-auth

```bash
gh auth logout
gh auth login
# Elegir: GitHub.com → HTTPS → Login with a web browser
gh auth status   # verificar que quedó bien
```

### A.3 Si el repo privado `master-backup-skills-agents` se expone

**Todos** los tokens que aparezcan en los archivos sincronizados deben rotarse. Revisar:

1. `~/.claude.json` — buscar `"token"`, `"apiKey"`, `"secret"`
2. `~/.claude/mcp.json` — buscar credenciales MCP
3. `~/**/.env*` — todos los .env del sistema

Rotación obligatoria (lista mínima si el repo fue público aunque sea 1 minuto):
- Anthropic API key → console.anthropic.com/settings/keys
- OpenAI API key → platform.openai.com/api-keys
- Supabase anon/service → supabase.com → Project Settings → API
- Vercel tokens → vercel.com/account/tokens
- GHL API keys → GoHighLevel sub-account settings
- n8n webhook tokens (re-generar los workflows que expongan webhooks)

Después: `gh repo edit --visibility private` si aplica, y verificar history con `git log --all -- <archivo-sensible>`.

---

## B. Actualización del sistema (agente nuevo o modificado)

### Flujo estándar

```bash
# 1. Validar el agente en local
./scripts/lint-agent.sh agents/categoria/nuevo-agente.md
# Debe salir con exit 0 o 1. Si es 2, NO continuar.

# 2. Rebuild del índice
./scripts/build-index.sh
# Actualiza AGENTS_INDEX.md

# 3. Commit
git add agents/categoria/nuevo-agente.md AGENTS_INDEX.md
git commit -m "feat(agents): add nuevo-agente"

# 4. Push
git push origin main
# CI correrá audit-all.sh → si falla, revertir.

# 5. (Opcional) Bump de versión
# Si es release significativo, editar CHANGELOG.md con vX.Y.Z + tag:
git tag -a v1.1.0 -m "Add nuevo-agente"
git push --tags
```

### Convención de commits

- `feat(agents): add X` — agente nuevo
- `fix(agents): repair frontmatter in X` — arregla validación
- `chore(agents): bump last_reviewed for X` — audit periódico
- `refactor(scripts): optimize lint-agent.sh` — cambios de tooling
- `docs: update ROTATION.md` — documentación

---

## C. Sincronización con upstream (`msitarzewski/agency-agents`)

**IMPORTANTE:** nuestro schema difiere del upstream (v1.0 formal vs informal). **NO hacer `git merge upstream/main`** — romperá el frontmatter.

### Configurar upstream una vez

```bash
git remote add upstream https://github.com/msitarzewski/agency-agents.git
git fetch upstream
```

### Revisar cambios del upstream

```bash
git fetch upstream
git log main..upstream/main --oneline
# Lista commits que tenemos pendientes del upstream
```

### Cherry-pick selectivo

Por cada commit útil del upstream:

```bash
# 1. Ver el diff
git show <commit-sha>

# 2. Cherry-pick
git cherry-pick <commit-sha>
# Si hay conflicto de schema → resolver manualmente el frontmatter

# 3. Validar el agente afectado
./scripts/lint-agent.sh agents/ruta/afectado.md

# 4. Si queda OK, continuar. Si no, abortar:
git cherry-pick --abort
```

### Lo que NO se importa del upstream

- Agentes con schema informal sin migrar (rompen `audit-all.sh`)
- Scripts que dupliquen capacidades de los nuestros (`lint-agent.sh`, `audit-all.sh`, `build-index.sh`)
- Cambios en `install.sh` upstream (nuestro install es diferente)

---

## D. Deprecación de un agente

Cuando un agente queda obsoleto o es reemplazado por uno mejor.

### Fase 1 — Marcar como `deprecated` (día 0)

En el frontmatter del agente:

```yaml
status: deprecated
superseded_by: nuevo-agente-name
deprecation_date: 2026-04-24
```

Agregar aviso en `CHANGELOG.md`:

```markdown
## [Unreleased]
### Deprecated
- `old-agente-name` — reemplazado por `nuevo-agente-name`. Se removerá después del 2026-06-23.
```

Commit:
```bash
git commit -m "chore(agents): deprecate old-agente-name → nuevo-agente-name"
```

### Fase 2 — Gracia de 60 días

El agente sigue funcional pero emite warning al invocarse. Los usuarios tienen 60 días para migrar.

### Fase 3 — Superseded + archive (día 60+)

```bash
# 1. Cambiar status en frontmatter
#    status: superseded
#    (mantener supersededBy)

# 2. Mover a archive
mkdir -p agents/archive
git mv agents/categoria/old-agente-name.md agents/archive/

# 3. Regenerar índice
./scripts/build-index.sh

# 4. Release minor
git commit -m "chore(agents): archive old-agente-name (EOL)"
git tag -a v1.2.0 -m "Archive old-agente-name"
git push --tags
```

Actualizar `CHANGELOG.md`:

```markdown
## [1.2.0] — 2026-06-23
### Removed
- `old-agente-name` archivado tras 60 días de deprecation. Usar `nuevo-agente-name`.
```

---

## E. Audit semanal

### Manual

```bash
./scripts/audit-all.sh --report
open ~/.claude/AUDIT_REPORT.md
```

Revisar:
- **Críticos** → acción inmediata (migrar, remover, fixear)
- **Warnings** → planear para el siguiente ciclo
- **last_reviewed stale >90 días** → tocar `last_reviewed: YYYY-MM-DD` a hoy

### GitHub Action (opcional)

Crear `.github/workflows/weekly-audit.yml`:

```yaml
name: Weekly Audit
on:
  schedule:
    - cron: '0 13 * * 1'  # lunes 13:00 UTC (08:00 CDMX)
  workflow_dispatch:

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run audit
        run: |
          chmod +x scripts/*.sh
          AGENTS_DIR=./agents LINTER=./scripts/lint-agent.sh \
            ./scripts/audit-all.sh --fail-on-critical
```

Si falla, el maintainer recibe notificación y abre issue automático.

### Checklist rápida post-audit

- [ ] `0 críticos` en `AUDIT_REPORT.md`
- [ ] Warnings documentados en issue si no se resuelven en la sesión
- [ ] `last_reviewed` actualizado en agentes tocados
- [ ] `git commit` + push si hubo cambios
- [ ] `~/backup-claude.sh` si se tocó configuración global

---

## Referencia rápida de archivos

| Archivo | Propósito |
|---|---|
| `scripts/lint-agent.sh` | Valida un agente individual |
| `scripts/audit-all.sh` | Audit masivo con reporte |
| `scripts/build-index.sh` | Regenera AGENTS_INDEX.md |
| `scripts/uninstall.sh` | Remueve instalación idempotente |
| `.githooks/pre-commit` | Bloquea commits con críticos |
| `agents/SCHEMA.md` | Contrato del frontmatter |
| `agents/OVERLAP_MAP.md` | Decisión "cuándo usar X vs Y" |
| `CHANGELOG.md` | Historia de releases |
| `docs/ROTATION.md` | Este documento |
