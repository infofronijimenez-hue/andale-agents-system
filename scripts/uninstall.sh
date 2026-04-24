#!/usr/bin/env bash
# uninstall.sh — Remueve agentes y scripts instalados por andale-agents-system.
# Idempotente. NO toca CLAUDE.md, claude.json ni mcp.json.
#
# Uso: ./uninstall.sh [--yes|-y] [--dry-run] [--help|-h]
#
# Owner: Froni Jimenez | Creado: 2026-04-24 | v1.0.0

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_AGENTS="$HOME/.claude/agents"
TARGET_SCRIPTS="$HOME/.claude/scripts"
REPO_SCRIPTS=(lint-agent.sh audit-all.sh build-index.sh migrate-frontmatter.sh uninstall.sh README.md)

YES=0; DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y)  YES=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) grep '^#' "$0" | head -8; exit 0 ;;
    *) echo "Flag desconocida: $arg" >&2; exit 1 ;;
  esac
done

confirm() {
  [[ $YES -eq 1 ]] && return 0
  printf '%s [y/N]: ' "$1"; read -r a
  [[ "$a" == "y" || "$a" == "Y" ]]
}

# Calcular qué se removería
AGENT_HITS=()
while IFS= read -r f; do
  rel="${f#$REPO_DIR/agents/}"
  [[ -f "$TARGET_AGENTS/$rel" ]] && AGENT_HITS+=("$TARGET_AGENTS/$rel")
done < <(find "$REPO_DIR/agents" -type f -name "*.md" 2>/dev/null)

SCRIPT_HITS=()
for s in "${REPO_SCRIPTS[@]}"; do
  [[ -f "$TARGET_SCRIPTS/$s" ]] && SCRIPT_HITS+=("$TARGET_SCRIPTS/$s")
done

N_A=${#AGENT_HITS[@]}; N_S=${#SCRIPT_HITS[@]}

if [[ $N_A -eq 0 && $N_S -eq 0 ]]; then
  echo "ℹ️  No hay nada instalado por andale-agents-system. Exit 0."
  exit 0
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "🔎 DRY-RUN — lo que se removería:"
  echo "  Agentes: $N_A en $TARGET_AGENTS/"
  [[ $N_A -gt 0 ]] && printf '    - %s\n' "${AGENT_HITS[@]:0:10}"
  [[ $N_A -gt 10 ]] && echo "    ... y $((N_A - 10)) más"
  echo "  Scripts: $N_S en $TARGET_SCRIPTS/"
  [[ $N_S -gt 0 ]] && printf '    - %s\n' "${SCRIPT_HITS[@]}"
  echo ""
  echo "NO se tocaría: CLAUDE.md, claude.json, mcp.json"
  exit 0
fi

echo "⚠️  Se removerán $N_A agentes y $N_S scripts."
if ! confirm "Continuar?"; then
  echo "Cancelado."; exit 0
fi

[[ $N_A -gt 0 ]] && for f in "${AGENT_HITS[@]}";  do rm -f "$f"; done
[[ $N_S -gt 0 ]] && for f in "${SCRIPT_HITS[@]}"; do rm -f "$f"; done

echo "✅ Desinstalado: $N_A agentes removidos, $N_S scripts removidos."
exit 0
