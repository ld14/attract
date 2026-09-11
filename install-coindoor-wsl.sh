#!/usr/bin/env bash
# Lanzador WSL. El instalador original de Mac es install-coindoor.sh, junto a este archivo.
set -euo pipefail

if (( $# < 1 || $# > 2 )); then
    echo "uso: $0 <paquete.zip> [raiz de libreria]" >&2
    exit 1
fi

for tool in wslpath powershell.exe; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: falta $tool; ejecutar desde WSL con interoperabilidad Windows habilitada." >&2
        exit 1
    fi
done

if [[ ! -f "$1" ]]; then
    echo "error: no existe el paquete: $1" >&2
    exit 1
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
zip=$(wslpath -a -w "$1")
root=$(wslpath -a -w "${2:-.}")
installer=$(wslpath -a -w "$script_dir/install-coindoor.ps1")

exec powershell.exe -NoProfile -ExecutionPolicy Bypass \
    -File "$installer" "$zip" "$root"
