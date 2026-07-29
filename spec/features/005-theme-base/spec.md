# 005 · Theme de producción, base — Spec

**Estado:** especificada, sin implementar. Tres experimentos previos sin
correr bloquean decisiones de esta feature (ver §Riesgos y `tasks.md`).

## Qué hace

Crea `themes/attract/`, el theme QML de producción de ATTRACT, con sus
cimientos y las dos pantallas principales del diseño de referencia
(`design_handoff_game_detail/`):

- **Pantalla de librería:** barra superior (wordmark, pills de filtro, reloj),
  bloque hero del juego enfocado (sistema/año/género, título, sinopsis,
  botones JUGAR y VER DETALLE, contador), y el rail horizontal de carátulas
  con la tarjeta enfocada elevada y resaltada con su accent.
- **Pantalla de detalle:** barra superior, columna izquierda (panel de
  carátula + botón JUGAR) y columna de información (título, chips de metadata,
  box art con badge de formato, bloque NOTA DE LA CRÍTICA, sinopsis, tarjetas
  de CONTENIDO EXTRA).
- **Overlay de lanzamiento** mientras Pegasus arranca el emulador.

Y debajo de las dos, la infraestructura que las features 006 y 007 van a
reusar: los tokens de diseño, la resolución de rutas sin hardcodear, la
lectura de `data.json` y los átomos visuales.

Todo se dibuja en un canvas fijo de 1280×720 escalado entero
([`ADR-0016`](../../decisions/0016-canvas-fijo-escalado.md)).

**Fuera de esta feature, en las siguientes:** el video de gameplay, el
carrusel de revistas y el visor de documentos (006); el overlay de trucos &
combos (007). El panel de carátula del detalle muestra la carátula estática
en 005; el video se le enchufa después sin rehacer el layout.

## Por qué

Es la primera vez que el proyecto tiene un theme de verdad. Todo lo hecho
hasta acá —12 ADR, `CONVENCION.md`, los fixtures, `doctor`, `synopsis`,
`ingest`— define y valida un modelo de datos que hasta hoy **nadie mira en
pantalla**. `themes/attract-debug/` dumpea texto plano; no es una interfaz,
es un microscopio.

Esta feature cierra el circuito: los datos que ATTRACT produce y valida pasan
a verse. Y al verse, se empiezan a descubrir los huecos que ningún test
encuentra — que es exactamente para lo que existen los fixtures de
degradación que ya están puestos a propósito.

## Contra qué se verifica

Los fixtures ya encarnan los casos límite. No hay que inventar datos:

| Caso | Fixture | Qué tiene que pasar |
|---|---|---|
| Juego sin `data.json` | `media/mok/` | Todos los bloques ricos con su mensaje de §2.3. Sin crash |
| Juego sin `x-set` | bloque `EXPERIMENTO` (`dino.zip`) | Resuelve el set por el nombre del archivo |
| Sin carátula | `mok` (solo `marquee` + `poster`) | Cadena de fallback §2.2: cae a `poster` |
| Reseña parcial | `media/dino/data.json` (`{"review": {"score": 94}}`) | Muestra el 94; las seis categorías en `"-"` |
| Sin cobertura en revistas | `media/mok/`, `media/sf2ce/` | `"Sin cobertura en revistas"` |
| Varios `file:` | `TEST MULTIFILE` | Lanza el selector nativo de Pegasus (ya confirmado, ADR-0004) |
| Acentos en NFC | `MICROMANÍA`, `"báculos mágicos"` en el `summary:` de `mok` | Se muestran bien |

## Criterios de aceptación

- [ ] `make theme` instala `themes/attract/` y Pegasus lo carga sin el error
      "Theme loading failed" — con singletons y subcarpetas incluidos.
- [ ] La librería lista los juegos del fixture, se recorre con flechas
      izquierda/derecha y con el gamepad (vía `api.keys`, no `Qt.Key` crudo).
- [ ] El hero muestra el título, año, género, sistema y sinopsis del juego
      enfocado, y el contador `NN / NN` correcto.
- [ ] La tarjeta enfocada se eleva y toma el accent de su juego; las demás
      quedan al 50% de opacidad. El rail sigue al foco.
- [ ] Enter/A sobre la tarjeta ya enfocada abre el detalle. Enter/A sobre otra
      tarjeta solo la enfoca (patrón TV: primer toque enfoca, segundo abre).
- [ ] El detalle muestra los chips de metadata, la sinopsis y el badge de
      formato tomado de `x-formato` — **no** de `mediaFor()`, que miente en 4
      de 5 juegos (`docs/mapeo-mockup-pegasus.md`).
- [ ] El bloque NOTA DE LA CRÍTICA distingue los dos niveles de "sin dato" de
      `CONVENCION.md` §2.3: sin `review` → bloque entero en "Sin Información";
      `review` parcial → muestra lo que hay, categorías faltantes en `"-"`.
- [ ] El foco del detalle recorre `[JUGAR] → [extras]` en orden, y
      Escape/B vuelve a la librería.
- [ ] Un juego sin `data.json` se ve completo y degradado, sin crash y sin
      huecos en el layout.
- [ ] Ninguna ruta absoluta hardcodeada en el theme — todo se resuelve en
      runtime desde `api` (cierra la deuda de ADR-0003 que arrastran los dos
      experimentos archivados).
- [ ] `make test` y `make doctor` siguen en verde.

## Fuera de alcance

- **Video de gameplay, carrusel de revistas, visor de documentos** — feature
  006. El panel de carátula queda listo para recibir el video sin rehacer el
  layout.
- **Overlay de trucos & combos y su tokenizer** — feature 007.
- **Las páginas falsas del prototipo** (tapa de revista mockeada, páginas de
  reseña en papel pergamino, diagramas de control dibujados en CSS). El propio
  handoff dice que ningún placeholder llega a producción, y los fixtures ya
  tienen escaneos reales. Portar un generador de páginas falsas sería escribir
  código con fecha de vencimiento. Se conservan solo los dos placeholders que
  son estados reales del contrato: el color-wash con accent al final de la
  cadena de carátula (§2.2) y los mensajes de §2.3.
- **Reproducir los efectos CSS que Qt 5.15 no tiene** (`backdrop-filter`,
  `color-mix`, `conic-gradient`, `mix-blend-mode`). Se aproximan, y cada
  aproximación lleva el comentario que el handoff pide.
- **Filtros reales en las pills de la barra superior** (TODOS / ARCADE /
  CONSOLA / FAVORITOS). Se dibujan como el diseño manda; conectarlas a
  `api.filters` es otra feature.
- **Bundlear las fuentes** — los `.ttf` de Chakra Petch, Sora y JetBrains Mono
  los baja el autor (el gabinete es offline, no se pueden pedir en runtime).
  El theme carga lo que haya y cae a las fuentes del sistema si faltan.
- **Cambiar `themes/attract-debug/`** — es la evidencia viva de ADR-0001 y el
  archivo sobre el que se copian los experimentos. Se agrega al lado, no se
  pisa (regla de `CLAUDE.md`).

## Riesgos

Tres preguntas sin responder bloquean decisiones de diseño, no solo de
implementación. Cada una tiene su experimento escrito y sin correr en
`themes/experimentos/`:

1. **`rutas-relativas.qml`** — ¿existe `game.files` y da la ruta absoluta de
   la ROM? De ahí sale `media/<set>/`. Sin esto no hay `data.json`, y el plan
   B (derivar de un asset nativo) falla en juegos sin ningún asset.
2. **`graphical-effects.qml`** — ¿resuelve `import QtGraphicalEffects`? Define
   si hay blur y glow de verdad o si todo se aproxima con rectángulos planos.
   El módulo **no** está en las dependencias de build declaradas de Pegasus,
   igual que PDF, que efectivamente no existía (ADR-0007).
3. **`multimedia-loop.qml`** — bloquea la 006, no esta. Se corre igual junto
   con los otros dos porque comparte el trabajo de instalar y abrir.

Un cuarto riesgo no tiene experimento propio porque se responde solo al dar
el primer paso de la implementación: **si un theme de Pegasus soporta
subcarpetas y singletons vía `qmldir`**. La arquitectura de este plan asume
que sí. Si no, la salida es aplanar el árbol y reemplazar los singletons por
un `QtObject` instanciado una vez en `theme.qml` — es un cambio mecánico,
pero conviene descubrirlo con el esqueleto vacío y no con veinte componentes
escritos encima.
