#!/usr/bin/env bash
# install.sh — Instala los 188 agentes + tooling a ~/.claude/
#
# Seguro de correr múltiples veces (idempotente).
# NO modifica tu CLAUDE.md ni otras configs.
#
# Uso:
#   ./install.sh               # instalación interactiva
#   ./install.sh --yes         # sin prompts (CI-friendly)
#   ./install.sh --uninstall   # remueve agentes y scripts

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_AGENTS="$HOME/.claude/agents"
TARGET_SCRIPTS="$HOME/.claude/scripts"

YES=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y) YES=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --help|-h) grep '^#' "$0" | head -10; exit 0 ;;
  esac
done

confirm() {
  [[ $YES -eq 1 ]] && return 0
  printf '%s [y/N]: ' "$1"
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

# ─── Uninstall ─────────────────────────────────────────────────────────────
if [[ $UNINSTALL -eq 1 ]]; then
  echo "⚠️  Esto removerá agentes y scripts instalados por andale-agents-system."
  if ! confirm "Continuar?"; then
    echo "Cancelado."
    exit 0
  fi
  # Solo remover los agentes que VIENEN de este repo (por lista)
  while IFS= read -r f; do
    rel="${f#$REPO_DIR/agents/}"
    target="$TARGET_AGENTS/$rel"
    [[ -f "$target" ]] && rm -f "$target"
  done < <(find "$REPO_DIR/agents" -type f -name "*.md")
  # Remover scripts del repo
  for s in lint-agent.sh audit-all.sh build-index.sh migrate-frontmatter.sh README.md; do
    [[ -f "$TARGET_SCRIPTS/$s" ]] && rm -f "$TARGET_SCRIPTS/$s"
  done
  echo "✅ Desinstalado."
  exit 0
fi

# ─── Install ───────────────────────────────────────────────────────────────
echo "🎭 Andale Agents System — Instalador"
echo ""
echo "Se copiarán:"
echo "  agents/ → $TARGET_AGENTS  ($(find "$REPO_DIR/agents" -name '*.md' | wc -l | tr -d ' ') archivos)"
echo "  scripts/ → $TARGET_SCRIPTS ($(ls "$REPO_DIR"/scripts/*.sh | wc -l | tr -d ' ') scripts)"
echo ""
echo "NO se modificará: ~/.claude/CLAUDE.md, claude.json, mcp.json"
echo ""

if ! confirm "Proceder?"; then
  echo "Cancelado."
  exit 0
fi

# Crear dirs si no existen
mkdir -p "$TARGET_AGENTS"
mkdir -p "$TARGET_SCRIPTS"

# Backup si ya hay contenido previo
if [[ -d "$TARGET_AGENTS" ]] && [[ -n "$(ls -A "$TARGET_AGENTS" 2>/dev/null)" ]]; then
  BACKUP_DIR="$HOME/.claude/agents.backup-$(date +%Y%m%d-%H%M%S)"
  echo "📦 Backup del contenido previo → $BACKUP_DIR"
  cp -r "$TARGET_AGENTS" "$BACKUP_DIR"
fi

# Copy agents
echo "📁 Copiando agentes..."
rsync -a --exclude='.*' "$REPO_DIR/agents/" "$TARGET_AGENTS/"

# Copy scripts
echo "🛠️  Copiando scripts..."
cp "$REPO_DIR"/scripts/*.sh "$TARGET_SCRIPTS/"
cp "$REPO_DIR/scripts/README.md" "$TARGET_SCRIPTS/" 2>/dev/null || true
chmod +x "$TARGET_SCRIPTS"/*.sh

# Verify with audit
echo ""
echo "🔍 Validando instalación..."
if "$TARGET_SCRIPTS/audit-all.sh" 2>&1 | tail -8; then
  echo ""
  echo "✅ Instalación OK."
  echo ""
  echo "Próximos pasos:"
  echo "  1. Activa un agente: 'Hey Claude, activate Frontend Developer mode'"
  echo "  2. Ver el índice:    open ~/.claude/AGENTS_INDEX.md"
  echo "  3. Audit semanal:    $TARGET_SCRIPTS/audit-all.sh --report"
else
  echo "⚠️  El audit reportó findings — revisa ~/.claude/AUDIT_REPORT.md"
  exit 1
fi
