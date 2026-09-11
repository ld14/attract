# 019 · Configurador de Pegasus para Windows

**Estado:** implementada

## Qué hace

Configura una instalación de Pegasus en Windows desde un checkout de ATTRACT:
registra las colecciones, instala y selecciona el theme de producción, apaga
los providers externos y puede iniciar Pegasus al terminar.

Antes de escribir, valida que el theme y los directorios elegidos existan.
Cierra Pegasus para que no reescriba la configuración y conserva backups de
todo archivo o theme que reemplace. No crea ni edita `metadata.pegasus.txt`.

## Por qué

ADR-0017 acepta que una instalación nueva empieza con providers incompatibles
con la librería de ATTRACT y deja el arreglo como paso manual. La primera
instalación Windows real también mostró otros tres pasos fáciles de omitir:
crear `game_dirs.txt`, instalar el theme y cerrar Pegasus antes de editar.

## Criterios de aceptación

- [x] Con una colección real válida, `game_dirs.txt` queda apuntando a ella.
- [x] Sin colecciones reales válidas, usa `fixtures/arcade` y lo informa como demo.
- [x] Instala `themes/attract`, selecciona `themes/attract/` y desactiva los
      providers externos definidos por ADR-0017.
- [x] Si ya hay configuración o theme, los respalda antes de reemplazarlos.
- [x] Una ruta explícita inválida falla antes de modificar archivos.
- [x] Puede trabajar contra un directorio de config portable y omitir el arranque.
- [x] Una segunda ejecución produce la misma configuración y nuevos backups.

## Fuera de alcance

- Crear juegos o completar metadata: corresponde a ingesta/carga guiada.
- Instalar Pegasus, MAME o ROMs.
- Configurar Linux; macOS está cubierto por la feature
  [020-configurador-pegasus-macos](../020-configurador-pegasus-macos/spec.md).
