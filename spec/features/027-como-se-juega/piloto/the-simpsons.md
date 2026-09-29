# The Simpsons — C · Cooperativo

## Identidad

| Campo | Valor |
|---|---|
| Título | The Simpsons |
| Plataforma | Arcade (MAME) |
| Identificador exacto | `simpsons` (romset) |
| Variante | No verificada contra `-listxml` (no se pidió `cloneof`/`description` en la consulta de este piloto) |
| Emulador y versión | MAME 0.288 |
| Fuente del romset | 1991, Konami |

## Fuentes

- `mame.exe -listxml simpsons` (2026-09-28) — controles, jugadores.
- `library/_mame32/cfg/simpsons.cfg` — remapeo ya existente en este gabinete, evidencia de uso previo (el propio `docs/como-se-juega.md` §3.1 ya lo señalaba antes de este piloto).
- COINDOOR: `games/juegos/arcade/the-simpsons/game.json` (`cabinet.button_list`), vía ArcadeDB.
- `library/arcade/metadata.pegasus.txt` (summary, genre, players).

## Objetivo

Un robo de joyas sale mal y Smithers secuestra a Maggie; hasta 4 jugadores
(Homer, Marge, Lisa, Bart) lo persiguen en un beat-'em-up de desplazamiento
horizontal, hasta el enfrentamiento final contra Mr. Burns.

## Controles originales (capa 1)

De `cabinet.button_list` (COINDOOR / ArcadeDB):

| Control lógico | Acción | Color declarado |
|---|---|---|
| `P1_BUTTON1` | Attack | Red |
| `P1_BUTTON2` | Jump | Blue |
| `P1_JOYSTICK_*` | Up/movimiento | Red |

Dos botones por jugador: ataque y salto. Cada personaje tiene un arma propia
(aspiradora, cuerda, patineta, puños) pero eso es una variación visual del
mismo botón de "Attack", no un control adicional.

## Entradas técnicas (capa 2)

`mame.exe -listxml simpsons`:

```
<input players="4" coins="4" service="yes">
  <control type="joy" player="1" buttons="2" ways="8"/>
  <control type="joy" player="2" buttons="2" ways="8"/>
  <control type="joy" player="3" buttons="2" ways="8"/>
  <control type="joy" player="4" buttons="2" ways="8"/>
</input>
```

## Mapeo local (capa 3)

**Existe un remapeo, pero es provisorio y no está verificado contra el panel
final.** `cfg/simpsons.cfg` (autogenerado por MAME al cerrar el juego, trae
también `<counters>` de créditos y `<mixer>` de audio, como ya documentaba
`docs/como-se-juega.md` §3.1):

| Entrada lógica | Remapeada a |
|---|---|
| `COIN1` | `JOYCODE_1_BUTTON7` |
| `P1_BUTTON1` (Attack) | `JOYCODE_1_BUTTON5` |
| `P1_BUTTON2` (Jump) | `JOYCODE_1_BUTTON1` |
| `START1` | `JOYCODE_1_BUTTON6` |

Esto es un remapeo a mano para el panel **provisorio** de 8 botones (§3.2 del
plan), no una correspondencia medida y verificada del panel **final**. Por
la decisión de éxito del plan ("un botón físico se señala solo con
correspondencia resuelta y verificada"), la guía **no puede** todavía decir
"apretá el botón de tal posición": puede decir que existen `COIN1`/`START1`
mapeados a algo en este gabinete, pero no en qué posición física están esos
`JOYCODE_1_BUTTON5/6/7` sin medirlo (Etapa F).

## Inicio

A diferencia de Pacman y SFA2: **este juego sí tiene `COIN1` y `START1`
alcanzables desde el panel de 8 botones** (aunque su posición física no esté
medida). Es el único de los 3 arcades importados con esa propiedad.

## Salida

`Esc`, sin confirmación (`confirm_quit 0`). El remapeo de `simpsons.cfg` no
toca ninguna tecla de UI/salida, solo entradas de juego.

## Multijugador

Hasta 4 jugadores simultáneos, cooperativo (todos contra los enemigos, no
entre sí). Jugadores 2-4 no verificados en la práctica — el panel de hoy
solo tiene el stick y los botones del jugador 1 instalados.

## Periféricos

Ninguno.

## Desconocidos

- Si el remapeo de `simpsons.cfg` sigue vigente cuando se instale el panel
  final, o si hay que rehacerlo (cambia el número de botones físicos
  disponibles).
- Layout de colores/acciones para los jugadores 2-4 — `cabinet.button_list`
  solo trae entradas de `P1_*`.

## Conflictos

Ninguno detectado entre `-listxml`, `cabinet` y `summary`.

## Trabajo manual

Ninguno de contenido. El remapeo de `simpsons.cfg` ya existía en la máquina
antes de este piloto (evidencia de una partida jugada, no de una preparación
para la guía).
