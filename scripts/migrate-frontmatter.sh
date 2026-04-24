#!/usr/bin/env bash
# migrate-frontmatter.sh — Migración asistida del frontmatter a SCHEMA.md v1.0.
#
# Uso:
#   migrate-frontmatter.sh <archivo.md>              # dry-run (diff en stdout)
#   migrate-frontmatter.sh --apply <archivo.md>      # aplica con .bak
#   migrate-frontmatter.sh --apply-all               # aplica a todos (confirma)
#   migrate-frontmatter.sh --dry-run-all             # muestra resumen sin modificar
#
# Heurísticas por categoría:
#   - vibe      → ausente: se conserva (editor debe decidir tono personal)
#   - color     → ausente: inferido por categoría (ver COLOR_MAP)
#   - emoji     → ausente: inferido por categoría (ver EMOJI_MAP)
#   - status    → ausente: "active"
#   - risk_level → ausente: inferido por categoría + patrones (ver RISK_MAP)
#   - last_reviewed → ausente: fecha de hoy
#   - reviewed_by   → ausente: "froni"
#   - description >160 → truncado a 157 + "..."
#
# NO MODIFICA: campos ya presentes. Body nunca se toca.
# Owner: Froni Jimenez | Creado: 2026-04-24 | v1.0.0

set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-$HOME/.claude/agents}"
TODAY=$(date +%Y-%m-%d)
REVIEWER="${REVIEWER:-froni}"

# ─── Category maps ─────────────────────────────────────────────────────────
get_category_color() {
  case "$1" in
    academic)          echo "purple" ;;
    design)            echo "pink" ;;
    engineering)       echo "indigo" ;;
    game-development*) echo "orange" ;;
    marketing)         echo "green" ;;
    paid-media)        echo "yellow" ;;
    product)           echo "blue" ;;
    project-management) echo "teal" ;;
    sales)             echo "red" ;;
    spatial-computing) echo "cyan" ;;
    specialized)       echo "slate" ;;
    strategy*)         echo "violet" ;;
    support)           echo "lime" ;;
    testing)           echo "amber" ;;
    scripts)           echo "stone" ;;
    examples)          echo "zinc" ;;
    integrations*)     echo "emerald" ;;
    *)                 echo "gray" ;;
  esac
}

get_category_emoji() {
  case "$1" in
    academic)          echo "📚" ;;
    design)            echo "🎨" ;;
    engineering)       echo "🏗️" ;;
    game-development*) echo "🎮" ;;
    marketing)         echo "📣" ;;
    paid-media)        echo "💸" ;;
    product)           echo "📊" ;;
    project-management) echo "📋" ;;
    sales)             echo "💼" ;;
    spatial-computing) echo "🥽" ;;
    specialized)       echo "🎯" ;;
    strategy*)         echo "♟️" ;;
    support)           echo "🛟" ;;
    testing)           echo "🧪" ;;
    scripts)           echo "📜" ;;
    examples)          echo "📖" ;;
    integrations*)     echo "🔌" ;;
    *)                 echo "🤖" ;;
  esac
}

get_category_risk() {
  local cat="$1"
  local name="$2"  # agent filename — detectar security/compliance
  # Agentes de seguridad/compliance siempre al menos medium
  if printf '%s' "$name" | grep -qiE 'security|compliance|threat|blockchain|auth|hipaa|privacy|audit'; then
    echo "high"; return
  fi
  # Agentes que tocan pagos/financiero
  if printf '%s' "$name" | grep -qiE 'payment|billing|finance|accounting|payroll|tax'; then
    echo "high"; return
  fi
  case "$cat" in
    engineering|strategy*|specialized|sales|support|scripts|integrations*) echo "medium" ;;
    *) echo "low" ;;
  esac
}

# ─── Frontmatter extraction ────────────────────────────────────────────────
get_field() {
  local fm="$1" key="$2"
  printf '%s\n' "$fm" | awk -v k="$key" '
    $0 ~ "^"k":" {
      sub("^"k":[[:space:]]*", "")
      gsub(/^[\x27"]|[\x27"]$/, "")
      print; exit
    }'
}

# ─── Build proposed frontmatter ────────────────────────────────────────────
propose_frontmatter() {
  local file="$1"

  # Category = primer segmento después de AGENTS_DIR
  local rel="${file#$AGENTS_DIR/}"
  local cat
  cat=$(dirname "$rel" | awk -F/ '{print $1}')
  [[ "$cat" == "." ]] && cat="_root"

  local agent_name
  agent_name=$(basename "$file" .md)

  local fm
  fm=$(awk '/^---$/{c++; next} c==1{print} c>=2{exit}' "$file")

  local name desc color emoji vibe status risk last_reviewed reviewed_by version
  name=$(get_field "$fm" "name")
  desc=$(get_field "$fm" "description")
  color=$(get_field "$fm" "color")
  emoji=$(get_field "$fm" "emoji")
  vibe=$(get_field "$fm" "vibe")
  status=$(get_field "$fm" "status")
  risk=$(get_field "$fm" "risk_level")
  last_reviewed=$(get_field "$fm" "last_reviewed")
  reviewed_by=$(get_field "$fm" "reviewed_by")
  version=$(get_field "$fm" "version")

  local changes=()

  # Fill missing with heuristics
  if [[ -z "$color" ]]; then
    color=$(get_category_color "$cat")
    changes+=("+color: $color (heurística por categoría)")
  fi
  if [[ -z "$emoji" ]]; then
    emoji=$(get_category_emoji "$cat")
    changes+=("+emoji: $emoji (heurística por categoría)")
  fi
  if [[ -z "$status" ]]; then
    status="active"
    changes+=("+status: active (default)")
  fi
  if [[ -z "$risk" ]]; then
    risk=$(get_category_risk "$cat" "$agent_name")
    changes+=("+risk_level: $risk (heurística)")
  fi
  if [[ -z "$last_reviewed" ]]; then
    last_reviewed="$TODAY"
    changes+=("+last_reviewed: $TODAY")
  fi
  if [[ -z "$reviewed_by" ]]; then
    reviewed_by="$REVIEWER"
    changes+=("+reviewed_by: $REVIEWER")
  fi
  if [[ -z "$version" ]]; then
    version="1.0.0"
    changes+=("+version: 1.0.0 (default inicial)")
  fi

  # Truncate description if >160
  if [[ -n "$desc" ]] && [[ ${#desc} -gt 160 ]]; then
    local new_desc="${desc:0:157}..."
    changes+=("~description: truncado ${#desc}→160 chars")
    desc="$new_desc"
  fi

  # vibe: NO se auto-completa. Se reporta como gap pero no se rellena.
  local vibe_note=""
  if [[ -z "$vibe" ]]; then
    vibe_note="# (vibe no propuesto — editar manualmente, debe capturar la personalidad)"
  fi

  # ─── Build new frontmatter ──────────────────────────────────────────────
  # Preserve body exactly
  local body
  body=$(awk '/^---$/{c++; next} c>=2{print}' "$file")

  # Emit to stdout as "proposed file"
  {
    echo "---"
    [[ -n "$name" ]] && echo "name: $name"
    [[ -n "$desc" ]] && echo "description: $desc"
    [[ -n "$color" ]] && echo "color: $color"
    [[ -n "$emoji" ]] && echo "emoji: $emoji"
    if [[ -n "$vibe" ]]; then
      echo "vibe: $vibe"
    elif [[ -n "$vibe_note" ]]; then
      echo "vibe: TODO $vibe_note"
    fi
    echo "version: $version"
    echo "status: $status"
    echo "risk_level: $risk"
    echo "last_reviewed: $last_reviewed"
    echo "reviewed_by: $reviewed_by"

    # Preserve any additional fields from original frontmatter that we didn't touch
    # (tags, services, hipaa_safe, supersededBy)
    for extra in tags services hipaa_safe supersededBy; do
      local val
      val=$(get_field "$fm" "$extra")
      if [[ -n "$val" ]]; then
        echo "$extra: $val"
      fi
    done
    # Multi-line fields (tags as list, services as list) — copy raw block if present
    # Simplified: awk to extract blocks starting with "tags:" or "services:"
    awk '
      /^tags:$/ || /^services:$/ { in_block = 1; print; next }
      /^[a-zA-Z_]+:/ { in_block = 0; next }
      in_block && /^[[:space:]]/ { print; next }
    ' <(printf '%s\n' "$fm")

    echo "---"
    printf '%s\n' "$body"
  }

  # Print changes summary to stderr
  if [[ ${#changes[@]} -gt 0 ]]; then
    echo "" >&2
    echo "━━━ Cambios propuestos para $rel ━━━" >&2
    for c in "${changes[@]}"; do
      echo "   $c" >&2
    done
    if [[ -n "$vibe_note" ]]; then
      echo "   ⚠️  vibe ausente — no auto-completado ($vibe_note)" >&2
    fi
  else
    echo "   (sin cambios — ya cumple schema)" >&2
  fi
}

# ─── CLI ────────────────────────────────────────────────────────────────────
MODE="dry-run"  # dry-run | apply | apply-all | dry-run-all
FILE=""

for arg in "$@"; do
  case "$arg" in
    --apply) MODE="apply" ;;
    --apply-all) MODE="apply-all" ;;
    --dry-run-all) MODE="dry-run-all" ;;
    --dry-run) MODE="dry-run" ;;
    --help|-h) grep '^#' "$0" | head -25; exit 0 ;;
    *) FILE="$arg" ;;
  esac
done

# ─── Execute ────────────────────────────────────────────────────────────────
apply_one() {
  local file="$1"
  local proposed
  proposed=$(propose_frontmatter "$file" 2>/dev/null)
  # Backup original
  cp "$file" "$file.bak"
  printf '%s' "$proposed" > "$file"
  echo "   ✅ aplicado → backup: $file.bak" >&2
}

case "$MODE" in
  dry-run)
    if [[ -z "$FILE" ]]; then
      echo "ERROR: provide a file or use --dry-run-all / --apply-all" >&2
      exit 2
    fi
    [[ ! -f "$FILE" ]] && { echo "ERROR: file not found: $FILE" >&2; exit 2; }
    echo "=== DRY-RUN: propuesta para $FILE ==="
    propose_frontmatter "$FILE"
    ;;

  apply)
    if [[ -z "$FILE" ]]; then
      echo "ERROR: --apply requires a file argument" >&2
      exit 2
    fi
    [[ ! -f "$FILE" ]] && { echo "ERROR: file not found: $FILE" >&2; exit 2; }
    echo "=== APPLY: modificando $FILE ==="
    apply_one "$FILE"
    ;;

  dry-run-all)
    FILES=()
    while IFS= read -r f; do
      FILES+=("$f")
    done < <(find "$AGENTS_DIR" -type f -name "*.md" \
      ! -name "SCHEMA.md" ! -name "AGENTS_INDEX.md" ! -name "OVERLAP_MAP.md" \
      ! -name "README.md" ! -name "INDEX.md" ! -name ".*" | sort)

    echo "=== DRY-RUN-ALL: ${#FILES[@]} agentes ==="
    total_changes=0
    for f in "${FILES[@]}"; do
      rel="${f#$AGENTS_DIR/}"
      num_changes=$(propose_frontmatter "$f" 2>&1 >/dev/null | grep -c '^   [+~]' || true)
      if [[ "$num_changes" -gt 0 ]]; then
        echo "  $rel → $num_changes cambios"
        total_changes=$((total_changes + num_changes))
      fi
    done
    echo ""
    echo "Total cambios propuestos: $total_changes"
    echo "Para aplicar: $0 --apply-all"
    ;;

  apply-all)
    FILES=()
    while IFS= read -r f; do
      FILES+=("$f")
    done < <(find "$AGENTS_DIR" -type f -name "*.md" \
      ! -name "SCHEMA.md" ! -name "AGENTS_INDEX.md" ! -name "OVERLAP_MAP.md" \
      ! -name "README.md" ! -name "INDEX.md" ! -name ".*" | sort)

    echo "=== APPLY-ALL: ${#FILES[@]} agentes ==="
    echo "⚠️  Esto modificará todos los agentes. Cada uno tendrá backup .bak"
    echo -n "Continuar? [y/N]: "
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Cancelado."
      exit 0
    fi
    applied=0
    for f in "${FILES[@]}"; do
      rel="${f#$AGENTS_DIR/}"
      echo "[$((applied+1))/${#FILES[@]}] $rel"
      apply_one "$f"
      applied=$((applied+1))
    done
    echo ""
    echo "✅ $applied archivos procesados. Backups: *.bak"
    echo "Para revertir: find $AGENTS_DIR -name '*.bak' -exec sh -c 'mv \"\$1\" \"\${1%.bak}\"' _ {} \\;"
    ;;
esac
