# 007 · Trucos & combos — Spec

**Estado:** especificada, sin implementar. Nada la bloquea: los cuatro
experimentos corrieron durante la 005 y los datos ya están en los fixtures.

## Qué hace

El overlay **"TRUCOS & COMBOS"**: la última pieza del diseño de referencia.
Se abre desde la tarjeta *Hacks* del detalle y muestra los combos y los
códigos secretos de un juego.

Lo que lo distingue de una lista de texto —y la razón por la que el handoff le
dedica una sección entera— es que **la secuencia de inputs se dibuja como
botones, no como caracteres**. `"↓ ↘ → + K"` no se lee como texto: se ve como
tres teclas de dirección, un `+` y un botón de patada rojo.

Dos piezas:

1. **El tokenizer** (`core/InputTokens.js`): una función pura que parte un
   string de notación y devuelve tokens tipados. Sin UI.
2. **El overlay** (`overlays/CheatsOverlay.qml`): panel centrado con estética
   de tablero de comandos de arcade — marco HUD con escuadras, scanlines,
   secciones de COMBOS y CÓDIGOS SECRETOS.

## Por qué

Es el único bloque del diseño que **inventa un lenguaje visual** en vez de
maquetar datos. Y es el que más se nota en un gabinete: alguien parado frente
a la máquina no lee `"↓ ↙ ← ↓ ↙ ← + PP"`, pero sí reconoce media luna, media
luna, dos puños.

Además cierra el theme: con esto, todo lo que el handoff describe está hecho.

## La gramática de tokens

Es el corazón de la feature y el handoff la especifica entera. Se reproduce
tal cual, porque **es el contrato visual**, no una preferencia de estilo:

| Token | Cómo se reconoce | Cómo se dibuja |
|---|---|---|
| **Dirección** | Una tirada compuesta **solo** de `↑↓←→↖↗↘↙` | Tecla de 36×36, oscura, redondeada, con la flecha en accent y un resplandor suave |
| **Botón de cara** | `✕ × ⨯ ○ ◯ △ □` | Círculo de 34×34 con **color por convención**: `✕` azul `#3b6fe0`, `○` rojo `#e0454f`, `△` verde `#39b878`, `□` magenta `#d65bd6`, cada uno con su halo |
| **Gatillo / pad** | `^[LR][123]$` — `L1`, `R2`, `L3` | Pastilla oscura con la etiqueta |
| **Botón de arcade** | `^[PK]{1,3}$` — `P`, `K`, `PP` | Círculo de 34×34 con degradado y bisel: puño (`P`) rojo, patada (`K`) azul |
| **Separador** | `+` | Un `+` gris, sin caja |
| **Cualquier otra palabra** | lo que no encaje arriba | Texto corriente, gris apagado |

**Esa última fila es lo que hace que la gramática sirva de verdad**, y no es un
detalle: permite mezclar notación con lenguaje natural en la misma línea. El
fixture `"acercate y toca P dos veces seguidas"` se dibuja como prosa con un
botón de puño en el medio. Sin esa regla, cada truco tendría que ser notación
pura o texto puro.

## Contra qué se verifica

Los fixtures ya tienen los datos, cargados durante la 005 justamente para esto:

| Caso | Fixture | Qué ejercita |
|---|---|---|
| Direcciones + arcade | `dino` → `"↓ ↘ → + K"` | Teclas de flecha, `+`, botón `K` |
| Multi-botón | `dino` → `"↓ ↙ ← ↓ ↙ ← + PP"` | `PP` como un solo botón, no dos |
| **Prosa con un botón adentro** | `dino` → `"acercate y toca P dos veces seguidas"` | La regla que hace útil la gramática |
| Prosa pura | `dino` → `"En el test menu: PLAYERS 3"` | Nada se convierte en botón por error |
| Teclas con nombre | `dino` → `"↑ ↑ ↓ ↓ START"` | `START` como keycap |
| Solo combos, sin códigos | (falta) | Una sección vacía |
| Botones de cara y gatillos | **(falta)** | Los colores por convención y `L1`/`R2` |

**Las dos últimas filas no tienen fixture todavía.** Son la mitad de la
gramática —los cuatro colores de los botones de cara y los gatillos— sin nada
contra qué comprobarse. Se agregan como tarea 0, con el mismo criterio que las
páginas numeradas de la 006: si no hay dato, no hay verificación.

## Criterios de aceptación

- [ ] El overlay abre desde la tarjeta *Hacks* y cierra con B/Escape,
      devolviendo el foco al detalle.
- [ ] Los seis tipos de token se dibujan como manda la tabla, con los colores
      por convención de los botones de cara.
- [ ] `PP` es **un** botón, no dos.
- [ ] Una línea puede mezclar prosa y botones.
- [ ] Las secciones COMBOS y CÓDIGOS SECRETOS muestran su contador (`0N MOVS`,
      `0N SECRETOS`).
- [ ] El cuerpo scrollea con arriba/abajo cuando no entra.
- [ ] El tokenizer es una función **pura**, sin UI, verificable sola.
- [ ] Un `input` vacío o raro no rompe nada: cae a prosa.

## Fuera de alcance

- **Editar trucos desde el theme.** El theme lee `data.json`, no lo escribe
  (ADR-0002: la metadata es artefacto, y los datos ricos los produce la
  ingesta o una persona).
- **Adivinar la notación.** Si un `input` viene en un formato que la gramática
  no reconoce, se muestra como prosa. No se intenta inferir que `"QCF+P"` es un
  cuarto de círculo: eso sería heurística frágil, y el contrato ya define la
  notación esperada.
- **Íconos de gamepad reales** (dibujar un mando). El diseño usa formas
  geométricas y colores, no ilustraciones.
- **Una pantalla de trucos aparte del detalle.** Es un overlay, como el visor.

## Riesgos

- **La gramática es del handoff, no del contrato de datos.** `data.json` guarda
  `input` como string libre (ADR-0015); nada obliga a que use esta notación.
  Un juego cuyos trucos estén escritos en prosa se va a ver como prosa — que
  es el comportamiento correcto, pero conviene tenerlo claro antes de que
  alguien lo reporte como bug.
- **Los glifos dependen de la fuente.** `↖↗↘↙` y `✕○△□` tienen que existir en
  Chakra Petch / Sora, o Qt los va a sustituir por otra fuente y se van a ver
  desalineados. Se verifica en pantalla, no se asume.
