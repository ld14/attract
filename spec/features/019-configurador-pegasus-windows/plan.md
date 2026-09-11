# 019 · Configurador de Pegasus para Windows — Plan

## Enfoque

Un launcher `.bat` llama a un script PowerShell autocontenido. El script hace
preflight completo antes de cerrar Pegasus o escribir, y acepta rutas explícitas
para cubrir config normal y portable. Las escrituras de texto usan UTF-8 sin BOM
y LF, y los reemplazos conservan una copia con timestamp.

## Implementación

1. `configure-pegasus-windows.bat` — entrada de doble clic y reenvío de argumentos.
2. `scripts/configure-pegasus-windows.ps1` — detección, backups, configuración,
   instalación del theme y arranque desacoplado.
3. `docs/SETUP.md` y `README.md` — uso normal, parámetros y comportamiento demo.

## Decisiones

- Se automatizan ADR-0017 y las rutas ya fijadas por Pegasus; no hay decisión
  arquitectónica nueva.
- Solo cuentan como colecciones reales los directorios cuyo metadata no esté
  vacío y contenga al menos un bloque `game:`.
- Los fixtures son fallback visible, no una librería real silenciosa.
- El script no toca metadata, de acuerdo con ADR-0002.

## Riesgos

- **Pegasus pisa cambios al salir** — se cierra antes del primer backup/escritura.
- **Theme previo personalizado** — se mueve a `backups/themes`, fuera del
  directorio que escanea Pegasus, y no se borra.
- **Fallo a mitad de instalación** — la configuración se escribe después de
  preparar el theme y cada entrada previa queda respaldada.
- **PowerShell 5 agrega BOM con `Set-Content -Encoding utf8`** — se usa
  `System.Text.UTF8Encoding(false)` directamente.
