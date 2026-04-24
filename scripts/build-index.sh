#!/usr/bin/env bash
# build-index.sh — Genera AGENTS_INDEX.md automáticamente desde el frontmatter.
#
# Uso:
#   build-index.sh                        # escribe a ~/.claude/AGENTS_INDEX.md
#   build-index.sh --out /path/INDEX.md   # custom destino
#   build-index.sh --stdout               # imprime sin escribir
#
# Owner: Froni Jimenez | Creado: 2026-04-24 | v1.0.0

set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-$HOME/.claude/agents}"
OUT="${OUT:-$HOME/.claude/AGENTS_INDEX.md}"
STDOUT=0

for arg in "$@"; do
  case "$arg" in
    --out) shift; OUT="$1"; shift ;;
    --stdout) STDOUT=1 ;;
    --help|-h) grep '^#' "$0" | head -10; exit 0 ;;
  esac
done

if [[ ! -d "$AGENTS_DIR" ]]; then
  echo "ERROR: agents directory not found: $AGENTS_DIR" >&2
  exit 1
fi

# Get scalar frontmatter field from file
get_field() {
  local file="$1" key="$2"
  awk -v k="$key" '
    /^---$/{c++; next}
    c==1 && $0 ~ "^"k":" {
      sub("^"k":[[:space:]]*", "")
      gsub(/^[\x27"]|[\x27"]$/, "")
      print; exit
    }
    c>=2{exit}
  ' "$file"
}

# Collect all agents (exclude SCHEMA.md, indices, hidden)
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
NOW=$(date +%Y-%m-%d)

# ─── Render to temp file, then atomic move ────────────────────────────────
TMP=$(mktemp -t agents-index.XXXXXX)
trap 'rm -f "$TMP"' EXIT

{
  echo "# 🎭 Agents Index — Sistema Andale"
  echo ""
  echo "> **Auto-generado** por \`~/.claude/scripts/build-index.sh\` — NO editar a mano."
  echo "> Última generación: **$NOW** · Total agentes: **$TOTAL**"
  echo ""
  echo "---"
  echo ""
  echo "## 📊 Stats"
  echo ""
  echo "| Categoría | Count |"
  echo "|---|---|"

  # Count per category
  declare -a CATEGORIES
  CATEGORIES=()
  for f in "${FILES[@]}"; do
    rel="${f#$AGENTS_DIR/}"
    cat=$(dirname "$rel")
    [[ "$cat" == "." ]] && cat="_root"
    CATEGORIES+=("$cat")
  done
  printf '%s\n' "${CATEGORIES[@]}" | sort | uniq -c | awk '{printf "| %s | %d |\n", $2, $1}'

  echo ""
  echo "---"
  echo ""
  echo "## 📚 Catálogo por categoría"
  echo ""

  # Group by category (top-level dir)
  current_cat=""
  for f in "${FILES[@]}"; do
    rel="${f#$AGENTS_DIR/}"
    cat=$(dirname "$rel" | awk -F/ '{print $1}')
    [[ "$cat" == "." ]] && cat="_root"

    if [[ "$cat" != "$current_cat" ]]; then
      if [[ -n "$current_cat" ]]; then echo ""; fi
      echo "### \`$cat/\`"
      echo ""
      echo "| Agent | Description | Status | Risk |"
      echo "|---|---|---|---|"
      current_cat="$cat"
    fi

    name=$(get_field "$f" "name")
    desc=$(get_field "$f" "description")
    emoji=$(get_field "$f" "emoji")
    status=$(get_field "$f" "status")
    risk=$(get_field "$f" "risk_level")
    [[ -z "$name" ]] && name=$(basename "$f" .md)
    [[ -z "$status" ]] && status="—"
    [[ -z "$risk" ]] && risk="—"
    [[ -z "$desc" ]] && desc="(sin descripción)"

    # Escape pipes in description
    desc=$(printf '%s' "$desc" | sed 's/|/\\|/g')
    name_esc=$(printf '%s' "$name" | sed 's/|/\\|/g')

    printf "| %s [%s](agents/%s) | %s | %s | %s |\n" \
      "$emoji" "$name_esc" "$rel" "$desc" "$status" "$risk"
  done

  echo ""
  echo "---"
  echo ""
  echo "## 🔍 Cómo regenerar"
  echo ""
  echo '```bash'
  # shellcheck disable=SC2088  # literal tilde for display in markdown
  echo '~/.claude/scripts/build-index.sh'
  echo '```'
  echo ""
  echo "## 🛡️ Cómo auditar"
  echo ""
  echo '```bash'
  # shellcheck disable=SC2088  # literal tilde for display in markdown
  echo '~/.claude/scripts/audit-all.sh'
  echo '```'
} > "$TMP"

if [[ $STDOUT -eq 1 ]]; then
  cat "$TMP"
else
  mv "$TMP" "$OUT"
  trap - EXIT
  echo "✅ Index written: $OUT ($TOTAL agents)"
fi
