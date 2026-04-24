# Pull Request

## Tipo de cambio
<!-- Marca lo que aplica -->
- [ ] Nuevo agente
- [ ] Modificación de agente existente
- [ ] Fix de linter / script
- [ ] Mejora de docs
- [ ] Cambio de schema / arquitectura
- [ ] Otro (describe):

## Descripción
<!-- Qué hace este PR y por qué -->

## Checklist pre-merge

### Si tocaste un agente (`.md` en `agents/`):
- [ ] Pasé `./scripts/lint-agent.sh agents/ruta/mi-agente.md` → exit 0
- [ ] Frontmatter respeta el schema (ver `agents/SCHEMA.md`)
- [ ] `last_reviewed` está actualizado con la fecha de hoy
- [ ] `version` incrementada si es modificación de agente existente
- [ ] `description` ≤ 160 chars y NO termina truncada con `...`

### Si tocaste un script (`scripts/*.sh`, `install.sh`):
- [ ] `bash -n scripts/<archivo>.sh` pasa
- [ ] `shellcheck --severity=warning scripts/<archivo>.sh` pasa (si tienes shellcheck local)
- [ ] Probé el cambio end-to-end al menos una vez
- [ ] Actualicé los comentarios de uso (`# Uso: ...`) si cambió la interfaz

### General:
- [ ] `./scripts/audit-all.sh` reporta 0 críticos
- [ ] El CI está en verde
- [ ] Si este PR rompe algo existente, lo documenté en la descripción

## Contexto adicional
<!-- Links a issues, screenshots, etc -->

Closes #
