[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $ProjectRoot = '',
    [string] $PegasusExe = '',
    [string] $ConfigDirectory = '',
    [string] $LibraryRoot = '',
    [string[]] $GameDirectory = @(),
    [switch] $UseFixtures,
    [switch] $SkipLaunch,
    [switch] $SkipProcessControl
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Join-Path $PSScriptRoot '..'
}

function Resolve-Directory {
    param([string] $Path, [string] $Label)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Label no existe o no es un directorio: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Test-GameDirectory {
    param([string] $Path)

    $metadata = Join-Path $Path 'metadata.pegasus.txt'
    if (-not (Test-Path -LiteralPath $metadata -PathType Leaf)) {
        return $false
    }
    if ((Get-Item -LiteralPath $metadata).Length -eq 0) {
        return $false
    }
    $hasCollection = $false
    $hasGame = $false
    foreach ($line in Get-Content -LiteralPath $metadata -Encoding UTF8) {
        if ($line -cmatch '^collection:\s*\S') { $hasCollection = $true }
        if ($line -cmatch '^game:\s*\S') {
            if (-not $hasCollection) {
                throw "Metadata sin collection: antes de game: en $metadata. Reimporte el paquete COINDOOR."
            }
            $hasGame = $true
        }
    }
    return $hasGame
}

function Get-BackupPath {
    param([string] $Path, [string] $Timestamp)

    $candidate = "$Path.bak-$Timestamp"
    $number = 1
    while (Test-Path -LiteralPath $candidate) {
        $candidate = "$Path.bak-$Timestamp-$number"
        $number += 1
    }
    return $candidate
}

function Backup-File {
    param([string] $Path, [string] $Timestamp)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }
    $backup = Get-BackupPath -Path $Path -Timestamp $Timestamp
    Copy-Item -LiteralPath $Path -Destination $backup
    return $backup
}

function Write-Utf8Lf {
    param([string] $Path, [string] $Content)

    $normalized = $Content -replace "`r`n", "`n" -replace "`r", "`n"
    $normalized = $normalized.TrimEnd("`n") + "`n"
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $normalized, $encoding)
}

function Set-Setting {
    param([string] $Text, [string] $Key, [string] $Value)

    $pattern = '^' + [regex]::Escape($Key) + '\s*:'
    $lines = @($Text -replace "`r`n", "`n" -replace "`r", "`n" -split "`n")
    $result = New-Object System.Collections.Generic.List[string]
    $found = $false

    foreach ($line in $lines) {
        if ($line -match $pattern) {
            if (-not $found) {
                $result.Add("${Key}: $Value")
                $found = $true
            }
            continue
        }
        $result.Add($line)
    }

    if (-not $found) {
        while ($result.Count -gt 0 -and $result[$result.Count - 1] -eq '') {
            $result.RemoveAt($result.Count - 1)
        }
        $result.Add("${Key}: $Value")
    }
    return $result -join "`n"
}

function Stop-Pegasus {
    $processes = @(Get-Process -Name 'pegasus-fe' -ErrorAction SilentlyContinue)
    if ($processes.Count -eq 0) {
        return
    }

    Write-Host 'Cerrando Pegasus para que no pise la configuracion...'
    foreach ($process in $processes) {
        $null = $process.CloseMainWindow()
    }
    foreach ($process in $processes) {
        if (-not $process.HasExited) {
            $null = $process.WaitForExit(5000)
        }
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -Force
        }
    }
}

$project = Resolve-Directory -Path $ProjectRoot -Label 'El proyecto'
$themeSource = Resolve-Directory -Path (Join-Path $project 'themes\attract') -Label 'El theme ATTRACT'
foreach ($requiredThemeFile in @('theme.cfg', 'theme.qml')) {
    if (-not (Test-Path -LiteralPath (Join-Path $themeSource $requiredThemeFile) -PathType Leaf)) {
        throw "El theme esta incompleto: falta $requiredThemeFile"
    }
}

if ($UseFixtures -and $GameDirectory.Count -gt 0) {
    throw 'Usa -UseFixtures o -GameDirectory, no ambos.'
}

$usingFixtures = $false
$selectedGameDirectories = New-Object System.Collections.Generic.List[string]
if ($UseFixtures) {
    $fixtureDirectory = Resolve-Directory -Path (Join-Path $project 'fixtures\arcade') -Label 'El fixture Arcade'
    if (-not (Test-GameDirectory -Path $fixtureDirectory)) {
        throw "El fixture no contiene metadata valida: $fixtureDirectory"
    }
    $selectedGameDirectories.Add($fixtureDirectory)
    $usingFixtures = $true
} elseif ($GameDirectory.Count -gt 0) {
    foreach ($directory in $GameDirectory) {
        $resolved = Resolve-Directory -Path $directory -Label 'La coleccion'
        if (-not (Test-GameDirectory -Path $resolved)) {
            throw "La coleccion no tiene metadata valida con al menos un juego: $resolved"
        }
        $selectedGameDirectories.Add($resolved)
    }
} else {
    if (-not $LibraryRoot) { $LibraryRoot = Join-Path $project 'library' }
    $library = Resolve-Directory -Path $LibraryRoot -Label 'La libreria'
    foreach ($directory in Get-ChildItem -LiteralPath $library -Directory | Sort-Object Name) {
        if (-not $directory.Name.StartsWith('_') -and (Test-GameDirectory -Path $directory.FullName)) {
            $selectedGameDirectories.Add($directory.FullName)
        }
    }
    if ($selectedGameDirectories.Count -eq 0) {
        $fixtureDirectory = Resolve-Directory -Path (Join-Path $project 'fixtures\arcade') -Label 'El fixture Arcade'
        if (-not (Test-GameDirectory -Path $fixtureDirectory)) {
            throw 'No hay colecciones reales ni un fixture Arcade valido.'
        }
        $selectedGameDirectories.Add($fixtureDirectory)
        $usingFixtures = $true
    }
}

if ([string]::IsNullOrWhiteSpace($PegasusExe)) {
    $pegasus = Join-Path $project 'pegasus\pegasus-fe.exe'
} else {
    $pegasus = [System.IO.Path]::GetFullPath($PegasusExe)
}
if (-not $SkipLaunch -and -not (Test-Path -LiteralPath $pegasus -PathType Leaf)) {
    throw "No se encontro Pegasus: $pegasus. Indica -PegasusExe o usa -SkipLaunch."
}

if ([string]::IsNullOrWhiteSpace($ConfigDirectory)) {
    $portableMarker = Join-Path (Split-Path -Parent $pegasus) 'portable.txt'
    if (Test-Path -LiteralPath $portableMarker -PathType Leaf) {
        $config = Join-Path (Split-Path -Parent $pegasus) 'config'
    } else {
        if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
            throw 'LOCALAPPDATA no esta definido. Indica -ConfigDirectory.'
        }
        $config = Join-Path $env:LOCALAPPDATA 'pegasus-frontend'
    }
} else {
    $config = [System.IO.Path]::GetFullPath($ConfigDirectory)
}

Write-Host 'Configuracion de Pegasus para Windows'
Write-Host "  Proyecto : $project"
Write-Host "  Config   : $config"
Write-Host "  Theme    : $themeSource"
Write-Host '  Juegos   :'
foreach ($directory in $selectedGameDirectories) {
    Write-Host "    $directory"
}
if ($usingFixtures) {
    Write-Warning 'No hay una coleccion real valida; se usara fixtures\arcade como demostracion.'
}

if (-not $PSCmdlet.ShouldProcess($config, 'Configurar Pegasus e instalar ATTRACT')) {
    return
}

if (-not $SkipProcessControl) {
    Stop-Pegasus
}

New-Item -ItemType Directory -Path $config -Force | Out-Null
$themesRoot = Join-Path $config 'themes'
New-Item -ItemType Directory -Path $themesRoot -Force | Out-Null
$themeBackupsRoot = Join-Path $config 'backups\themes'
New-Item -ItemType Directory -Path $themeBackupsRoot -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$themeTarget = Join-Path $themesRoot 'attract'
$themeStage = Join-Path $themesRoot ('.attract-stage-' + [guid]::NewGuid().ToString('N'))
$themeBackup = $null
try {
    New-Item -ItemType Directory -Path $themeStage | Out-Null
    foreach ($item in Get-ChildItem -LiteralPath $themeSource -Force) {
        Copy-Item -LiteralPath $item.FullName -Destination $themeStage -Recurse
    }
    if (-not (Test-Path -LiteralPath (Join-Path $themeStage 'theme.qml') -PathType Leaf)) {
        throw 'La copia preparada del theme no contiene theme.qml.'
    }
    if (Test-Path -LiteralPath $themeTarget) {
        $themeBackup = Get-BackupPath -Path (Join-Path $themeBackupsRoot 'attract') -Timestamp $timestamp
        Move-Item -LiteralPath $themeTarget -Destination $themeBackup
    }
    Move-Item -LiteralPath $themeStage -Destination $themeTarget
} catch {
    if (Test-Path -LiteralPath $themeStage) {
        Remove-Item -LiteralPath $themeStage -Recurse -Force
    }
    if ($null -ne $themeBackup -and -not (Test-Path -LiteralPath $themeTarget) -and (Test-Path -LiteralPath $themeBackup)) {
        Move-Item -LiteralPath $themeBackup -Destination $themeTarget
    }
    throw
}

$settingsPath = Join-Path $config 'settings.txt'
$gameDirsPath = Join-Path $config 'game_dirs.txt'
$settingsBackup = Backup-File -Path $settingsPath -Timestamp $timestamp
$gameDirsBackup = Backup-File -Path $gameDirsPath -Timestamp $timestamp

$settings = ''
if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    $settings = [System.IO.File]::ReadAllText($settingsPath)
}
$settings = Set-Setting -Text $settings -Key 'general.theme' -Value 'themes/attract/'
$settings = Set-Setting -Text $settings -Key 'providers.pegasus_media.enabled' -Value 'true'
foreach ($provider in @('steam', 'gog', 'es2', 'launchbox', 'logiqx', 'playnite', 'skraper')) {
    $settings = Set-Setting -Text $settings -Key "providers.$provider.enabled" -Value 'false'
}
Write-Utf8Lf -Path $settingsPath -Content $settings
Write-Utf8Lf -Path $gameDirsPath -Content ($selectedGameDirectories -join "`n")

Write-Host ''
Write-Host 'Configuracion terminada.'
Write-Host "  Settings  : $settingsPath"
Write-Host "  Game dirs : $gameDirsPath"
Write-Host "  Theme     : $themeTarget"
if ($null -ne $settingsBackup) { Write-Host "  Backup    : $settingsBackup" }
if ($null -ne $gameDirsBackup) { Write-Host "  Backup    : $gameDirsBackup" }
if ($null -ne $themeBackup) { Write-Host "  Backup    : $themeBackup" }

if (-not $SkipLaunch) {
    Write-Host 'Abriendo Pegasus...'
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $pegasus + '"') -WindowStyle Hidden
}
