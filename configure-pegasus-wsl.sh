#!/usr/bin/env bash
# Configura Pegasus de Windows desde WSL con rutas Linux.
set -euo pipefail

if (( $# > 1 )); then
    echo "uso: $0 [raiz de libreria]" >&2
    exit 1
fi
for tool in wslpath powershell.exe; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: falta $tool; ejecutar desde WSL con interoperabilidad Windows habilitada." >&2
        exit 1
    fi
done
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
root=${1:-"$script_dir/library"}
if [[ ! -d "$root" ]]; then
    echo "error: no existe la libreria: $root" >&2
    exit 1
fi
installer=$(wslpath -a -w "$script_dir/scripts/configure-pegasus-windows.ps1")
root=$(wslpath -a -w "$root")
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$installer" -LibraryRoot "$root"
