# 019 · Configurador de Pegasus para Windows — Tareas

## Implementación

- [x] Crear el launcher `.bat` para doble clic y argumentos.
- [x] Implementar preflight y selección de colecciones reales/fallback demo.
- [x] Implementar cierre de Pegasus, backups y escrituras UTF-8/LF.
- [x] Instalar y seleccionar ATTRACT; aplicar providers de ADR-0017.
- [x] Implementar config portable, `-SkipLaunch` y `-WhatIf`.

## Verificación

- [x] Caso feliz aislado: config nueva recibe theme, settings y game dirs.
- [x] Config existente: conserva backups y actualiza claves sin duplicarlas.
- [x] Ruta explícita inválida: falla sin crear ni modificar la config.
- [x] Idempotencia: dos ejecuciones dejan el mismo contenido efectivo.
- [x] Ejecutar contra la instalación Windows real y confirmar en el log:
      theme ATTRACT, metadata encontrado y juegos cargados.

## Cierre

- [x] Documentar el comando en `README.md` y `docs/SETUP.md`.
- [x] Marcar los criterios de `spec.md` y estas tareas.
- [x] Registrar la feature como hecha en el roadmap.
- [x] Confirmar que no requiere dependencia ni ADR nueva.
