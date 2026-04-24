#!/usr/bin/env bash
# lint-agent.sh — Valida un agente contra SCHEMA.md y detecta prompt injection.
#
# Uso:
#   lint-agent.sh <ruta-al-agente.md>
#   lint-agent.sh --quiet <ruta>      # solo exit code, sin output
#   lint-agent.sh --json <ruta>       # output JSON
#
# Exit codes:
#   0 = clean (sin findings)
#   1 = warnings (frontmatter incompleto, tags no canónicos)
#   2 = critical (prompt injection detectado, campos obligatorios faltantes)
#
# Owner: Froni Jimenez | Creado: 2026-04-24 | v1.0.0

set -euo pipefail

# ─── Config ────────────────────────────────────────────────────────────────
# Críticos: esenciales para identificación del agente. Sin estos el agente
# no puede ser referenciado ni usado.
REQUIRED_FIELDS=("name" "description")
# Recomendados: ausencia se reporta como warning, no crítico.
RECOMMENDED_FIELDS=("color" "vibe" "emoji")
VALID_STATUS=("active" "beta" "deprecated" "superseded")
VALID_RISK=("low" "medium" "high" "critical")
MAX_DESCRIPTION_LEN=160

# Dominios de exfiltración conocidos (allowlist-style: rechazamos estos)
EXFIL_DOMAINS='webhook\.site|pastebin\.com|transfer\.sh|paste\.ee|ngrok\.io|requestcatcher\.com|beeceptor\.com|hookb\.in|postb\.in|pipedream\.net|eo\.dnslog\.cn|burpcollaborator'

# ─── CLI parsing ────────────────────────────────────────────────────────────
QUIET=0
JSON=0
FILE=""
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=1 ;;
    --json) JSON=1 ;;
    -h|--help)
      grep '^#' "$0" | head -20
      exit 0
      ;;
    *) FILE="$arg" ;;
  esac
done

if [[ -z "$FILE" ]]; then
  echo "ERROR: provide a .md agent file" >&2
  echo "Usage: $0 <file.md>" >&2
  exit 2
fi

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: file not found: $FILE" >&2
  exit 2
fi

# ─── Output helpers ────────────────────────────────────────────────────────
CRITICAL=()
WARNINGS=()
INFO=()

add_critical() { CRITICAL+=("$1"); }
add_warning()  { WARNINGS+=("$1"); }
add_info()     { INFO+=("$1"); }

# ─── Parse frontmatter ──────────────────────────────────────────────────────
# Extract lines between first two '---' markers
FM=$(awk '/^---$/{c++; next} c==1{print} c>=2{exit}' "$FILE")
BODY=$(awk '/^---$/{c++; next} c>=2{print}' "$FILE")

# BODY_NOCODE: body con bloques ``` ... ``` sustituidos por líneas vacías
# (preserva numeración, evita falsos positivos en ejemplos didácticos)
BODY_NOCODE=$(printf '%s\n' "$BODY" | awk '
  /^[[:space:]]*```/ { in_code = !in_code; print ""; next }
  { if (in_code) print ""; else print }
')

if [[ -z "$FM" ]]; then
  add_critical "Frontmatter missing or malformed (no --- delimiters)"
fi

# Extract a scalar field from frontmatter (handles "key: value")
get_field() {
  local key="$1"
  printf '%s\n' "$FM" | awk -v k="$key" '
    $0 ~ "^"k":" {
      sub("^"k":[[:space:]]*", "")
      gsub(/^[\x27"]|[\x27"]$/, "")
      print; exit
    }'
}

# ─── Validate required fields ───────────────────────────────────────────────
for f in "${REQUIRED_FIELDS[@]}"; do
  val=$(get_field "$f")
  if [[ -z "$val" ]]; then
    add_critical "Required field missing: $f"
  fi
done

for f in "${RECOMMENDED_FIELDS[@]}"; do
  val=$(get_field "$f")
  if [[ -z "$val" ]]; then
    add_warning "Recommended field missing: $f"
  fi
done

# description length
DESC=$(get_field "description")
if [[ -n "$DESC" ]] && [[ ${#DESC} -gt $MAX_DESCRIPTION_LEN ]]; then
  add_warning "description too long: ${#DESC} chars (max $MAX_DESCRIPTION_LEN)"
fi

# ─── Validate optional enum fields ──────────────────────────────────────────
STATUS=$(get_field "status")
if [[ -n "$STATUS" ]]; then
  valid=0
  for s in "${VALID_STATUS[@]}"; do [[ "$STATUS" == "$s" ]] && valid=1; done
  if [[ $valid -eq 0 ]]; then
    add_warning "status '$STATUS' not in: ${VALID_STATUS[*]}"
  fi
fi

RISK=$(get_field "risk_level")
if [[ -n "$RISK" ]]; then
  valid=0
  for r in "${VALID_RISK[@]}"; do [[ "$RISK" == "$r" ]] && valid=1; done
  if [[ $valid -eq 0 ]]; then
    add_warning "risk_level '$RISK' not in: ${VALID_RISK[*]}"
  fi
fi

# version — recommend semver if present
VERSION=$(get_field "version")
if [[ -n "$VERSION" ]] && ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  add_warning "version '$VERSION' not semver (X.Y.Z)"
fi

# superseded must have supersededBy
if [[ "$STATUS" == "superseded" ]]; then
  SB=$(get_field "supersededBy")
  if [[ -z "$SB" ]] || [[ "$SB" == "null" ]]; then
    add_critical "status=superseded requires supersededBy field"
  fi
fi

# ─── services: allowlist validation ────────────────────────────────────────
# Dominios conocidos seguros (ampliable). Un `services.url` fuera de este set
# dispara warning — no crítico (puede ser un servicio legítimo no listado).
SAFE_DOMAINS_REGEX='(api\.anthropic\.com|openai\.com|googleapis\.com|github\.com|vercel\.com|supabase\.(co|com)|posthog\.com|sentry\.io|stripe\.com|cloudflare\.com|aistudio\.google\.com|deepmind\.google|huggingface\.co|langsmith\.com|langfuse\.com|n8n\.io|ghl\.com|gohighlevel\.com|notion\.so|notion\.com|atlassian\.com|linear\.app|slack\.com|zoom\.us|figma\.com|upload-post\.com|api\.upload-post\.com|docs\.upload-post\.com)'

SERVICES_URLS=$(printf '%s\n' "$FM" | awk '/^[[:space:]]+url:/{sub(/^[[:space:]]+url:[[:space:]]*/,""); gsub(/^["\x27]|["\x27]$/,""); print}')
if [[ -n "$SERVICES_URLS" ]]; then
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    if ! printf '%s' "$url" | grep -qiE "$SAFE_DOMAINS_REGEX"; then
      add_warning "services.url fuera de allowlist conocida: $url (revisar manualmente)"
    fi
  done <<< "$SERVICES_URLS"
fi

# ─── last_reviewed staleness check ─────────────────────────────────────────
LAST_REVIEWED=$(get_field "last_reviewed")
if [[ -n "$LAST_REVIEWED" ]]; then
  # Portable date diff (macOS BSD date vs GNU date)
  if date -j -f "%Y-%m-%d" "$LAST_REVIEWED" +%s >/dev/null 2>&1; then
    reviewed_epoch=$(date -j -f "%Y-%m-%d" "$LAST_REVIEWED" +%s 2>/dev/null)
  elif date -d "$LAST_REVIEWED" +%s >/dev/null 2>&1; then
    reviewed_epoch=$(date -d "$LAST_REVIEWED" +%s 2>/dev/null)
  else
    reviewed_epoch=""
    add_warning "last_reviewed format inválido: '$LAST_REVIEWED' (usa YYYY-MM-DD)"
  fi
  if [[ -n "$reviewed_epoch" ]]; then
    now_epoch=$(date +%s)
    age_days=$(( (now_epoch - reviewed_epoch) / 86400 ))
    if (( age_days > 90 )); then
      add_warning "last_reviewed stale: ${age_days} días (>90) — re-auditar"
    fi
  fi
fi

# ─── PROMPT INJECTION DETECTION (the core security check) ──────────────────
# Escanea en BODY_NOCODE por default (ignora bloques ```...```)
# Si la variable IGNORE_CODE_BLOCKS=0, escanea body completo (más estricto).
IGNORE_CODE_BLOCKS="${IGNORE_CODE_BLOCKS:-1}"

scan_body() {
  local pattern="$1"
  local label="$2"
  local severity="$3"
  local target_body
  if [[ "$IGNORE_CODE_BLOCKS" == "1" ]]; then
    target_body="$BODY_NOCODE"
  else
    target_body="$BODY"
  fi
  if printf '%s' "$target_body" | grep -iEn "$pattern" >/dev/null 2>&1; then
    local lines
    lines=$(printf '%s' "$target_body" | grep -iEn "$pattern" | head -3 | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
    if [[ "$severity" == "critical" ]]; then
      add_critical "Injection pattern [$label] at body lines: $lines"
    else
      add_warning "Suspicious pattern [$label] at body lines: $lines"
    fi
  fi
}

# Instruction hijacking
scan_body 'ignore[[:space:]]+(all[[:space:]]+)?(previous|above|prior)[[:space:]]+(instructions?|prompts?|directives?|rules?)' \
          "instruction-hijack" "critical"
scan_body 'disregard[[:space:]]+(the[[:space:]]+)?(system[[:space:]]+prompt|previous)' \
          "disregard-prompt" "critical"
# "forget everything you know about X" es didáctico legítimo y NO debe disparar.
# Solo disparamos cuando 'forget' va acompañado de términos de control del LLM.
scan_body 'forget[[:space:]]+(everything|all[[:space:]]+previous|prior)[[:space:]]+(instructions?|prompts?|rules?|directives?|system)' \
          "forget-instructions" "critical"

# Role spoofing (outside code blocks is harder; flag any occurrence for review)
scan_body '^[[:space:]]*(system|assistant)[[:space:]]*:' "role-spoofing" "warning"

# Exfiltration domains
scan_body "($EXFIL_DOMAINS)" "exfil-domain" "critical"

# Active network commands piped to shell
scan_body 'curl[[:space:]]+[^|]*\|[[:space:]]*(bash|sh|zsh)' "curl-pipe-shell" "critical"
scan_body 'wget[[:space:]]+[^|]*\|[[:space:]]*(bash|sh|zsh)' "wget-pipe-shell" "critical"
scan_body 'curl[[:space:]]+(-X[[:space:]]+POST|--data|-d[[:space:]])' "curl-active-post" "warning"

# Destructive
scan_body 'rm[[:space:]]+-rf[[:space:]]+(/|~|\$HOME)([[:space:]]|$)' "destructive-rm" "critical"
scan_body 'sudo[[:space:]]+rm[[:space:]]+-rf' "sudo-rm" "critical"

# Eval over dynamic input
scan_body '\beval[[:space:]]*\([^)]*\$' "eval-dynamic" "warning"

# Base64 payloads (check for long base64 strings — potential hidden commands)
if printf '%s' "$BODY" | grep -iE '[A-Za-z0-9+/=]{500,}' >/dev/null 2>&1; then
  add_warning "Long base64-like string detected (>500 chars) — possible hidden payload"
fi

# base64 decode followed by execution
scan_body 'base64[[:space:]]+(--decode|-d)[[:space:]]*\|[[:space:]]*(bash|sh)' \
          "base64-decode-exec" "critical"

# ─── Output ─────────────────────────────────────────────────────────────────
N_CRIT=${#CRITICAL[@]}
N_WARN=${#WARNINGS[@]}

if [[ $JSON -eq 1 ]]; then
  printf '{'
  printf '"file":"%s",' "$FILE"
  printf '"critical":%d,' "$N_CRIT"
  printf '"warnings":%d,' "$N_WARN"
  printf '"findings":['
  sep=""
  if [[ $N_CRIT -gt 0 ]]; then
    for c in "${CRITICAL[@]}"; do
      printf '%s{"severity":"critical","msg":"%s"}' "$sep" "$(printf '%s' "$c" | sed 's/"/\\"/g')"
      sep=","
    done
  fi
  if [[ $N_WARN -gt 0 ]]; then
    for w in "${WARNINGS[@]}"; do
      printf '%s{"severity":"warning","msg":"%s"}' "$sep" "$(printf '%s' "$w" | sed 's/"/\\"/g')"
      sep=","
    done
  fi
  printf ']}\n'
elif [[ $QUIET -eq 0 ]]; then
  if [[ $N_CRIT -eq 0 && $N_WARN -eq 0 ]]; then
    echo "✅ $FILE — clean"
  else
    echo "📄 $FILE"
    if [[ $N_CRIT -gt 0 ]]; then
      for c in "${CRITICAL[@]}"; do echo "   ❌ CRITICAL: $c"; done
    fi
    if [[ $N_WARN -gt 0 ]]; then
      for w in "${WARNINGS[@]}"; do echo "   ⚠️  WARN:     $w"; done
    fi
  fi
fi

# Exit code
if   [[ $N_CRIT -gt 0 ]]; then exit 2
elif [[ $N_WARN -gt 0 ]]; then exit 1
else exit 0
fi
