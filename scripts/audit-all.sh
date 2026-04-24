#!/usr/bin/env bash
# audit-all.sh — Lintea los ~201 agentes y genera reporte consolidado.
#
# Uso:
#   audit-all.sh              # reporte en terminal
#   audit-all.sh --report     # también escribe ~/.claude/AUDIT_REPORT.md
#   audit-all.sh --fail-on-critical   # exit 2 si hay críticos (para CI futuro)
#
# Owner: Froni Jimenez | Creado: 2026-04-24 | v1.0.0

set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-$HOME/.claude/agents}"
LINTER="${LINTER:-$HOME/.claude/scripts/lint-agent.sh}"
REPORT="${REPORT:-$HOME/.claude/AUDIT_REPORT.md}"
WRITE_REPORT=0
FAIL_ON_CRITICAL=0

for arg in "$@"; do
  case "$arg" in
    --report) WRITE_REPORT=1 ;;
    --fail-on-critical) FAIL_ON_CRITICAL=1 ;;
    --help|-h) grep '^#' "$0" | head -10; exit 0 ;;
  esac
done

if [[ ! -x "$LINTER" ]]; then
  echo "ERROR: linter not found or not executable: $LINTER" >&2
  echo "Run: chmod +x $LINTER" >&2
  exit 1
fi

FILES=()
while IFS= read -r f; do
  FILES+=("$f")
done < <(find "$AGENTS_DIR" -type f -name "*.md" \
  ! -name "SCHEMA.md" \
  ! -name "AGENTS_INDEX.md" \
  ! -name "OVERLAP_MAP.md" \
  ! -name "INDEX.md" \
  ! -name "README.md" \
  ! -name ".*" \
  | sort)

TOTAL=${#FILES[@]}
CLEAN=0
WARN=0
CRIT=0

declare -a CRIT_FILES=()
declare -a WARN_FILES=()
declare -a CRIT_DETAILS=()
declare -a WARN_DETAILS=()

echo "🔍 Auditing $TOTAL agents in $AGENTS_DIR..."
echo ""

for f in "${FILES[@]}"; do
  set +e
  output=$("$LINTER" "$f" 2>&1)
  code=$?
  set -e

  rel="${f#$AGENTS_DIR/}"
  case $code in
    0) CLEAN=$((CLEAN+1)) ;;
    1)
      WARN=$((WARN+1))
      WARN_FILES+=("$rel")
      WARN_DETAILS+=("$output")
      ;;
    2)
      CRIT=$((CRIT+1))
      CRIT_FILES+=("$rel")
      CRIT_DETAILS+=("$output")
      ;;
  esac
done

# ─── Terminal summary ──────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMEN — Audit $(date +%Y-%m-%d' '%H:%M)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total agentes:      $TOTAL"
echo "✅ Limpios:         $CLEAN"
echo "⚠️  Warnings:       $WARN"
echo "❌ Críticos:        $CRIT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $CRIT -gt 0 ]]; then
  echo ""
  echo "❌ AGENTES CRÍTICOS (acción inmediata):"
  for f in "${CRIT_FILES[@]}"; do echo "   - $f"; done
fi

if [[ $WARN -gt 0 && $WARN -le 20 ]]; then
  echo ""
  echo "⚠️  AGENTES CON WARNINGS:"
  for f in "${WARN_FILES[@]}"; do echo "   - $f"; done
elif [[ $WARN -gt 20 ]]; then
  echo ""
  echo "⚠️  $WARN agentes con warnings (ver reporte completo con --report)"
fi

# ─── Markdown report ───────────────────────────────────────────────────────
if [[ $WRITE_REPORT -eq 1 ]]; then
  {
    echo "# 🛡️ Audit Report — Sistema Andale"
    echo ""
    echo "> Generado: **$(date +%Y-%m-%d' '%H:%M)** por \`audit-all.sh\`"
    echo ""
    echo "## 📊 Resumen"
    echo ""
    echo "| Métrica | Valor |"
    echo "|---|---|"
    echo "| Total agentes | $TOTAL |"
    echo "| ✅ Limpios | $CLEAN |"
    echo "| ⚠️ Warnings | $WARN |"
    echo "| ❌ Críticos | $CRIT |"
    pct=$(awk -v c="$CLEAN" -v t="$TOTAL" 'BEGIN{printf "%.1f", (c/t)*100}')
    echo "| Cleanliness | $pct% |"
    echo ""

    if [[ $CRIT -gt 0 ]]; then
      echo "## ❌ Críticos"
      echo ""
      for i in "${!CRIT_FILES[@]}"; do
        echo "### \`${CRIT_FILES[$i]}\`"
        echo ""
        echo '```'
        printf '%s\n' "${CRIT_DETAILS[$i]}"
        echo '```'
        echo ""
      done
    fi

    if [[ $WARN -gt 0 ]]; then
      echo "## ⚠️ Warnings"
      echo ""
      for i in "${!WARN_FILES[@]}"; do
        echo "### \`${WARN_FILES[$i]}\`"
        echo ""
        echo '```'
        printf '%s\n' "${WARN_DETAILS[$i]}"
        echo '```'
        echo ""
      done
    fi

    echo "## 🔄 Próxima auditoría recomendada"
    echo ""
    echo "Ejecutar semanalmente:"
    echo ""
    echo '```bash'
    echo "~/.claude/scripts/audit-all.sh --report"
    echo '```'
  } > "$REPORT"
  echo ""
  echo "📝 Reporte escrito: $REPORT"
fi

# Exit code
if [[ $FAIL_ON_CRITICAL -eq 1 && $CRIT -gt 0 ]]; then
  exit 2
fi
exit 0
