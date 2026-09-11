# Compatible con Windows PowerShell 5.1 y PowerShell 7.
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Zip,
    [Parameter(Position = 1)][string]$Raiz = '.',
    [string]$AttractPath
)

$ErrorActionPreference = 'Stop'
try {
    if (-not $AttractPath) { $AttractPath = $PSScriptRoot }
    if (-not $Zip) {
        throw 'Uso: .\install-coindoor.ps1 <paquete.zip> [raiz] [-AttractPath <repo ATTRACT>]'
    }
    foreach ($ruta in @($Zip, $Raiz, $AttractPath)) {
        if ($ruta -match '^/mnt/[a-zA-Z]/') {
            throw 'Use rutas Windows (D:\Juegos\...), no rutas WSL (/mnt/d/...).'
        }
    }
    $zipPath = (Resolve-Path -LiteralPath $Zip).ProviderPath
    if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
        throw "No es un archivo ZIP: $zipPath"
    }
    $repoPath = (Resolve-Path -LiteralPath $AttractPath).ProviderPath
    if (-not (Test-Path -LiteralPath (Join-Path $repoPath 'src/attract/instalar.py') -PathType Leaf)) {
        throw 'No se encuentra src/attract/instalar.py. Indique el repo con -AttractPath.'
    }
    $rootPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Raiz)
    $pythonArgs = @()
    $pythonExe = Join-Path $repoPath '.venv/Scripts/python.exe'
    if (-not (Test-Path -LiteralPath $pythonExe -PathType Leaf)) {
        $command = Get-Command python -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) {
            $pythonExe = $command.Source
        } else {
            $command = Get-Command py -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $command) { throw 'No se encuentra Python. Instale Python 3.12 o posterior para Windows.' }
            $pythonExe = $command.Source
            $pythonArgs = @('-3')
        }
    }

    # -c mantiene stdin disponible para las confirmaciones de ATTRACT.
    $helper = @'
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile

def main():
    archive, root, repo = map(Path, sys.argv[1:])
    print('=== Paquete COINDOOR ===', flush=True)
    print(f'  zip:  {archive}\n  raiz: {root}\n', flush=True)
    print('--- Contenido del paquete ---', flush=True)
    with zipfile.ZipFile(archive) as bundle:
        bundle.printdir()
        game = json.loads(bundle.read('game.json'))
    sys.stdout.flush()
    env = os.environ.copy()
    env['PYTHONPATH'] = str(repo / 'src') + os.pathsep + env.get('PYTHONPATH', '')
    print('\n--- Instalando ---', flush=True)
    result = subprocess.run(
        [sys.executable, '-m', 'attract.instalar', str(archive), str(root)], env=env,
    )
    if result.returncode:
        return result.returncode

    system = root / game['system']
    media = system / 'media' / game['set']
    metadata = system / 'metadata.pegasus.txt'
    print(f'\n--- Verificacion ---\n  media: {media}\n  metadata: {metadata}')
    if not media.is_dir() or not metadata.is_file():
        raise ValueError('No se encontraron los assets o la metadata instalada.')
    print('  assets:')
    for item in sorted(media.iterdir()):
        size = '<DIR>' if item.is_dir() else f'{item.stat().st_size} bytes'
        print(f'    {size:>14}  {item.name}')
    blocks = re.split(r'\n\s*\n', metadata.read_text(encoding='utf-8-sig'))
    matches = [block for block in blocks if any(
        line.startswith('x-set:') and line.partition(':')[2].strip() == game['set']
        for line in block.splitlines()
    )]
    if len(matches) != 1:
        raise ValueError('No se encontro un unico bloque para el set instalado.')
    print('  bloque game:')
    skip_summary = False
    files = []
    for line in matches[0].splitlines():
        if line.startswith('summary:'):
            skip_summary = True
            continue
        if skip_summary and line[:1].isspace():
            continue
        skip_summary = False
        print(f'    {line}')
        if line.startswith('file:'):
            files.append(line.partition(':')[2].strip())
    if not files or not files[0]:
        raise ValueError('El bloque no tiene linea file:.')
    rom = system / files[0]
    if not rom.exists():
        raise ValueError(f'file: no existe: {rom}. Pegasus va a descartar el juego.')
    print(f'  file: OK -> {rom}')
    return 0

try:
    sys.exit(main())
except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
    print(f'ERROR: {error}', file=sys.stderr)
    sys.exit(1)
'@
    & $pythonExe @pythonArgs -c $helper $zipPath $rootPath $repoPath
    $installExitCode = $LASTEXITCODE
    if ($installExitCode -eq 0) {
        Write-Host ''
        Write-Host 'Instalado. Para registrar la libreria y reiniciar Pegasus, ejecute en PowerShell:'
        $configScript = (Join-Path $PSScriptRoot 'scripts/configure-pegasus-windows.ps1').Replace("'", "''")
        $quotedRoot = $rootPath.Replace("'", "''")
        Write-Host "powershell.exe -NoProfile -ExecutionPolicy Bypass -File '$configScript' -LibraryRoot '$quotedRoot'"
        Write-Host 'Desde WSL: bash ./configure-pegasus-wsl.sh <la misma raiz Linux usada al instalar>'
    }
    exit $installExitCode
} catch {
    [Console]::Error.WriteLine("ERROR: $($_.Exception.Message)")
    exit 1
}
