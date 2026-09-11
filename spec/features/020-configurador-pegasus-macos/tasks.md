# 020 · Configurador de Pegasus para macOS — Tareas

## Implementación

- [x] Crear launcher `.command` independiente del directorio actual.
- [x] Implementar argumentos, ayuda, preflight y selección de colecciones.
- [x] Implementar cierre, backups, settings UTF-8/LF e instalación del theme.
- [x] Implementar config estándar/portable, `--dry-run` y arranque con `open`.

## Verificación

- [x] Fallback demo, providers, backups e idempotencia en config temporal.
- [x] Detección de colección real y config portable.
- [x] Ruta explícita inválida y dry-run no escriben.
- [x] Sintaxis válida en Bash 3.2/compatible.
- [ ] Verificación final pendiente en macOS real claramente documentada.

## Cierre

- [x] Documentar uso en README y SETUP.
- [x] Marcar spec/tareas según evidencia obtenida.
- [x] Actualizar conteo de tests y roadmap.
- [x] Confirmar que no agrega dependencia ni requiere ADR.
