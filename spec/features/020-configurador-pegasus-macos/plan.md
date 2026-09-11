# 020 · Configurador de Pegasus para macOS — Plan

## Enfoque

Un `.command` resuelve su propia ubicación y delega en Bash. El script usa
solo herramientas incluidas en macOS y evita extensiones de Bash posteriores
a 3.2. Comparte el contrato funcional con Windows, pero implementa rutas,
procesos y lanzamiento nativos de macOS.

## Implementación

1. `configure-pegasus-macos.command` — launcher de Finder y reenvío de argumentos.
2. `scripts/configure-pegasus-macos.sh` — preflight, selección, backups,
   settings, instalación transaccional y arranque mediante `open`.
3. `tests/test_configure_pegasus_macos.py` — contratos de filesystem ejecutables
   también con Git Bash, sin invocar APIs de macOS.
4. `README.md` y `docs/SETUP.md` — entrada normal y opciones avanzadas.

## Decisiones

- Bash 3.2 y utilidades del sistema mantienen el instalador sin dependencias.
- `osascript` intenta cierre amable y `pkill` queda como fallback acotado.
- `portable.txt` junto al binario selecciona `<directorio-binario>/config`;
  `--config-directory` permite declarar otra ubicación.
- Los backups del theme viven en `backups/themes`, fuera del escaneo de Pegasus.

## Riesgos

- **Finder no conserva el cwd del repo** — el `.command` deriva la ruta desde `$0`.
- **Pegasus pisa settings al salir** — se espera el cierre antes de escribir.
- **Espacios en rutas** — todas las expansiones de paths van entre comillas.
- **Prueba fuera de Mac** — process control y `open` se omiten en integración;
  filesystem, selección, backups e idempotencia sí se ejecutan.
