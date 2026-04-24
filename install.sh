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

# Generar índice a partir del frontmatter instalado
echo ""
echo "📚 Generando catálogo AGENTS_INDEX.md..."
if "$TARGET_SCRIPTS/build-index.sh" >/dev/null 2>&1; then
  echo "  ✅ $HOME/.claude/AGENTS_INDEX.md"
else
  echo "  ⚠️  build-index falló (continuo)"
fi

# Validar con audit (genera AUDIT_REPORT.md)
echo ""
echo "🔍 Validando instalación (audit completo)..."
if "$TARGET_SCRIPTS/audit-all.sh" --report 2>&1 | tail -8; then
  echo ""
  echo "✅ Instalación OK."
else
  echo "⚠️  El audit reportó findings — revisa ~/.claude/AUDIT_REPORT.md"
  exit 1
fi

# ─── Post-install validation mejorada ──────────────────────────────────────
echo ""
echo "🔐 Verificación post-install (permisos + integridad)..."
POST_FAIL=0

# 1. Permisos del directorio de agentes (755)
if [[ -d "$TARGET_AGENTS" ]]; then
  dir_perms=$(stat -f '%Lp' "$TARGET_AGENTS" 2>/dev/null || stat -c '%a' "$TARGET_AGENTS" 2>/dev/null)
  if [[ "$dir_perms" != "755" ]]; then
    echo "  ⚠️  $TARGET_AGENTS tiene permisos $dir_perms — corrigiendo a 755"
    chmod 755 "$TARGET_AGENTS"
  else
    echo "  ✅ $TARGET_AGENTS permisos 755"
  fi
fi

# 2. Permisos de archivos de agentes (644)
bad_files=$(find "$TARGET_AGENTS" -type f -name "*.md" ! -perm 644 2>/dev/null | wc -l | tr -d ' ')
if [[ "$bad_files" -gt 0 ]]; then
  echo "  ⚠️  $bad_files archivo(s) con permisos distintos a 644 — corrigiendo"
  find "$TARGET_AGENTS" -type f -name "*.md" -exec chmod 644 {} \;
else
  echo "  ✅ Archivos de agentes con permisos 644"
fi

# 3. Permisos de scripts (755)
bad_scripts=$(find "$TARGET_SCRIPTS" -type f -name "*.sh" ! -perm 755 2>/dev/null | wc -l | tr -d ' ')
if [[ "$bad_scripts" -gt 0 ]]; then
  echo "  ⚠️  $bad_scripts script(s) con permisos distintos a 755 — corrigiendo"
  find "$TARGET_SCRIPTS" -type f -name "*.sh" -exec chmod 755 {} \;
else
  echo "  ✅ Scripts con permisos 755"
fi

# 4. Integridad: cada agente del repo debe estar en ~/.claude/agents/
REPO_COUNT=$(find "$REPO_DIR/agents" -type f -name "*.md" | wc -l | tr -d ' ')
INSTALLED_COUNT=$(find "$TARGET_AGENTS" -type f -name "*.md" | wc -l | tr -d ' ')
MISSING=0
while IFS= read -r f; do
  rel="${f#$REPO_DIR/agents/}"
  [[ ! -f "$TARGET_AGENTS/$rel" ]] && MISSING=$((MISSING+1))
done < <(find "$REPO_DIR/agents" -type f -name "*.md")
if [[ $MISSING -gt 0 ]]; then
  echo "  ❌ $MISSING agente(s) del repo NO están en $TARGET_AGENTS"
  POST_FAIL=1
else
  echo "  ✅ Integridad OK — $REPO_COUNT agentes del repo presentes ($INSTALLED_COUNT totales instalados)"
fi

# 5. lint-agent.sh ejecutable
if [[ -x "$TARGET_SCRIPTS/lint-agent.sh" ]]; then
  echo "  ✅ lint-agent.sh ejecutable"
else
  echo "  ❌ lint-agent.sh NO ejecutable"
  POST_FAIL=1
fi

# 6. Índice generado
if [[ -f "$HOME/.claude/AGENTS_INDEX.md" ]] && [[ -s "$HOME/.claude/AGENTS_INDEX.md" ]]; then
  echo "  ✅ AGENTS_INDEX.md generado ($(wc -l < "$HOME/.claude/AGENTS_INDEX.md" | tr -d ' ') líneas)"
else
  echo "  ❌ AGENTS_INDEX.md no existe o está vacío"
  POST_FAIL=1
fi

if [[ $POST_FAIL -eq 1 ]]; then
  echo ""
  echo "⚠️  Validación post-install reportó problemas — revisa arriba."
  exit 1
fi

echo ""
echo "Próximos pasos:"
echo "  1. Activa un agente: 'Hey Claude, activate Frontend Developer mode'"
echo "  2. Ver el índice:    open ~/.claude/AGENTS_INDEX.md"
echo "  3. Ver el reporte:   open ~/.claude/AUDIT_REPORT.md"
echo "  4. Audit semanal:    $TARGET_SCRIPTS/audit-all.sh --report"
