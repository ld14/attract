#!/usr/bin/env bash
# Deja a Pegasus sin juegos para empezar una carga desde cero.
#
#   - manda a la papelera cada coleccion de library/ (todo subdirectorio que
#     NO empiece con "_": los "_" son datos que no son juegos, como _magazines)
#   - vacia game_dirs.txt y favorites.txt, dejando .bak al lado
#
# fixtures/ no se toca nunca: es de test y esta versionado.
# stats.db tampoco: guarda tiempo de juego por ruta. Borralo a mano si querés
# que las estadisticas viejas no reaparezcan al recargar los mismos paths.
#
# Uso:  scripts/reset-pegasus.sh          borra (pide confirmacion)
#       DRY=1 scripts/reset-pegasus.sh    solo muestra que haria
set -euo pipefail

DRY="${DRY:-}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIBRARY="$REPO/library"

case "$(uname -s)" in
  Darwin) CONFIG="$HOME/Library/Preferences/pegasus-frontend" ;;
  Linux)  CONFIG="$HOME/.config/pegasus-frontend" ;;
  *)      CONFIG="${LOCALAPPDATA:-$HOME}/pegasus-frontend" ;;
esac

# Papelera si existe (recuperable); si no, un directorio al lado.
TRASH="$HOME/.Trash"; [ -d "$TRASH" ] || TRASH="${TMPDIR:-/tmp}"
DEST="$TRASH/attract-library-$(date +%Y%m%d-%H%M%S)"

# Colecciones a borrar: subdirectorios de library/ que no empiecen con "_".
colecciones=()
for d in "$LIBRARY"/*/; do
  [ -d "$d" ] || continue          # glob sin match: queda literal
  nombre="$(basename "$d")"
  [[ "$nombre" == _* ]] && continue
  colecciones+=("$nombre")
done

echo "Pegasus config : $CONFIG"
echo "Library        : $LIBRARY"
if [ ${#colecciones[@]} -eq 0 ]; then
  echo "Colecciones    : (ninguna, library/ ya esta vacia)"
else
  echo "Colecciones    : ${colecciones[*]}"
  echo "A la papelera  : $DEST"
  du -sh "${colecciones[@]/#/$LIBRARY/}" 2>/dev/null || true
fi

if [ -n "$DRY" ]; then
  echo
  echo "DRY=1: no se borro nada."
  exit 0
fi

echo
read -r -p "Borrar estas colecciones y vaciar game_dirs.txt? [escribi 'si'] " ok
[ "$ok" = "si" ] || { echo "Cancelado."; exit 1; }

# Pegasus reescribe su config al salir: si sigue abierto, pisa el game_dirs.txt
# que vaciamos abajo.
if pgrep -f pegasus-fe >/dev/null; then
  echo "Cerrando Pegasus..."
  osascript -e 'tell application "Pegasus" to quit' 2>/dev/null || pkill -f pegasus-fe || true
  for _ in $(seq 20); do pgrep -f pegasus-fe >/dev/null || break; sleep 0.5; done
fi

if [ ${#colecciones[@]} -gt 0 ]; then
  mkdir -p "$DEST"
  for nombre in "${colecciones[@]}"; do
    mv "$LIBRARY/$nombre" "$DEST/"
    mkdir "$LIBRARY/$nombre"   # se recrea vacia: las rutas siguen existiendo
    echo "  $nombre -> $DEST/$nombre"
  done
fi

for f in game_dirs.txt favorites.txt; do
  [ -f "$CONFIG/$f" ] || continue
  cp "$CONFIG/$f" "$CONFIG/$f.bak"
  : > "$CONFIG/$f"
  echo "  $f vaciado (backup en $f.bak)"
done

echo
echo "Listo. Pegasus arranca sin juegos."
echo "Para la carga nueva, volve a agregar las rutas en Pegasus > Settings > Game directories"
echo "(o restaura: cp \"$CONFIG/game_dirs.txt.bak\" \"$CONFIG/game_dirs.txt\")"
