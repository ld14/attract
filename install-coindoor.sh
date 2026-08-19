#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "uso: $0 <paquete.zip> [ruta]"
    echo ""
    echo "  Instala un paquete COINDOOR en la libreria."
    echo "  Ejemplo: $0 files_install/the-simpsons-arcade-game.coindoor.zip library/"
    exit 1
fi

ZIP="$1"
RAIZ="${2:-.}"

if [ ! -f "$ZIP" ]; then
    echo "error: no existe $ZIP"
    exit 1
fi

echo "=== Paquete COINDOOR ==="
echo "  zip:  $ZIP"
echo "  raiz: $RAIZ"
echo ""

# Mostrar contenido del zip
echo "--- Contenido del paquete ---"
unzip -l "$ZIP"
echo ""

# Ejecutar import
echo "--- Instalando ---"
PYTHONPATH=src python3 -m attract.instalar "$ZIP" "$RAIZ"
echo ""

# Verificar resultado
SET=$(unzip -p "$ZIP" game.json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['set'])" 2>/dev/null || echo "")
SYSTEM=$(unzip -p "$ZIP" game.json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['system'])" 2>/dev/null || echo "")

if [ -n "$SET" ] && [ -n "$SYSTEM" ]; then
    MEDIA="$RAIZ/$SYSTEM/media/$SET"
    META="$RAIZ/$SYSTEM/metadata.pegasus.txt"
    echo "--- Verificacion ---"
    echo "  media:    $MEDIA"
    echo "  metadata: $META"
    if [ -d "$MEDIA" ]; then
        echo "  assets:"
        ls -lh "$MEDIA" | tail -n +2 | sed 's/^/    /'
    fi
    if [ -f "$META" ]; then
        echo "  bloque game: nuevo"
        grep -A1 "game: The Simpsons" "$META" | sed 's/^/    /'
    fi
fi
