# Pacman — A · Arcade de pocos botones

## Identidad

| Campo | Valor |
|---|---|
| Título | Pacman |
| Plataforma | Arcade (MAME) |
| Identificador exacto | `pacman` (romset) |
| Variante | Lanzamiento exportado por Bally/Midway para Norteamérica (según `summary` de `metadata.pegasus.txt`; no verificado contra `-listxml`, que no distingue variantes regionales en este caso) |
| Emulador y versión | MAME 0.288 |
| Fuente del romset | 1980, Namco (licencia Midway) |

## Fuentes

- `mame.exe -listxml pacman` (2026-09-28, MAME 0.288 local) — **fuente autoritativa** para controles, y la que detectó el conflicto de abajo.
- COINDOOR: `games/juegos/arcade/pacman/game.json` (`cabinet`), vía ArcadeDB.
- `library/arcade/metadata.pegasus.txt` — summary con el error ya reportado.

## Objetivo

Recorrer el laberinto comiendo todos los puntos mientras se esquiva a los
cuatro fantasmas. Las cápsulas grandes invierten la persecución por un
tiempo. Objetivo real y verificado — la sinopsis acierta en esto.

## Controles originales (capa 1)

**Un solo control: el joystick de 4 direcciones. No hay botón de acción.**
Pac-Man se mueve solo; no dispara, no salta, no tiene ataque. Es el gabinete
arcade más citado como ejemplo de "solo joystick" en la historia del medio.

## Entradas técnicas (capa 2)

`mame.exe -listxml pacman`:

```
<input players="2" coins="2">
  <control type="joy" player="1" ways="4"/>
  <control type="joy" player="2" ways="4"/>
</input>
```

Ningún `<control>` trae atributo `buttons`. COINDOOR coincide exactamente:
`cabinet.buttons: 0`, `cabinet.button_list: []`, `cabinet.controls: "joystick
(4 direcciones)"`.

## Mapeo local (capa 3)

**No verificado.** Sin `cfg/pacman.cfg`: usa el default de MAME. Como no hay
botón que mapear, la única correspondencia física relevante es la del propio
stick — pendiente de Etapa D/F igual que el resto de la muestra.

## Inicio

Igual que en Street Fighter Alpha 2: sin `COIN1`/`START1` dedicados en el
panel de hoy, se arranca por teclado (`5`, después `1`).

## Salida

`Esc`, sin confirmación (`confirm_quit 0`).

## Multijugador

2 jugadores, por turnos (no simultáneo — es un arcade de 1980, alternancia
clásica, no cooperativo ni versus). No verificado contra `-listxml` más allá
de `players="2"`; es conocimiento general del hardware, no un dato que
`-listxml` distinga explícitamente como "turnos" vs. "simultáneo".

## Periféricos

Ninguno.

## Desconocidos

Ninguno relevante más allá de la variante regional exacta (ver Identidad).

## Conflictos

**Confirmado (2026-09-28): la sinopsis de `metadata.pegasus.txt` es
incorrecta.** Dice: *"El control se realiza con un joystick y un botón de
acción."* Tanto `-listxml` como el propio `cabinet` de COINDOOR (`buttons:
0`) contradicen esa frase — el conflicto no es solo contra una fuente
externa, es **interno al mismo `game.json` de COINDOOR** (su `cabinet` dice 0
botones, su `summary` afirma que hay uno). Corregir en COINDOOR antes de usar
este texto en la guía final.

## Trabajo manual

El cruce `-listxml` ↔ `cabinet` ↔ `summary` que encontró el conflicto. Ninguna
corrección se aplicó a `library/` (decisión 14: se corrige en COINDOOR).
