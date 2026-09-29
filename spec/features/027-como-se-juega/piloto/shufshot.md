# Shuffleshot — D · Periférico o control especial

## Identidad

| Campo | Valor |
|---|---|
| Título | Shuffleshot |
| Plataforma | Arcade (MAME) |
| Identificador exacto | `shufshot` (romset) |
| Variante | No verificada contra `-listxml` más allá de identidad básica |
| Emulador y versión | MAME 0.288 |
| Fuente del romset | 1997, Incredible Technologies |

## Fuentes

- `mame.exe -listxml shufshot` (2026-09-28) — **fuente autoritativa**, detectó el conflicto de abajo.
- COINDOOR: `games/juegos/arcade/shufshot/game.json` (`cabinet.button_list`), vía ArcadeDB.
- `library/arcade/metadata.pegasus.txt` (genre, summary — el summary está mal, ver Conflictos).

## Objetivo

Deporte de shuffleboard (disco deslizado sobre una pista, tipo "shuffleboard"
de bar) llevado a máquina arcade: apuntar y lanzar un disco con la trackball
para acumular puntos, compitiendo contra otro jugador. Esto sale del
`genre` (`Deportes / Shuffleboard`) y de las acciones reales de
`cabinet.button_list` (Zoom, Wax, movimiento X/Y de trackball) — **no** del
`summary`, que describe otro juego (ver Conflictos).

## Controles originales (capa 1)

De `cabinet.button_list` (COINDOOR / ArcadeDB):

| Control lógico | Acción |
|---|---|
| `P1_BUTTON1` | Zoom |
| `P1_BUTTON2` | Wax (encerar la pista, mecánica real de shuffleboard) |
| `P1_TRACKBALL_X` / `X_EXT` | Izquierda / Derecha |
| `P1_TRACKBALL_Y` / `Y_EXT` | Arriba / Abajo |

Sin colores declarados para estos botones (`color: ""` en los cuatro).

## Entradas técnicas (capa 2)

`mame.exe -listxml shufshot`:

```
<input players="2" coins="3" service="yes">
  <control type="trackball" player="1" buttons="2" minimum="0" maximum="255" sensitivity="25" keydelta="32" reverse="yes"/>
  <control type="trackball" player="2" buttons="2" minimum="0" maximum="255" sensitivity="25" keydelta="32" reverse="yes"/>
</input>
```

## Mapeo local (capa 3)

**No aplica: es el caso de "periférico no disponible".** El panel declarado
del gabinete (§3.2 de `docs/como-se-juega.md`: 2× stick+8 botones, Start/Coin
por jugador, 2 flippers, teclado y mouse) **no incluye ninguna trackball**,
ni hoy ni en el diseño final. Esto es exactamente el criterio de aceptación
de la spec 027: *"Un periférico que el gabinete no tiene se muestra como
requisito, no como un botón."* La guía de Shuffleshot tiene que decir "este
juego necesita una trackball, que este gabinete no tiene" y no dibujar
ningún control físico para los 4 controles de movimiento.

Los dos botones (`Zoom`, `Wax`) sí podrían mapearse a un botón normal del
panel, pero sin la trackball el juego no es jugable igual — no alcanza con
resolver esos dos.

## Inicio

`COIN1`/`START1` sin remapeo conocido (no hay `cfg/shufshot.cfg`) — mismo
caso que Pacman y SFA2: depende del teclado hoy.

## Salida

`Esc`, sin confirmación (`confirm_quit 0`).

## Multijugador

2 jugadores. `-listxml` no distingue si es competitivo o cooperativo; por el
género (shuffleboard, un disco por turno) es razonable asumir competitivo,
pero **no está verificado** — se anota como supuesto, no como dato.

## Periféricos

**Trackball, requerida para el movimiento — no disponible en este
gabinete.** Es el caso ejemplo de esta categoría en la muestra (A6).

## Desconocidos

- Si `Zoom`/`Wax` alcanzan para algo útil sin poder mover el disco (probable
  que no: son acciones secundarias).
- Mecánica exacta de turnos/puntaje — no se investigó más allá del género.

## Conflictos

**Confirmado (2026-09-28): la sinopsis de `metadata.pegasus.txt` describe un
juego distinto.** Empieza con *"Shuffleship es un juego de arcade..."* — el
nombre ya no coincide (**"Shuffleship"**, no "Shuffleshot") — y sigue
describiendo una nave espacial disparando en niveles con un tablero de
fichas: un shoot-'em-up con puzzle, nada que ver con shuffleboard. El
`genre` (`Deportes / Shuffleboard`) y el `cabinet` (trackball + Zoom/Wax) sí
son consistentes entre sí y con `-listxml` — el dato roto es puntualmente el
`summary`. Corregir o regenerar en COINDOOR antes de usarlo en la guía final.

## Trabajo manual

El cruce `-listxml` ↔ `cabinet` ↔ `summary` que encontró el conflicto, y la
identificación de "requiere periférico ausente" a partir del perfil
declarado del gabinete (§3.2). Ninguna corrección se aplicó a `library/`.
