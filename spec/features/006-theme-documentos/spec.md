# 006 · Video, revistas y visor de documentos — Spec

**Estado:** especificada, sin implementar. No hay experimentos bloqueando: los
cuatro corrieron durante la 005 (ver `docs/plataforma-pegasus.md`).

## Qué hace

Las tres piezas del diseño de referencia que la 005 dejó afuera, todas colgando
del detalle de un juego:

1. **Video de gameplay** en el panel de carátula, con los controles de
   transporte que dibuja el theme (play/pausa, volumen en pasos, medidor de 5
   barras, mute).
2. **Carrusel "NOTAS EN REVISTAS"** en la columna izquierda: las tapas de las
   revistas que cubren ese juego, dos visibles a la vez.
3. **Visor de documentos paginado**, en pantalla completa, compartido por
   revistas y manual: hojear, saltar por miniaturas, zoom y paneo.

El layout de la 005 **ya los espera**: el panel de carátula tiene su lugar y la
columna izquierda tiene el hueco del carrusel.

## Por qué

Es lo que separa a ATTRACT de cualquier otro frontend. Un rail de carátulas lo
tiene cualquiera; poder abrir la nota de la revista donde ese juego salió en
1993 no. Y es la razón de ser de todo el modelo de datos de revistas
([`ADR-0010`](../../decisions/0010-contrato-magazine-json-extendido.md)), que
hoy existe y **no lo consume nadie**.

## El contrato que consume

Ya está definido y validado por `attract doctor`. Nada nuevo que decidir:

```
data.json → mags: [{ref}]          → media/_magazines/<ref>/magazine.json
data.json → manual: {pages: [...]} → media/<set>/_manual/
```

`magazine.json` trae `pages[]` (**todas** las páginas del escaneo) y
`articles[]` con `game`, `startPage`, `pages[]`, `type` y `confidence`.

### `startPage` es un índice 1-based sobre `pages[]` — resuelto acá

El contrato de ADR-0010 nunca lo dijo. Se resuelve por aritmética, no por
preferencia: el fixture tiene **8** entradas en `pages[]` y sus artículos
referencian **3 a 8**. Con índices 0-based el `8` se saldría del rango; con el
número impreso en la página no habría forma de mapearlo a un archivo, porque el
contrato no guarda esa correspondencia. **1-based sobre `pages[]` es la única
lectura que cierra.**

Queda como chequeo de `attract doctor`, no como comentario: que `startPage` y
cada valor de `articles[].pages` caigan en `1..pages.length`. Un artículo que
apunte fuera de rango hoy pasa el validador y explota recién en el visor.

## Cómo funciona la entrada al visor

Esto es lo que le da sentido al modelo de datos, y sale de
`docs/decisiones/2026-07-23.md` §5:

> Se entra **directo a la nota** del juego, pero después se puede hojear la
> revista **entera**. La nota es la puerta de entrada, no un límite.

En concreto: el visor abre en `startPage` del artículo cuyo `game` coincide con
el `<set>`, pero su modelo son **todas** las `pages[]` de la revista. Las
páginas del artículo se marcan en la tira de miniaturas — eso sale gratis del
contrato y no estaba en el diseño.

## Contra qué se verifica

| Caso | Fixture | Qué tiene que pasar |
|---|---|---|
| Revista con artículo del juego | `dino` → `micromania-16` | Abre en la página 3, se hojean las 8, las del artículo (3,4,5,7,8) marcadas |
| Artículo que salta una página | el mismo — la 6 es `publicidad` | Se puede hojear a la 6 igual: el visor recorre la revista entera |
| `ref` colgado | `sf2ce` → `revista-que-no-existe` | El carrusel muestra que esa revista no está. **Sin crash** |
| Manual sin revistas | `sf2ce` → `_manual/` de 4 págs | Se abre el mismo visor, con el manual |
| Sin revistas ni manual | `mok` | Los dos bloques con su mensaje de §2.3 |
| Juego sin video | casi todos | El panel muestra la carátula, no un hueco (§2.1 nota 2) |
| Video que loopea | `library/preview/media/dino/video.mp4` | Reengancha solo; el transporte responde |

## Criterios de aceptación

- [ ] El panel de carátula muestra el video cuando hay `assets.video`, en loop,
      y cae a la carátula cuando no.
- [ ] Los controles de transporte se revelan **por foco**, no por hover: el
      gabinete no tiene mouse. El handoff lo pide explícitamente.
- [ ] Play/pausa, volumen por pasos de 0.2, medidor de 5 barras y mute
      funcionan y se ven reflejados.
- [ ] Al salir del detalle el `MediaPlayer` suelta el `source`. Sin esto el
      gabinete acumula decoders.
- [ ] El carrusel muestra las tapas de las revistas del juego, dos a la vez,
      con contador `1–2 / N`. Con más de dos, aparecen las flechas.
- [ ] El nombre de la revista se muestra limpio según la regla ya cerrada en
      ADR-0010: sacar la extensión de `name`, `-`/`_` → espacio, y anteponer
      `Nº<issue> (<year>)` si están.
- [ ] El visor abre en `startPage` del artículo del juego y permite hojear
      **toda** la revista.
- [ ] Las páginas del artículo se distinguen en la tira de miniaturas.
- [ ] Con más de una revista, se puede cambiar de revista sin salir del visor.
- [ ] El manual abre el **mismo** visor, con el mismo modelo de páginas.
- [ ] Zoom en 4 pasos y paneo **con D-pad**, no solo con mouse.
- [ ] Escape/B cierra el visor y devuelve el foco al detalle.
- [ ] Una página que no carga no rompe el visor.
- [ ] `attract doctor` valida que `startPage` y `articles[].pages` estén en
      rango, con sus tests.

## Fuera de alcance

- **El overlay de trucos & combos y su tokenizer** — feature 007.
- **Las páginas falsas del prototipo** (tapa de revista mockeada, páginas de
  reseña en papel pergamino, diagramas de control dibujados en CSS). Mismo
  criterio que en la 005: el handoff dice que ningún placeholder llega a
  producción, y portar un generador de páginas falsas es escribir código con
  fecha de vencimiento. Una página que falta se muestra como lo que es.
- **Producir los escaneos.** ATTRACT consume el contrato, no lo genera
  ([`ADR-0009`](../../decisions/0009-frontera-produccion-consumo-revistas.md)).
- **Una sección "explorar revistas"** independiente del juego. El modelo de
  datos la permite, pero no está en el diseño.
- **Sonido del video por defecto.** Arranca en mute: un gabinete que se pone a
  sonar solo al mover el foco es insoportable. El usuario lo activa.

## Riesgos

- **Nada de esto se probó en el gabinete (Windows).** Lo que más riesgo tiene
  es `loops` de QtMultimedia, que históricamente varía entre backends de
  plataforma. Ya está anotado en `docs/plataforma-pegasus.md` §5.
- **Las páginas de revista de `fixtures/` pesan 0 bytes**, así que el visor no
  se puede verificar contra ellas — el mismo agujero que tuvo la cadena de
  carátula en la 005, y se resuelve igual: páginas generadas y numeradas.
- **Peso de los escaneos.** Una página real es un JPEG grande y la hoja mide
  560×760 sobre un lienzo de 1280×720. Sin `sourceSize` se decodifica entera en
  memoria, por página.
- **El zoom multiplica ese peso.** A 2.4× hace falta más resolución, no la
  misma imagen escalada.
