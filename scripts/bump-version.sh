#!/usr/bin/env bash
# bump-version.sh — Semver bump helper: CHANGELOG + tag anotado (sin push).
#
# Uso:
#   bump-version.sh <patch|minor|major>        # ejecuta el bump
#   bump-version.sh <patch|minor|major> --dry-run  # solo muestra qué haría
#   bump-version.sh --help
#
# Flujo:
#   1. Lee última versión desde `git describe --tags --abbrev=0`
#   2. Calcula nueva versión (patch|minor|major)
#   3. Mueve contenido de [Unreleased] a [X.Y.Z] - YYYY-MM-DD en CHANGELOG.md
#   4. Commit del CHANGELOG
#   5. Crea tag anotado vX.Y.Z con mensaje auto-generado
#   6. NO hace push — el usuario decide cuándo
#
# Owner: Froni Jimenez | Creado: 2026-04-24 | v1.0.0

set -euo pipefail

# ─── Colores (solo TTY) ────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; YLW=$'\033[1;33m'; GRN=$'\033[0;32m'; BLD=$'\033[1m'; NC=$'\033[0m'
else
  RED=""; YLW=""; GRN=""; BLD=""; NC=""
fi

# ─── Args ──────────────────────────────────────────────────────────────────
BUMP_TYPE=""
DRY_RUN=0

show_help() {
  grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -20
}

for arg in "$@"; do
  case "$arg" in
    patch|minor|major) BUMP_TYPE="$arg" ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) show_help; exit 0 ;;
    *) echo "${RED}ERROR: argumento desconocido: $arg${NC}" >&2; show_help; exit 2 ;;
  esac
done

if [[ -z "$BUMP_TYPE" ]]; then
  echo "${RED}ERROR: falta tipo de bump (patch|minor|major)${NC}" >&2
  show_help
  exit 2
fi

# ─── Repo root + archivos ──────────────────────────────────────────────────
REPO_ROOT=$(git rev-parse --show-toplevel)
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
  echo "${RED}ERROR: CHANGELOG.md no existe en $REPO_ROOT${NC}" >&2
  exit 1
fi

# ─── Leer versión actual ───────────────────────────────────────────────────
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [[ -z "$CURRENT_TAG" ]]; then
  echo "${YLW}⚠ No hay tags previos. Asumiendo v0.0.0 como base.${NC}" >&2
  CURRENT_TAG="v0.0.0"
fi

# Normalizar: quitar prefijo 'v' si existe
CURRENT_VERSION="${CURRENT_TAG#v}"

# Validar formato X.Y.Z
if ! [[ "$CURRENT_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "${RED}ERROR: versión actual no es semver válido: $CURRENT_VERSION${NC}" >&2
  exit 1
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

# ─── Calcular nueva versión ────────────────────────────────────────────────
case "$BUMP_TYPE" in
  patch) PATCH=$((PATCH+1)) ;;
  minor) MINOR=$((MINOR+1)); PATCH=0 ;;
  major) MAJOR=$((MAJOR+1)); MINOR=0; PATCH=0 ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
NEW_TAG="v${NEW_VERSION}"
TODAY=$(date +%Y-%m-%d)

echo "${BLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLD}  Version bump: ${CURRENT_TAG} → ${NEW_TAG} (${BUMP_TYPE})${NC}"
echo "${BLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ─── Validar que [Unreleased] existe y tiene contenido ─────────────────────
if ! grep -q '^## \[Unreleased\]' "$CHANGELOG"; then
  echo "${RED}ERROR: sección [Unreleased] no encontrada en CHANGELOG.md${NC}" >&2
  exit 1
fi

# ─── Plan (siempre mostrado) ───────────────────────────────────────────────
echo ""
echo "${BLD}Plan:${NC}"
echo "  1. Actualizar $CHANGELOG:"
echo "     - Renombrar [Unreleased] → [${NEW_VERSION}] - ${TODAY}"
echo "     - Insertar nueva sección [Unreleased] vacía arriba"
echo "     - Actualizar links de comparación al final"
echo "  2. git add CHANGELOG.md"
echo "  3. git commit -m 'chore: release ${NEW_TAG}'"
echo "  4. git tag -a ${NEW_TAG} -m 'Release ${NEW_TAG}'"
echo "  5. ${YLW}NO push automático${NC} (el usuario decide)"
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
  echo "${YLW}[DRY-RUN] No se modificó nada. Re-ejecuta sin --dry-run para aplicar.${NC}"
  exit 0
fi

# ─── Verificar working tree limpio ─────────────────────────────────────────
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "${RED}ERROR: working tree tiene cambios sin commit. Limpia o commitea primero.${NC}" >&2
  git status --short >&2
  exit 1
fi

# ─── Actualizar CHANGELOG.md ───────────────────────────────────────────────
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

awk -v new_ver="$NEW_VERSION" -v today="$TODAY" '
  /^## \[Unreleased\]/ && !done {
    print "## [Unreleased]"
    print ""
    print "### Added"
    print "- _(pendiente)_"
    print ""
    print "### Changed"
    print "- _(pendiente)_"
    print ""
    print "### Deprecated"
    print "- _(pendiente)_"
    print ""
    print "### Removed"
    print "- _(pendiente)_"
    print ""
    print "### Fixed"
    print "- _(pendiente)_"
    print ""
    print "### Security"
    print "- _(pendiente)_"
    print ""
    print "---"
    print ""
    print "## [" new_ver "] - " today
    done=1
    next
  }
  { print }
' "$CHANGELOG" > "$TMP"

# Actualizar links al final si existen
if grep -q '^\[Unreleased\]:' "$TMP"; then
  # Append nuevo link de comparación para la versión
  sed -i.bak \
    -e "s|^\[Unreleased\]:.*compare/v[^.]*\.[^.]*\.[^.]*\.\.\.HEAD|[Unreleased]: https://github.com/infofronijimenez-hue/andale-agents-system/compare/${NEW_TAG}...HEAD|" \
    "$TMP"
  rm -f "$TMP.bak"

  # Insertar link de la nueva versión si no existe
  if ! grep -q "^\[${NEW_VERSION}\]:" "$TMP"; then
    CURRENT_VER_ONLY="${CURRENT_TAG#v}"
    echo "[${NEW_VERSION}]: https://github.com/infofronijimenez-hue/andale-agents-system/compare/v${CURRENT_VER_ONLY}...${NEW_TAG}" >> "$TMP"
  fi
fi

mv "$TMP" "$CHANGELOG"
trap - EXIT

echo "${GRN}✓ CHANGELOG.md actualizado${NC}"

# ─── Commit ────────────────────────────────────────────────────────────────
git add "$CHANGELOG"
git commit -m "chore: release ${NEW_TAG}"
echo "${GRN}✓ Commit creado${NC}"

# ─── Tag anotado ───────────────────────────────────────────────────────────
TAG_MSG="Release ${NEW_TAG}

Bump: ${BUMP_TYPE} (${CURRENT_TAG} → ${NEW_TAG})
Fecha: ${TODAY}

Ver CHANGELOG.md para el detalle de cambios."

git tag -a "$NEW_TAG" -m "$TAG_MSG"
echo "${GRN}✓ Tag anotado creado: ${NEW_TAG}${NC}"

# ─── Resumen final ─────────────────────────────────────────────────────────
echo ""
echo "${BLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${GRN}${BLD}  ✓ Bump completado localmente${NC}"
echo "${BLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Para publicar:"
echo "  ${BLD}git push origin main && git push origin ${NEW_TAG}${NC}"
echo ""
echo "Para revertir antes de push:"
echo "  git tag -d ${NEW_TAG}"
echo "  git reset --hard HEAD~1"
