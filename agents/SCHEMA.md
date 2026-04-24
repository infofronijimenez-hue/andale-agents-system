# Agent Schema — Sistema de Agentes

> Contrato de frontmatter enriquecido para los ~201 agentes de `~/.claude/agents/`.
> Creado: 2026-04-24 | Versión: 1.0.0 | Owner: Froni Jimenez

---

## 🎯 Propósito

Industrializar el frontmatter de los agentes con campos que permitan:
1. **Versionado** de cada agente (evolución sin romper consumidores)
2. **Status lifecycle** (activo, beta, deprecado, superseded)
3. **Clasificación de riesgo** para contextos HIPAA/CMS
4. **Tags multi-dominio** (un agente puede aplicar a varias áreas)
5. **Allowlist de servicios externos** (defensa supply-chain)

---

## 📋 Frontmatter v1.0 — Schema oficial

### Campos OBLIGATORIOS (críticos — sin estos el agente se rechaza)

```yaml
---
name: Nombre del Agente          # string, único dentro de su categoría
description: Una línea ≤160 chars # string, ≤160 chars, sin emojis
---
```

### Campos RECOMENDADOS (ausencia = warning, no crítico)

```yaml
color: indigo                     # colorname CSS o #hex
emoji: 🏛️                          # 1 emoji representativo
vibe: Frase de personalidad       # string, 1 línea, captura la esencia
```

**Decisión arquitectónica 2026-04-24:** Baseline audit mostró que `color`/`vibe` faltan
en ~52% del repo upstream. Mantenerlos como críticos genera ruido que oculta los
findings reales de seguridad. Se degradan a recomendados hasta migración Sprint 2.

### Campos NUEVOS v1.0 (opcionales pero recomendados)

```yaml
version: 1.0.0                    # semver — inicia en 1.0.0
status: active                    # enum: active | beta | deprecated | superseded
supersededBy: null                # si status=superseded, nombre del reemplazo
risk_level: low                   # enum: low | medium | high | critical
hipaa_safe: true                  # bool — ¿puede manejar datos PHI/PII sin riesgo?
tags:                             # lista — categorización cruzada
  - security
  - backend
  - compliance
services:                         # lista de dependencias externas
  - name: Anthropic API
    url: https://api.anthropic.com
    tier: paid                    # enum: free | freemium | paid
    allowlist_required: true      # bool — si true, dominio debe estar pre-aprobado
last_reviewed: 2026-04-24         # YYYY-MM-DD — última auditoría manual
reviewed_by: froni                # string — quién auditó
```

---

## 🛡️ Reglas de risk_level

| Nivel | Criterio | Controles mínimos |
|---|---|---|
| `low` | No toca datos sensibles, no ejecuta código destructivo, solo sugiere | Lint básico |
| `medium` | Puede sugerir código que afecta producción o datos no sensibles | Lint + revisión manual antes de usar |
| `high` | Toca autenticación, datos operacionales, infraestructura | Lint + CODEOWNERS + pruebas en sandbox |
| `critical` | Puede tocar datos HIPAA/SSN/financieros, auth, billing | Lint + revisión dual + sandbox obligatorio + audit log |

---

## 🏷️ Tags canónicos (taxonomía controlada)

Usa tags de esta lista para búsqueda consistente. Si necesitas un tag nuevo, documéntalo aquí primero.

**Técnicos:**
`frontend`, `backend`, `database`, `devops`, `security`, `ai-ml`, `mobile`, `api`,
`testing`, `observability`, `performance`, `accessibility`

**Dominio de negocio Andale:**
`insurance`, `hipaa`, `cms`, `compliance`, `sales`, `recruitment`, `content`,
`copy`, `marketing`, `analytics`, `finance`, `legal`

**Stack:**
`nextjs`, `supabase`, `vercel`, `ghl`, `n8n`, `react`, `typescript`

**Proceso:**
`strategy`, `audit`, `qa`, `docs`, `incident-response`, `planning`

---

## 🔄 Lifecycle de status

```
beta → active → deprecated → superseded
         ↓
      deprecated (sin reemplazo)
```

- **beta**: agente nuevo sin uso en producción (evaluación)
- **active**: en uso regular, probado
- **deprecated**: desaconsejado, aún funcional (dar 60 días de aviso)
- **superseded**: reemplazado, `supersededBy` obligatorio

---

## 🚨 Campos prohibidos en body (detectados por linter)

El cuerpo del agente NO debe contener:

1. **Instrucciones de hijacking al LLM**: `ignore previous instructions`, `ignore all prior`, `disregard system prompt`
2. **Role spoofing**: líneas que empiecen con `system:`, `assistant:`, `user:` fuera de ejemplos claros
3. **URLs de exfiltración**: `webhook.site`, `pastebin.com`, `transfer.sh`, `paste.ee`, `ngrok.io`, `requestcatcher`, `beeceptor`
4. **Comandos activos de red sin contexto**: `curl -X POST ... | bash`, `wget --post-data`
5. **Payloads base64 largos**: base64 encoded >500 chars consecutivos
6. **Destructivos**: `rm -rf /`, `rm -rf ~`, `sudo rm` sin explicación didáctica
7. **Eval dinámico**: `eval(` sobre variables no-locales

Si un agente legítimamente necesita mostrar estos patrones (ej. agente Security Engineer mostrando ejemplos de ataques), debe usar bloques de código claramente marcados y comentados.

---

## 🔍 Cómo validar

```bash
~/.claude/scripts/lint-agent.sh <path-al-agente.md>
~/.claude/scripts/audit-all.sh    # lintea los 201
```

---

## 📜 Changelog del schema

| Versión | Fecha | Cambio |
|---|---|---|
| 1.0.0 | 2026-04-24 | Schema inicial — añade version, status, risk_level, tags, hipaa_safe, services.allowlist_required, last_reviewed |
