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
RAIZ="${RAIZ%/}"

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
        # el bloque del set (parrafo que contiene su x-set:), sin el summary
        BLOQUE=$(awk -v s="x-set: $SET" 'BEGIN{RS=""} index($0, s)' "$META")
        echo "  bloque game:"
        printf '%s\n' "$BLOQUE" | grep -v '^summary:' | sed 's/^/    /'

        # Pegasus (general.verify-files) descarta el juego si el file: no
        # existe, y sin juegos validos descarta la coleccion entera: es un
        # fallo silencioso salvo que se mire lastrun.log. Se chequea aca.
        FILE=$(printf '%s\n' "$BLOQUE" | sed -n 's/^file: //p' | head -1)
        if [ -z "$FILE" ]; then
            echo "  ERROR: el bloque no tiene linea file:"
            exit 1
        fi
        if [ ! -e "$RAIZ/$SYSTEM/$FILE" ]; then
            echo "  ERROR: file: '$FILE' no existe en $RAIZ/$SYSTEM/"
            echo "         Pegasus va a descartar el juego y la coleccion entera."
            exit 1
        fi
        echo "  file: OK -> $RAIZ/$SYSTEM/$FILE"
    fi
fi
