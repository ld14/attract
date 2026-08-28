# 012 · Manual en PDF, abierto por el sistema operativo

**Estado:** implementada (ADR-0021, `Qt.openUrlExternally` en `core/Paths.qml`).

## Qué hace

Extiende la tarjeta **"Manual digitalizado"** que ya existe para que, además de
hojear las páginas escaneadas, pueda **abrir el PDF del manual con la aplicación
predeterminada del sistema** — en macOS (desarrollo) y en Windows (el gabinete).

Recibe: un campo `file` nuevo y opcional en `data.json → manual`, con el nombre
del PDF dentro de `media/<set>/_manual/`.
Produce: el PDF abierto en el visor que el usuario ya tenga asociado, o un aviso
de error si el sistema lo rechaza.

**No es una sección nueva.** No hay colección, pantalla, menú ni navegación
nuevos: entra por la misma tarjeta de CONTENIDO EXTRA, con los mismos tokens y
el mismo comportamiento de foco. Un juego con páginas escaneadas sigue abriendo
el visor exactamente como hoy.

Explícitamente **fuera de su responsabilidad**: renderizar el PDF adentro del
theme (imposible, [`ADR-0007`](../../decisions/0007-paginas-revista-imagenes-no-pdf.md)),
y producir o rasterizar PDFs (ATTRACT consume, no produce —
[`ADR-0009`](../../decisions/0009-frontera-produccion-consumo-revistas.md)).

## Por qué

Un manual escaneado nace como PDF. Hoy el único camino para que aparezca en
pantalla es rasterizarlo a mano página por página: un coste que
[`ADR-0014`](../../decisions/0014-manual-digitalizado.md) asume explícitamente,
pero que deja **invisible** a todo manual no convertido. La tarjeta dice "No
Disponible" aunque el PDF esté ahí, al lado de la carátula.

El mecanismo es `Qt.openUrlExternally` — ver
[`ADR-0021`](../../decisions/0021-manual-pdf-app-del-sistema.md) para el porqué
y las cuatro alternativas descartadas.

## Criterios de aceptación

- [x] **Fase 0, bloqueante — pasada en macOS el 2026-08-09.**
      `Qt.openUrlExternally` existe y abre; una ruta inexistente devuelve
      `false`, así que **hay canal de error**. Falta la corrida en el gabinete
      Windows. Detalle en `themes/experimentos/abrir-url-externa.qml`
      `#RESULTADO OBSERVADO`.
- [ ] Antes de abrir el PDF aparece un aviso que dice que se abre **fuera de
      ATTRACT**. Medido: el visor abre por delante y **Pegasus pierde el foco**,
      sin API para recuperarlo. En el gabinete, que es solo joystick, eso deja
      al jugador en el visor: el aviso no lo arregla, lo hace explícito.
- [ ] Dado un juego con `manual.pages` y `manual.file`, cuando se abre la
      tarjeta, entonces se abre el `DocumentViewer` **igual que hoy**, y adentro
      hay un control visible que abre el PDF en la app del sistema.
- [ ] Dado un juego con `manual.file` y **sin** `pages`, cuando se abre la
      tarjeta, entonces el PDF se abre directamente sin pasar por el visor, y el
      subtítulo de la tarjeta dice `PDF`.
- [ ] Dado un juego sin `pages` ni `file`, la tarjeta sigue diciendo
      `"No Disponible"` y no se abre (`docs/CONVENCION.md` §2.3, sin cambios).
- [ ] Dado un `file` declarado cuyo archivo **no está en el disco**, entonces
      `attract doctor` lo reporta como **error**, con el mismo criterio que ya
      usa para `manual.pages`.
- [ ] Dado un `file` con `..`, con `/` o `\`, o sin extensión `.pdf`, entonces
      `attract doctor` lo reporta como error.
- [ ] Dado un PDF borrado del disco en tiempo de ejecución, cuando se intenta
      abrir, entonces aparece un aviso de error y **Pegasus sigue funcionando**;
      el aviso se cierra con B/ESC o solo.
- [ ] Cerrar el visor de PDF no cierra ni cuelga Pegasus.
- [ ] Un nombre de archivo con espacios y acentos abre correctamente en las dos
      plataformas.
- [ ] **Maze of the Kings** (el juego desnudo, sin ningún campo rico) sigue sin
      romperse — `spec/constitution/mission.md`.

## Fuera de alcance

- **Renderizar el PDF adentro del theme** — imposible con este binario
  (ADR-0007, contraprueba en `themes/experimentos/pdf-qtquick.qml`).
- **Generar o rasterizar PDFs desde `attract`** — eso exigiría una dependencia
  nueva y rompe el límite duro stdlib-only de
  `spec/constitution/tech-stack.md`. Necesitaría su propio ADR.
- **Saber si el visor arrancó de verdad**, o **recuperar el foco** después de
  abrirlo. No hay API en Pegasus para ninguna de las dos. Es el coste asumido en
  ADR-0021, y la vuelta al frente en el gabinete se resuelve mapeando `Alt+F4`
  en el encoder del joystick — configuración de la máquina, no de este repo.
- **Otros formatos (EPUB, CBZ, CHM, TXT).** El mecanismo es indiferente al
  formato, pero no se agrega nada hoy por un caso que no existe.
- **Miniaturas, búsqueda dentro del PDF, historial, favoritos.** Nada de eso
  entra: el PDF se suelta al sistema y termina ahí la responsabilidad.
