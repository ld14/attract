# 007 · Trucos & combos — Tareas

_Checklist accionable derivada del `plan.md`._

## 0 · Fixtures: la mitad de la gramática no tiene datos

Los combos que hay cubren direcciones, `+`, `P`/`K`/`PP`, prosa y `START`.
**No cubren los botones de cara (`✕○△□`) ni los gatillos (`L1`/`R2`)** — o sea
los cuatro colores por convención y un tipo entero de token, sin nada contra
qué comprobarse.

- [ ] Agregar a `library/preview/media/dino/data.json` combos con esa notación.
      Va en `preview` y **no** en `fixtures` a propósito: un combo con botones
      de PlayStation en un juego de arcade sería un dato falso, y los fixtures
      encarnan contratos, no ejemplos de relleno.
- [ ] Dejar un juego **con combos y sin códigos**, para ver una sección vacía.

## 1 · El tokenizer

- [ ] `core/InputTokens.js` — `partir(texto, variante)` → `[{tipo, valor,
      color}]`. **Función pura: sin QML, sin UI, sin colores de CSS.**
- [ ] El orden de las reglas es la gramática: `+`, flechas, botones de cara,
      gatillos, botones de arcade, keycaps (solo variante `codigo`), prosa.
- [ ] **Las palabras de prosa consecutivas se fusionan en un solo token.** Sin
      eso, `"acercate y toca P dos veces"` da siete tokens de texto que se
      dibujan con espacios raros. Lo hace el prototipo y hay que portarlo.
- [ ] Casos borde: string vacío, solo espacios, un `+` suelto, una flecha
      pegada a una letra (`↓K` no es una dirección).

## 2 · Verificación del tokenizer, **sin abrir Pegasus**

Es la única parte del theme que se puede verificar sin mirar la pantalla, y
justamente es donde un error cuesta ver a ojo: que `PP` salga como dos botones
en vez de uno no salta a la vista en una captura.

- [ ] Archivo de casos entrada → salida esperada, corrido a mano.
- [ ] **No va en `tests/`**: ese directorio es de pytest y prueba
      `src/attract/`, que es Python. Meter ahí una prueba de JavaScript
      rompería `make test` en una máquina sin node.
- [ ] Casos mínimos: los cinco tipos de token, `PP` como uno solo, prosa con
      un botón adentro, prosa pura que no se convierta en botones.

## 3 · La fila de tokens

- [ ] `ui/InputTokenRow.qml` — un `Flow` que mapea `tipo` → delegate. **No
      parsea nada.** Envuelve: una secuencia larga no entra en una línea.
- [ ] Tamaños del handoff: 36×36 direcciones, 34×34 botones de cara y arcade,
      pastilla para gatillos.
- [ ] Los colores por convención (`✕` azul, `○` rojo, `△` verde, `□` magenta)
      **son del handoff, no elegidos**: son la convención de PlayStation y por
      eso se reconocen de un vistazo.

## 4 · El overlay

- [ ] `overlays/CheatsOverlay.qml` — panel de `min(900, ancho)` × 88% del alto,
      borde teñido con accent, scanlines y las cuatro escuadras HUD. El patrón
      ya está probado en `ReviewCard`.
- [ ] Cabecera: título, `{juego} · LISTA DE COMANDOS`, chip `P1`, cerrar.
- [ ] Secciones **COMBOS** y **CÓDIGOS SECRETOS** con su regla y su contador
      (`0N MOVS`, `0N SECRETOS`).
- [ ] **Las secciones vacías se ocultan, y §2.3 no aplica acá** — el overlay se
      abre a pedido y solo cuando hay contenido. La tarjeta *Hacks* del
      detalle, que sí es parte de una pantalla, sigue mostrándose siempre.
- [ ] Cuerpo scrolleable con arriba/abajo.
- [ ] Pie: `— PRESIONÁ B PARA VOLVER —`.
- [ ] Se abre desde la tarjeta *Hacks* y cierra con B/Escape, devolviendo el
      foco al detalle. El patrón del `Loader` ya está probado con el visor.

## 5 · Verificación contra Pegasus real

| Caso | Fixture | Qué tiene que pasar |
|---|---|---|
| Direcciones + arcade | `dino` → `"↓ ↘ → + K"` | Tres teclas de flecha, un `+` gris, un botón azul de patada |
| Multi-botón | `dino` → `"↓ ↙ ← ↓ ↙ ← + PP"` | `PP` como **un** botón rojo |
| Prosa con botón | `dino` → `"acercate y toca P dos veces seguidas"` | Texto corriente con un botón de puño en el medio |
| Prosa pura | `dino` → `"En el test menu: PLAYERS 3"` | Nada convertido en botón por error |
| Botones de cara | el fixture nuevo | Los cuatro colores de la convención |
| Gatillos | el fixture nuevo | `L1`/`R2` como pastillas |
| Sección vacía | el juego sin códigos | La sección no aparece |
| **Los glifos** | cualquiera | `↖↗↘↙` y `✕○△□` bien alineados y del mismo tamaño. Si Qt los sustituye por otra fuente, se nota acá |

## 6 · Cierre

- [ ] `make test` y `make doctor` en verde.
- [ ] Anotar en `docs/plataforma-pegasus.md` lo que se aprenda de nuevo.
- [ ] Mover `007` a "Hecho" en `../../constitution/roadmap.md`, actualizar el
      mapa del repo, y **declarar el theme completo**: con esta feature, todo
      lo que el handoff describe está implementado.
- [ ] Lo que sigue sin verificarse en el gabinete (Windows) queda anotado, no
      dado por hecho.
