# 020 · Configurador de Pegasus para macOS

**Estado:** implementada (verificación macOS pendiente)

## Qué hace

Configura Pegasus en macOS desde un checkout de ATTRACT: registra colecciones,
instala y selecciona el theme, apaga providers externos y abre la aplicación.
Se entrega como `.command` de doble clic y como script de terminal.

Valida todas las entradas antes de cerrar Pegasus o escribir. Conserva backups
de configuración y theme fuera del directorio escaneado. No crea ni modifica
`metadata.pegasus.txt`.

## Por qué

El configurador Windows de la feature 019 eliminó pasos manuales que también
existen en el Mac. macOS necesita una entrada propia por sus rutas, permisos,
bundle `.app` y mecanismos de cierre/arranque.

## Criterios de aceptación

- [ ] El `.command` puede ejecutarse por doble clic desde cualquier ubicación.
      Ejecutable y cwd independiente verificados; falta Finder en macOS real.
- [x] Detecta colecciones reales válidas o usa `fixtures/arcade` como demo explícita.
- [x] Configura `~/Library/Preferences/pegasus-frontend` o una config portable/indicada.
- [x] Instala ATTRACT, aplica ADR-0017 y respalda todo estado reemplazado.
- [x] Una ruta explícita inválida falla antes de modificar archivos.
- [x] `--dry-run` no escribe y `--skip-launch` permite uso automatizado.
- [x] Dos ejecuciones dejan la misma configuración efectiva y backups separados.

## Fuera de alcance

- Instalar Pegasus, MAME, Homebrew o ROMs.
- Crear o editar metadata de la librería.
- Cambiar el configurador Windows de la feature 019.
