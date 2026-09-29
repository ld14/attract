# Street Fighter Alpha 2 — B · Lucha con 6 botones

## Identidad

| Campo | Valor |
|---|---|
| Título | Street Fighter Alpha 2 |
| Plataforma | Arcade (MAME) |
| Identificador exacto | `sfa2` (romset), descripción de MAME: "Street Fighter Alpha 2 (Europe 960229)" |
| Variante | Región Europa, revisión 960229. Es el set que trae este `library/arcade/` — no se probaron otros clones |
| Emulador y versión | MAME 0.288 (`library/_mame32/mame.exe`) |
| Fuente del romset | `sourcefile="capcom/cps2.cpp"`, año 1996, Capcom |

## Fuentes

- `mame.exe -listxml sfa2` (2026-09-28, MAME 0.288 local) — identidad, controles declarados.
- COINDOOR: `games/juegos/arcade/street-fighter-alpha-2/game.json` (`cabinet.button_list`), poblado desde ArcadeDB (`adb.arcadeitalia.net`) por `ArcadeDbPrecargaService`. Sin fecha de consulta propia registrada en el `game.json` leído.
- `library/arcade/metadata.pegasus.txt` (genre, developer, summary) — `x-procedencia: declarada`, campo que hoy no consume ningún comando (`docs/CONVENCION.md`).

## Objetivo

Combate 1 contra 1. Gana la ronda quien deja al rival sin vida o con más vida
al agotarse el tiempo; gana el combate quien se lleva 2 rondas.

## Controles originales (capa 1 — qué hace el jugador)

De `cabinet.button_list` (COINDOOR, vía ArcadeDB), 6 botones + palanca de 8
direcciones:

| Control lógico | Acción | Color declarado |
|---|---|---|
| `P1_BUTTON1` | Jab Punch | Blue |
| `P1_BUTTON2` | Strong Punch | Yellow |
| `P1_BUTTON3` | Fierce Punch | Red |
| `P1_BUTTON4` | Short Kick | Blue |
| `P1_BUTTON5` | Strong Kick | Yellow |
| `P1_BUTTON6` | Roundhouse Kick | Red |
| `P1_JOYSTICK_UP` | Jump | Blue |
| `P1_JOYSTICK_DOWN` | Crouch | Blue |

Es el layout clásico de 6 botones de Capcom (3 puños + 3 patadas, de suave a
fuerte). El color es el del gabinete original de fábrica, no del panel de
ATTRACT (ver §3.1 de `docs/como-se-juega.md`, hallazgo A4).

## Entradas técnicas (capa 2)

`mame.exe -listxml sfa2`:

```
<input players="2" coins="2" service="yes">
  <control type="joy" player="1" buttons="6" ways="8"/>
  <control type="joy" player="2" buttons="6" ways="8"/>
</input>
```

## Mapeo local (capa 3 — panel físico de ESTE gabinete)

**No verificado.** No existe `cfg/sfa2.cfg`: el juego usa el default de MAME.
El panel de hoy tiene 1 stick + 8 botones del jugador 1, sin Start/Coin
dedicados; el panel final (2 jugadores, con Start/Coin y flippers) sigue sin
instalar. La correspondencia botón lógico → posición física recién se calcula
en la Etapa D/F de `docs/como-se-juega.md`.

## Inicio

Sin `START1`/`COIN1` dedicados en el panel de hoy, arrancar depende del
**teclado**: `5` (insertar crédito) y `1` (Start P1) son los valores por
defecto de MAME para un teclado, y hoy son la única vía — el panel de 8
botones no tiene ninguno mapeado a `COIN1`/`START1` en este juego (a
diferencia de The Simpsons, que sí tiene ese remapeo provisorio, ver su
expediente).

## Salida

`Esc`, sin confirmación (`mame.ini`: `confirm_quit 0`, confirmado en §3.1 de
`docs/como-se-juega.md`).

## Multijugador

2 jugadores, versus (no cooperativo). Jugador 2 no verificado — el panel de
hoy no tiene su stick instalado.

## Periféricos

Ninguno: joystick + botones estándar, ambos disponibles (para P1) en el panel
de hoy.

## Desconocidos

- Si el jugador 2 (cuando se instale) usa el mismo layout de colores/acciones
  que el jugador 1 — se asume que sí por simetría de `-listxml`, pero no hay
  `P2_BUTTON*` listado explícitamente en `cabinet.button_list` de COINDOOR.
- Fecha exacta de consulta a ArcadeDB para este romset (el `game.json` leído
  no la registra).

## Conflictos

Ninguno detectado — a diferencia de Pacman y Shuffleshot, la sinopsis y los
datos de `cabinet` son consistentes entre sí y con `-listxml`.

## Trabajo manual

Cero para esta ficha: identidad, controles y sinopsis vinieron de COINDOOR
sin corrección. El trabajo manual de este expediente fue solo el cruce
verificador contra `-listxml`.
