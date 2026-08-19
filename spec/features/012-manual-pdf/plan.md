# 012 · Manual en PDF — Plan

_Cómo se implementa lo descrito en `spec.md`. Debe respetar la `constitution/`._

## Enfoque

Nada de esto se implementa hasta que la **Fase 0** dé resultado: un experimento
archivado que diga si `Qt.openUrlExternally` abre de verdad contra este binario,
en las dos máquinas. Si no abre, la feature se cierra y el ADR se archiva con la
evidencia — el mismo método con el que se decidió ADR-0007.

Después de eso, el cambio es deliberadamente chico. **No hay componente nuevo:**
hay una función en `core/Paths.qml`, un campo más en el objeto que devuelve
`core/DocModel.qml`, y tres archivos de UI que ya existen y solo agregan una
rama. La responsabilidad de "hablar con el sistema operativo" vive en una
función sin UI, y la de "avisar que falló" se resuelve reusando el overlay que
ya existe para exactamente ese problema.

Lo que este módulo deliberadamente **no** hace: no sabe qué visor de PDF hay
instalado, no espera a que arranque, no lo cierra, y no dibuja una sola página.

## Implementación

1. `themes/experimentos/abrir-url-externa.qml` — **Fase 0, bloqueante.** Mide
   contra Pegasus real, en macOS y Windows: que la función exista, que abra, qué
   devuelve con una ruta inexistente, si hace falta `encodeURIComponent`, y si
   el visor aparece delante o detrás de Pegasus fullscreen. Resuelve sus rutas
   con `Qt.resolvedUrl` — sin rutas absolutas, que es la deuda que
   `pdf-qtquick.qml` dejó anotada.
2. `src/attract/doctor.py` — `chk_data_contrato` (L270-288): valida `manual.file`
   (string no vacío, termina en `.pdf`, sin `/ \ ..`, existe en `_manual/`) y
   acepta `manual` sin `pages` cuando hay `file`. `chk_nombre_windows` (L98) ya
   corre sobre todo archivo recorrido y cubre caracteres prohibidos y nombres
   reservados: **no se escribe otro chequeo de nombres.**
3. `themes/attract/core/Paths.qml` — `manualPdfDe(game, nombre)`: reusa
   `manualDe()` y `conEsquema()`, y aplica `encodeURIComponent()` **solo al
   segmento del nombre**. Devuelve `""` si falta la base o el nombre. Acá también
   va la función que llama a `Qt.openUrlExternally` y devuelve `bool`, mientras
   quepa en unas pocas líneas.
4. `themes/attract/core/GameData.qml` — desdobla `hayManual` (L68-69) en
   `hayManualPaginas` (lo de hoy) y `hayManualPdf`, con
   `hayManual = hayManualPaginas || hayManualPdf`. Así `ExtrasList` y el badge
   de `GameCard` heredan el comportamiento sin cambios estructurales.
5. `themes/attract/core/DocModel.qml` — `desdeManual` (L82-97) agrega el campo
   `pdf` al objeto plano; `desdeRevista` lo deja en `""`. El visor sigue sin
   saber qué le tocó.
6. `themes/attract/screens/ExtrasList.qml` — subtítulo: `"12 págs"`,
   `"PDF"`, o `"12 págs · PDF"`. Sin nada, sigue `"No Disponible"` (L116).
7. `themes/attract/theme.qml` — `onAbrirExtra` (L170-173) es el **único** punto
   de decisión: con páginas abre el visor como hoy; solo con PDF, llama al
   launcher directo.
8. `themes/attract/overlays/DocumentViewer.qml` — un `Boton { variant: "glass" }`
   más en la fila de zoom (L324-357) y la tecla `api.keys.isDetails`, solo
   cuando el modelo trae `pdf`. La leyenda (L360-368) suma `X ABRIR PDF`
   **únicamente en ese caso**.
9. `themes/attract/overlays/LaunchOverlay.qml` — propiedades opcionales
   (`titulo`, `subtitulo`, `modo`) manteniendo su default actual, para dos usos
   sin crear un componente nuevo: el **aviso previo** ("el manual se abre fuera
   de ATTRACT") y el **fallo** cuando `openUrlExternally` devuelve `false`.

## Decisiones

- **`Qt.openUrlExternally` en vez de `launch:` de Pegasus, `subprocess` de
  Python o `QProcess`** — es la única vía que no necesita un `import`, y en este
  binario un import que no resuelve no degrada: mata el theme entero.
  Ver [`ADR 0021`](../../decisions/0021-manual-pdf-app-del-sistema.md).
- **`manual.file` explícito en vez de una convención de nombre implícita** — el
  theme no puede saber si un archivo existe; su única herramienta de disco es
  `XMLHttpRequest`. Mismo motivo por el que ADR-0014 rechazó `x-manual: 12`.
- **La validación de forma va en `doctor`, no en el theme** — a la altura del
  theme ya no se puede hacer nada, mismo criterio que el chequeo existente de
  `manual.pages` (`doctor.py:280-282`).
- **`encodeURIComponent` solo en el nombre, y no se toca `conEsquema()`** — esa
  función está en el camino caliente de todo lo que ya funciona (XHR de
  `data.json`, `magazine.json`, cada `Image` de página); tocarla es regresión
  gratis para arreglar un caso que todavía no existe ahí.
- **Se reusa `LaunchOverlay` en vez de crear un toast** — el theme no tiene
  sistema de mensajes, y `LaunchOverlay` ya es "lanzamos algo externo, acá está
  el feedback, me cierro solo" (L12-24, L149-153). Es el mismo problema.
- **Se avisa antes de abrir, aunque el aviso no arregle nada** — medido en la
  Fase 0: el visor abre por delante y Pegasus pierde el foco, y el theme no
  tiene con qué recuperarlo. El aviso no devuelve el foco; convierte una
  sorpresa en una decisión. La mitigación real (mapear `Alt+F4` en el encoder
  del joystick) es configuración del gabinete y queda fuera del repo.
- **Sin adapter por plataforma** — Qt ya *es* la capa de plataforma. Un
  `PlatformAdapter` con una rama Windows y una macOS que hacen la misma llamada
  sería abstracción decorativa.
- **La leyenda solo miente si se la deja** — `X ABRIR PDF` aparece únicamente
  cuando hay PDF. `ui/Leyenda.qml` L6-9 documenta con un bug real que una
  leyenda que miente es peor que ninguna.

## Riesgos

- ~~**`Qt.openUrlExternally` inerte en este binario**~~ — **descartado el
  2026-08-09**: la Fase 0 midió que existe y abre en macOS. Queda vivo solo para
  Windows, que no se corrió.
- **El jugador queda atrapado en el visor** — es el riesgo vivo. Medido: el
  visor abre por delante (bien) pero Pegasus pierde el foco y no hay API para
  recuperarlo, y el gabinete es solo joystick. Se mitiga con el aviso previo y,
  fuera del repo, mapeando `Alt+F4` en el encoder. Si igual ocurre, la salida ya
  no es un aviso mejor: es no ofrecer el PDF donde no hay retorno.
- **Devuelve `true` y no abre nada** — no hay mitigación: es el mismo límite que
  `game.launch()`. Se asume y se documenta; el aviso de error solo cubre el caso
  en que el SO rechaza.
- **Espacios y acentos en el nombre** — se mitiga con `encodeURIComponent` en el
  segmento, y `chk_nombre_windows` ya rechaza lo que Windows no acepta. La Fase 0
  mide cuál de las dos formas, cruda o codificada, es la que hay que usar.
- **Regresión en el visor de páginas** — el camino con `pages` no cambia: el PDF
  es un añadido, no un reemplazo. Se verifica con `sf2ce` (que tiene páginas) en
  Pegasus real.
- **Nada de esto se puede verificar en el Mac solo** — `ShellExecuteW` y
  `LSOpenCFURLRef` son caminos distintos, y Windows es producción
  ([`ADR-0003`](../../decisions/0003-cross-platform.md)).
