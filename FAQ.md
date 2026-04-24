# FAQ — Andale Agents System

> Preguntas frecuentes sobre el uso, modificación, audit y contribución al sistema.

---

## Uso básico

## ¿Qué hace realmente este repo?

Es una biblioteca de 188 agentes de IA en Markdown + tooling bash para validarlos, auditarlos y versionarlos. Cada agente es un archivo `.md` con frontmatter estructurado que define personalidad, misión y entregables. Claude Code los lee y asume el rol. Para equipos técnicos que quieren agentes consistentes, auditados y versionados en lugar de prompts sueltos.

## ¿Funciona sin Claude Code?

Los `.md` son legibles como documentación plana (cualquier editor los abre), pero la magia la hace Claude Code: detecta el `name` en el frontmatter, asume la personalidad y aplica la metodología. Sin Claude Code tienes buena documentación de 188 roles, sin activación automática.

## ¿Afecta mi configuración de Claude Code?

No. `install.sh` solo copia archivos a `~/.claude/agents/` y `~/.claude/scripts/`. **No toca** `CLAUDE.md`, `claude.json`, `mcp.json` ni tus skills. Si ya tenías agentes previos, hace backup automático en `~/.claude/agents.backup-YYYYMMDD-HHMMSS/` antes de copiar.

## ¿Puedo instalar solo algunas categorías de agentes?

El `install.sh` actual copia todo. Para instalación selectiva: clona el repo, borra las carpetas de `agents/` que no quieras antes de correr `./install.sh`. O bien, copia manualmente con `rsync -a agents/engineering/ ~/.claude/agents/engineering/`.

---

## Modificación

## ¿Puedo modificar un agente?

Sí. Edita el `.md` en `~/.claude/agents/categoria/nombre.md`, valida con `~/.claude/scripts/lint-agent.sh ruta/al/archivo.md`, y si quieres preservar el cambio ante reinstalación, también edítalo en el repo (`agents/categoria/nombre.md`) y haz commit.

## ¿Cómo subo uno nuevo?

1. Crea el archivo en `agents/categoria/categoria-nombre-del-agente.md` siguiendo el schema
2. Valida: `./scripts/lint-agent.sh agents/categoria/categoria-nombre-del-agente.md`
3. Regenera índice: `./scripts/build-index.sh`
4. Corre audit: `./scripts/audit-all.sh`
5. Commit + PR

Detalles en [`CONTRIBUTING.md`](./CONTRIBUTING.md) y schema en [`agents/SCHEMA.md`](./agents/SCHEMA.md).

## ¿Cómo actualizo a la última versión sin perder mis customizaciones?

```bash
cd andale-agents-system
git pull
./install.sh
```

El instalador hace backup automático de `~/.claude/agents/` a `~/.claude/agents.backup-YYYYMMDD-HHMMSS/` antes de sobrescribir. Tus customizaciones quedan ahí y puedes diffear: `diff -r ~/.claude/agents.backup-*/ ~/.claude/agents/`.

Para customizaciones permanentes, forkea el repo.

---

## Audit y validación

## ¿Qué pasa si el audit reporta warnings?

Warnings no bloquean el uso pero requieren revisión. Típicos: `last_reviewed` >90 días, `services.url` fuera de allowlist, role spoofing en texto plano. Abre `~/.claude/AUDIT_REPORT.md` para ver el detalle por agente y decide: fix o aceptar.

## ¿Qué pasa si el audit reporta críticos?

**No uses ese agente hasta resolverlo.** Críticos incluyen prompt injection (`ignore previous instructions`), dominios de exfiltración (webhook.site, pastebin.com), `curl … | bash`, `rm -rf /`, payloads base64 ocultos. Revisa `~/.claude/AUDIT_REPORT.md`, corrige el `.md` o muévelo a code block si es didáctico (ej. Security Engineer), y re-lintea.

## ¿Puedo ignorar el linter?

Técnicamente sí (solo es un script), pero no se recomienda. El linter existe porque un agente con instruction hijacking o dominios de exfiltración puede secuestrar a Claude Code. Si tienes un falso positivo legítimo, la solución estándar es mover el match dentro de un bloque ``` ``` — el linter los ignora por diseño.

## ¿Qué significa `status: beta` vs `active` vs `deprecated` vs `superseded`?

- `active` — listo para producción, mantenido
- `beta` — funcional pero API o contenido puede cambiar, úsalo con precaución
- `deprecated` — ya no se mantiene, evita empezar nuevos flujos con él
- `superseded` — reemplazado por otro agente (debe documentar cuál en el frontmatter)

## ¿Qué significa `risk_level: high`?

El agente puede ejecutar acciones con impacto significativo: tocar producción, manejar secretos, modificar datos sensibles (HIPAA/PII), ejecutar comandos destructivos. Uso recomendado solo con supervisión humana. Niveles: `low | medium | high | critical`. Ver [`agents/SCHEMA.md`](./agents/SCHEMA.md).

---

## Errores comunes

## ¿Por qué `install.sh` me pide bash 4 si tengo bash 3.2 en macOS?

**Bash 4 NO es requerido.** El instalador está escrito para funcionar con el bash 3.2 que trae macOS por defecto. Si ves un error pidiendo bash 4, es un bug — repórtalo abriendo un issue con el mensaje exacto y tu versión de macOS (`sw_vers` + `bash --version`).

## ¿Por qué algunos agentes tienen `vibe: TODO`?

Son agentes cuya migración de schema se completó automáticamente pero el campo `vibe` requiere decisión humana (personalidad descriptiva, no se puede inferir). Están marcados `TODO` para que un maintainer los revise manualmente. No afecta funcionalidad, solo identidad visual.

## ¿Qué pasa si elimino agentes instalados?

Nada grave. Claude Code simplemente no los encontrará cuando los invoques por nombre. Para restaurarlos: `./install.sh` o copia manual desde el repo. Para desinstalar limpio: `./install.sh --uninstall` (solo remueve los que vienen de este repo, respeta customizaciones externas).

---

## Contribuir

## ¿Cómo reporto un bug?

Abre un issue en [GitHub](https://github.com/infofronijimenez-hue/andale-agents-system/issues) con:
- Comando exacto que corriste
- Output completo del error
- Versión de macOS/Linux + versión de bash (`bash --version`)
- Si aplica: el agente `.md` involucrado

## ¿Cómo propongo un agente nuevo?

1. Abre un issue tipo "Nuevo agente" describiendo: propósito, categoría, entregables esperados
2. Espera feedback del maintainer antes de escribir el `.md` (evita trabajo duplicado)
3. Si se aprueba, sigue el flujo de [`CONTRIBUTING.md`](./CONTRIBUTING.md): crear → lint → build-index → audit → PR

## ¿Quién revisa los PRs?

El maintainer actual es [`infofronijimenez-hue`](https://github.com/infofronijimenez-hue). El PR debe pasar lint + audit con exit 0 automáticamente; luego el maintainer revisa contenido, personalidad y ajuste al schema.
