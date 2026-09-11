#!/usr/bin/env bash
# Configura Pegasus + ATTRACT en macOS sin dependencias externas.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
PEGASUS_APP=""
CONFIG_DIR=""
USE_FIXTURES=0
SKIP_LAUNCH=0
SKIP_PROCESS_CONTROL=0
DRY_RUN=0
GAME_DIRS=()

usage() {
  cat <<'EOF'
Uso: configure-pegasus-macos.sh [opciones]

  --project-root RUTA       checkout de ATTRACT
  --pegasus-app RUTA        ruta a Pegasus.app
  --config-directory RUTA   config normal o portable de Pegasus
  --game-directory RUTA     coleccion explicita (se puede repetir)
  --use-fixtures            fuerza fixtures/arcade como demostracion
  --skip-launch             no abre Pegasus al terminar
  --dry-run                 muestra el plan sin modificar nada
  --help                    muestra esta ayuda
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

absolute_dir() {
  local path="$1"
  local label="$2"
  [ -d "$path" ] || die "$label no existe o no es un directorio: $path"
  (cd "$path" && pwd -P)
}

valid_game_dir() {
  local metadata="$1/metadata.pegasus.txt"
  [ -s "$metadata" ] || return 1
  if ! awk '
    /^collection:[[:space:]]*[^[:space:]]/ { collection = 1 }
    /^game:[[:space:]]*[^[:space:]]/ { if (!collection) invalid = 1 }
    END { exit invalid ? 1 : 0 }
  ' "$metadata"; then
    die "Metadata sin collection: antes de game: en $metadata. Reimporta el paquete COINDOOR."
  fi
  grep -Eq '^game:[[:space:]]*[^[:space:]]' "$metadata"
}

backup_path() {
  local base="$1"
  local timestamp="$2"
  local candidate="${base}.bak-${timestamp}"
  local number=1
  while [ -e "$candidate" ]; do
    candidate="${base}.bak-${timestamp}-${number}"
    number=$((number + 1))
  done
  printf '%s\n' "$candidate"
}

backup_file() {
  local path="$1"
  local timestamp="$2"
  local backup
  [ -f "$path" ] || return 0
  backup="$(backup_path "$path" "$timestamp")"
  cp "$path" "$backup"
  printf '%s\n' "$backup"
}

set_setting() {
  local path="$1"
  local key="$2"
  local value="$3"
  local temp
  temp="$(mktemp "${path}.tmp.XXXXXX")"

  if [ -f "$path" ]; then
    awk -v key="$key" -v value="$value" '
      BEGIN { found = 0 }
      { sub(/\r$/, "") }
      index($0, key ":") == 1 {
        if (!found) print key ": " value
        found = 1
        next
      }
      { print }
      END { if (!found) print key ": " value }
    ' "$path" > "$temp"
  else
    printf '%s: %s\n' "$key" "$value" > "$temp"
  fi
  mv "$temp" "$path"
}

stop_pegasus() {
  command -v pgrep >/dev/null 2>&1 || return 0
  pgrep -x pegasus-fe >/dev/null 2>&1 || return 0

  printf 'Cerrando Pegasus para que no pise la configuracion...\n'
  if command -v osascript >/dev/null 2>&1; then
    osascript -e 'tell application "Pegasus" to quit' >/dev/null 2>&1 || true
  fi

  local attempt=0
  while pgrep -x pegasus-fe >/dev/null 2>&1 && [ "$attempt" -lt 20 ]; do
    sleep 0.5
    attempt=$((attempt + 1))
  done
  if pgrep -x pegasus-fe >/dev/null 2>&1; then
    pkill -x pegasus-fe
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root)
      [ "$#" -ge 2 ] || die "falta el valor de $1"
      PROJECT_ROOT="$2"
      shift 2
      ;;
    --pegasus-app)
      [ "$#" -ge 2 ] || die "falta el valor de $1"
      PEGASUS_APP="$2"
      shift 2
      ;;
    --config-directory)
      [ "$#" -ge 2 ] || die "falta el valor de $1"
      CONFIG_DIR="$2"
      shift 2
      ;;
    --game-directory)
      [ "$#" -ge 2 ] || die "falta el valor de $1"
      GAME_DIRS+=("$2")
      shift 2
      ;;
    --use-fixtures)
      USE_FIXTURES=1
      shift
      ;;
    --skip-launch)
      SKIP_LAUNCH=1
      shift
      ;;
    --skip-process-control)
      SKIP_PROCESS_CONTROL=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "opcion desconocida: $1"
      ;;
  esac
done

PROJECT_ROOT="$(absolute_dir "$PROJECT_ROOT" "El proyecto")"
THEME_SOURCE="$(absolute_dir "$PROJECT_ROOT/themes/attract" "El theme ATTRACT")"
[ -f "$THEME_SOURCE/theme.cfg" ] || die "El theme esta incompleto: falta theme.cfg"
[ -f "$THEME_SOURCE/theme.qml" ] || die "El theme esta incompleto: falta theme.qml"

if [ -z "$PEGASUS_APP" ]; then
  PEGASUS_APP="$PROJECT_ROOT/pegasus/Pegasus.app"
fi
PEGASUS_EXE="$PEGASUS_APP/Contents/MacOS/pegasus-fe"
if [ "$SKIP_LAUNCH" -eq 0 ]; then
  [ -d "$PEGASUS_APP" ] || die "No se encontro Pegasus.app: $PEGASUS_APP"
  [ -f "$PEGASUS_EXE" ] || die "No se encontro el ejecutable de Pegasus: $PEGASUS_EXE"
fi

if [ -z "$CONFIG_DIR" ]; then
  if [ -f "$(dirname "$PEGASUS_EXE")/portable.txt" ]; then
    CONFIG_DIR="$(dirname "$PEGASUS_EXE")/config"
  else
    [ -n "${HOME:-}" ] || die "HOME no esta definido; usa --config-directory"
    CONFIG_DIR="$HOME/Library/Preferences/pegasus-frontend"
  fi
fi

[ "$USE_FIXTURES" -eq 0 ] || [ "${#GAME_DIRS[@]}" -eq 0 ] || \
  die "usa --use-fixtures o --game-directory, no ambos"

SELECTED_DIRS=()
USING_FIXTURES=0
if [ "$USE_FIXTURES" -eq 1 ]; then
  fixture="$(absolute_dir "$PROJECT_ROOT/fixtures/arcade" "El fixture Arcade")"
  valid_game_dir "$fixture" || die "El fixture no contiene metadata valida: $fixture"
  SELECTED_DIRS+=("$fixture")
  USING_FIXTURES=1
elif [ "${#GAME_DIRS[@]}" -gt 0 ]; then
  for directory in "${GAME_DIRS[@]}"; do
    resolved="$(absolute_dir "$directory" "La coleccion")"
    valid_game_dir "$resolved" || \
      die "La coleccion no tiene metadata valida con al menos un juego: $resolved"
    SELECTED_DIRS+=("$resolved")
  done
else
  library="$(absolute_dir "$PROJECT_ROOT/library" "La libreria")"
  for directory in "$library"/*; do
    [ -d "$directory" ] || continue
    name="$(basename "$directory")"
    case "$name" in _*) continue ;; esac
    if valid_game_dir "$directory"; then
      SELECTED_DIRS+=("$(cd "$directory" && pwd -P)")
    fi
  done
  if [ "${#SELECTED_DIRS[@]}" -eq 0 ]; then
    fixture="$(absolute_dir "$PROJECT_ROOT/fixtures/arcade" "El fixture Arcade")"
    valid_game_dir "$fixture" || die "No hay colecciones reales ni un fixture Arcade valido"
    SELECTED_DIRS+=("$fixture")
    USING_FIXTURES=1
  fi
fi

printf 'Configuracion de Pegasus para macOS\n'
printf '  Proyecto : %s\n' "$PROJECT_ROOT"
printf '  Config   : %s\n' "$CONFIG_DIR"
printf '  Theme    : %s\n' "$THEME_SOURCE"
printf '  Juegos   :\n'
for directory in "${SELECTED_DIRS[@]}"; do
  printf '    %s\n' "$directory"
done
if [ "$USING_FIXTURES" -eq 1 ]; then
  printf 'AVISO: no hay una coleccion real valida; se usara fixtures/arcade como demostracion.\n' >&2
fi
if [ "$DRY_RUN" -eq 1 ]; then
  printf 'DRY RUN: no se modifico nada.\n'
  exit 0
fi

if [ "$SKIP_PROCESS_CONTROL" -eq 0 ]; then
  stop_pegasus
fi

mkdir -p "$CONFIG_DIR"
THEMES_ROOT="$CONFIG_DIR/themes"
THEME_BACKUPS_ROOT="$CONFIG_DIR/backups/themes"
mkdir -p "$THEMES_ROOT" "$THEME_BACKUPS_ROOT"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

THEME_TARGET="$THEMES_ROOT/attract"
THEME_STAGE="$THEMES_ROOT/.attract-stage-$$"
THEME_BACKUP=""
cleanup_stage() {
  [ ! -d "$THEME_STAGE" ] || rm -rf "$THEME_STAGE"
}
trap cleanup_stage EXIT
mkdir "$THEME_STAGE"
cp -R "$THEME_SOURCE/." "$THEME_STAGE/"
[ -f "$THEME_STAGE/theme.qml" ] || die "La copia preparada del theme no contiene theme.qml"
if [ -e "$THEME_TARGET" ]; then
  THEME_BACKUP="$(backup_path "$THEME_BACKUPS_ROOT/attract" "$TIMESTAMP")"
  mv "$THEME_TARGET" "$THEME_BACKUP"
fi
if ! mv "$THEME_STAGE" "$THEME_TARGET"; then
  if [ -n "$THEME_BACKUP" ] && [ ! -e "$THEME_TARGET" ] && [ -e "$THEME_BACKUP" ]; then
    mv "$THEME_BACKUP" "$THEME_TARGET"
  fi
  die "no se pudo instalar el theme"
fi
trap - EXIT

SETTINGS_PATH="$CONFIG_DIR/settings.txt"
GAME_DIRS_PATH="$CONFIG_DIR/game_dirs.txt"
SETTINGS_BACKUP="$(backup_file "$SETTINGS_PATH" "$TIMESTAMP")"
GAME_DIRS_BACKUP="$(backup_file "$GAME_DIRS_PATH" "$TIMESTAMP")"

set_setting "$SETTINGS_PATH" general.theme themes/attract/
set_setting "$SETTINGS_PATH" providers.pegasus_media.enabled true
for provider in steam gog es2 launchbox logiqx playnite skraper; do
  set_setting "$SETTINGS_PATH" "providers.${provider}.enabled" false
done

: > "$GAME_DIRS_PATH"
for directory in "${SELECTED_DIRS[@]}"; do
  printf '%s\n' "$directory" >> "$GAME_DIRS_PATH"
done

printf '\nConfiguracion terminada.\n'
printf '  Settings  : %s\n' "$SETTINGS_PATH"
printf '  Game dirs : %s\n' "$GAME_DIRS_PATH"
printf '  Theme     : %s\n' "$THEME_TARGET"
[ -z "$SETTINGS_BACKUP" ] || printf '  Backup    : %s\n' "$SETTINGS_BACKUP"
[ -z "$GAME_DIRS_BACKUP" ] || printf '  Backup    : %s\n' "$GAME_DIRS_BACKUP"
[ -z "$THEME_BACKUP" ] || printf '  Backup    : %s\n' "$THEME_BACKUP"

if [ "$SKIP_LAUNCH" -eq 0 ]; then
  command -v open >/dev/null 2>&1 || die "no se encontro el comando open de macOS"
  printf 'Abriendo Pegasus...\n'
  open "$PEGASUS_APP"
fi
