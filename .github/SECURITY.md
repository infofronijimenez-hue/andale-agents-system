# Security Policy

## Versiones soportadas

| Versión | Soporte          |
| ------- | ---------------- |
| 1.0.x   | ✅ Activo         |
| < 1.0   | ❌ No soportado   |

## Reporte de vulnerabilidades

**No uses issues públicos para reportar vulnerabilidades de seguridad.**

### Canal preferido: GitHub Security Advisories

1. Ve a https://github.com/infofronijimenez-hue/andale-agents-system/security/advisories/new
2. Describe la vulnerabilidad con:
   - Componente afectado (script, agente específico, install.sh, etc.)
   - Pasos para reproducir
   - Impacto potencial
   - Versión o commit afectado

### Canal alternativo

Si no puedes usar Security Advisories, abre un issue genérico **sin detalles sensibles** pidiendo un canal privado y el maintainer responderá.

## SLA de respuesta

- **Acuse de recibo:** 72 horas
- **Evaluación inicial:** 7 días
- **Parche o mitigación:** según severidad
  - Crítica: ≤ 7 días
  - Alta: ≤ 14 días
  - Media: ≤ 30 días
  - Baja: próximo release

## Alcance

### Sí cubierto:
- Vulnerabilidades en `scripts/*.sh`, `install.sh`
- Prompt injection que bypassa el linter (`lint-agent.sh`)
- Agentes que contengan comandos destructivos no detectados
- Exposición de secretos o credenciales en el repo
- Problemas del CI/CD (`.github/workflows/`)

### No cubierto:
- Vulnerabilidades en Claude Code u otras herramientas downstream
- Uso malicioso por parte de quien instala el repo (ej. modificar agentes localmente con código dañino)
- Bugs funcionales sin impacto de seguridad (usa `bug_report.md`)

## Controles de seguridad activos

Ver [`THREAT_MODEL.md`](../THREAT_MODEL.md) para el análisis completo. Resumen:

- **Secret scanning** habilitado con push protection
- **Branch protection** en `main` (PR review + status checks obligatorios)
- **Dependabot** para GitHub Actions
- **Linter adversarial** detecta:
  - Instruction hijacking (`ignore previous instructions`, etc.)
  - Dominios de exfiltración conocidos
  - `curl ... | bash`
  - `rm -rf /`, `rm -rf ~`, `sudo rm`
  - Base64 execution hidden payloads

## Agradecimientos

Los reportes responsables serán reconocidos públicamente (con autorización del reportante) en las release notes.
