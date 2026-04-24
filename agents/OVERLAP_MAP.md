# 🗺️ Overlap Map — Sistema de Agentes

> Guía de decisión "cuándo usar X vs Y" para agentes con responsabilidades solapadas.
> Basado en auditoría Code Reviewer (Sprint 0) + revisión arquitectónica (Sprint 3).
> Última actualización: 2026-04-24

---

## 🎯 Por qué existe este documento

Con 188 agentes, hay inevitablemente solapamientos. Sin este mapa:
- Te preguntas ¿Software Architect o Backend Architect? y pierdes tiempo
- Claude Code activa al agente equivocado para la tarea
- Se acumula deuda: agentes duplicados nunca consolidados

Este mapa resuelve las 5 zonas de mayor solape del sistema actual.

---

## 1️⃣ Architects (engineering + specialized)

| Agente | Úsalo cuando | Evítalo cuando |
|---|---|---|
| **Software Architect** | Diseño a nivel sistema completo: bounded contexts, trade-offs consistencia vs disponibilidad, ADRs, evolución arquitectónica | Solo necesitas detalles de backend o de performance específica |
| **Backend Architect** | API design, schemas, microservicios, integraciones, cloud infra | Estás decidiendo entre monolito vs microservicios (eso es Software Architect) |
| **Autonomous Optimization Architect** | Sistemas agénticos que eligen entre APIs/modelos con guardrails de costo | Arquitectura tradicional sin LLM routing |

**Regla de oro:** empieza por Software Architect para decisiones de alto nivel. Backend Architect para el cómo técnico del lado servidor.

---

## 2️⃣ Security (engineering + specialized)

| Agente | Úsalo cuando | Evítalo cuando |
|---|---|---|
| **Security Engineer** | Threat modeling, OWASP Top 10, secure code review, security architecture de apps web/cloud | Incidente activo en producción → Incident Response Commander |
| **Threat Detection Engineer** | Construcción de reglas SIEM, ATT&CK mapping, threat hunting, detection-as-code | Diseñando seguridad preventiva → Security Engineer |
| **Blockchain Security Auditor** | Smart contracts, DeFi, vulnerabilidades EVM | Web2 / aplicaciones no-crypto |
| **Compliance Auditor** | SOC 2, ISO 27001, HIPAA, PCI-DSS audits | Seguridad técnica sin componente regulatorio |

**Regla de oro:** Security Engineer + Compliance Auditor trabajan en paralelo en PARALELA (HIPAA). El primero asegura el código, el segundo el marco regulatorio.

---

## 3️⃣ Content & Marketing Strategists (29 agentes en marketing/)

### Por plataforma (elige la plataforma específica cuando sepas el canal)

| Plataforma | Agente |
|---|---|
| LinkedIn | LinkedIn Content Creator |
| TikTok | TikTok Strategist |
| Instagram | Instagram Curator |
| Twitter/X | Twitter Engager |
| Reddit | Reddit Community Builder |
| YouTube | Video Optimization Specialist |

### Cross-plataforma (elige según scope)

| Agente | Úsalo cuando |
|---|---|
| **Content Creator** | Necesitas estrategia editorial cross-platform, editorial calendar, narrativa de marca |
| **Social Media Strategist** | Programa paid/organic social cross-platform a nivel campaña |
| **Growth Hacker** | Enfoque en viral loops y experimentación de canales |

### Mercado China (11 agentes — NO usar para mercado occidental)

| Plataforma China | Agente |
|---|---|
| Douyin | Douyin Strategist |
| Xiaohongshu | Xiaohongshu Specialist |
| WeChat OA | WeChat Official Account Manager |
| Weibo | Weibo Strategist |
| Kuaishou | Kuaishou Strategist |
| Baidu SEO | Baidu SEO Specialist |
| Zhihu | Zhihu Strategist |
| Bilibili | Bilibili Content Strategist |
| Cross-border | Cross-Border E-Commerce Specialist |
| Localization | China Market Localization Strategist |
| Livestream | Livestream Commerce Coach |

**Regla de oro:** si la campaña es para audiencia china → specialist de esa plataforma. Si es mercado LATAM/US → los cross-plataforma.

---

## 4️⃣ Orquestadores (specialized/)

| Agente | Úsalo cuando | Evítalo cuando |
|---|---|---|
| **Workflow Architect** | Diseñar árboles de workflow con happy path + branches + failure modes para implementación técnica | Solo quieres automatización simple sin diseño formal |
| **Automation Governance Architect** | Auditar value/risk/maintainability de una automatización n8n/Zapier antes de construir | Ya tienes el workflow; solo falta implementar |
| **Agents Orchestrator** | Pipeline de desarrollo autónoma con múltiples agentes en handoff | Tarea single-agent |

**Regla de oro:** Governance ANTES de construir (¿vale la pena?). Architect durante el diseño (¿cómo luce el árbol?). Orchestrator en ejecución (¿quién hace qué?).

---

## 5️⃣ Code Quality & Review

| Agente | Úsalo cuando |
|---|---|
| **Code Reviewer** | PR review, quality gate, mentoring via comentarios |
| **Reality Checker** | Validar que algo REALMENTE funciona (no solo que dicen que funciona) |
| **Evidence Collector** | Screenshots, visual proof, pre-production QA |
| **API Tester** | Validación específica de APIs y contratos |
| **Performance Benchmarker** | Medición cuantitativa de performance |

**Regla de oro Andale:** Reality Checker + Evidence Collector trabajan juntos antes de cada deploy a producción (REGLA #11 Fase 4).

---

## 6️⃣ Sales (8 agentes en sales/)

| Agente | Úsalo cuando |
|---|---|
| **Deal Strategist** | Deals complejos B2B, MEDDPICC, win plans |
| **Discovery Coach** | Mejorar calidad de discovery calls y question design |
| **Sales Coach** | Development de reps, pipeline reviews, call coaching |
| **Outbound Strategist** | Secuencias multi-canal, ICP, prospecting research-driven |
| **Account Strategist** | Post-sale expansion, QBRs, land-and-expand |
| **Sales Engineer** | Pre-sale técnico: demos, POCs, technical win |
| **Proposal Strategist** | RFPs, win themes, executive summaries |
| **Pipeline Analyst** | Data de CRM, forecasting, velocity analysis |

**Regla de oro:** Outbound → Discovery → Sales Engineer → Deal Strategist → Proposal → Account Strategist. En ese orden del funnel.

---

## 📊 Consolidación propuesta (futuro Sprint)

Agentes candidatos a **merge** en el futuro (basado en solapamiento funcional):

| Candidatos | Razón merge | Riesgo |
|---|---|---|
| Content Creator + Social Media Strategist | Ambos hacen estrategia cross-platform | Bajo — son 80% solapados |
| Software Architect + Backend Architect | Backend es subconjunto de Software | Medio — perderías la especialización backend |
| Workflow Architect + Agents Orchestrator | Ambos diseñan flujos multi-step | Alto — governance es distinto a diseño |

**Decisión actual:** NO hacer merges. El costo (perder especialización) supera el beneficio (menos opciones). Esperar Sprint 5 cuando tengamos datos de uso real para priorizar.

---

## 🔄 Cómo mantener este mapa

1. Tras cada Sprint grande: revisar si hay nuevos solapamientos
2. Si un agente nuevo se propone y ya existe uno similar: documentar diferencia aquí ANTES de crearlo
3. Si un agente queda en desuso (`status: deprecated`): moverlo a sección "Históricos" con fecha

---

## 📎 Referencias

- Auditoría Code Reviewer (Sprint 0): `~/.claude/AUDIT_REPORT.md`
- Schema v1.0: `~/.claude/agents/SCHEMA.md`
- Índice completo: `~/.claude/AGENTS_INDEX.md`
