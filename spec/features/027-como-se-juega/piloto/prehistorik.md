# Prehistorik — E · DOS de teclado

## Identidad

| Campo | Valor |
|---|---|
| Título | Prehistorik |
| Plataforma | MS-DOS (DOSBox Staging) |
| Identificador exacto | `x-set: prehistorik`, carpeta `library/msdos/prehistorik/`, ejecutable `HISTORIK.EXE` (ver `autoexec` de `dosbox.conf`) |
| Variante | La copia instalada en `Prehisto/` — no se verificó versión/idioma contra una fuente externa |
| Emulador y versión | DOSBox Staging (binario en `emulators/dosbox-staging/`, versión no confirmada en este piloto) |
| Desarrollador/editor | Titus Software / Titus Interactive, 1991 |

## Fuentes

- `library/msdos/prehistorik/dosbox.conf` (generado por ATTRACT, `src/attract/dosbox.py`) — config efectiva.
- `library/msdos/metadata.pegasus.txt` (summary, genre, launch) — `x-procedencia: declarada`.
- Prueba directa en el gabinete (A2, 2026-09-27): confirmación de la tecla de salida, aunque en un juego distinto (ver Salida).

## Objetivo

Plataformas 2D ambientado en la era de las cavernas: recolectar comida,
esquivar peligros y derrotar enemigos a través de niveles con obstáculos,
trampas y jefes, armado con una honda y armas rudimentarias.

## Controles originales (capa 1)

Plataformero de teclado clásico de DOS: movimiento direccional + salto +
disparo/ataque. **No verificado el mapeo de teclas exacto** (qué tecla es
salto, cuál es disparo) — no hay una fuente equivalente a `-listxml`/ArcadeDB
para juegos de DOS en este proyecto; haría falta el manual original o
probarlo en el gabinete.

## Entradas técnicas (capa 2)

`dosbox.conf`: `[joystick] joysticktype = disabled` — la palanca está
deshabilitada a propósito (generador de `dosbox.py:158,185`, según ya
documentaba `docs/como-se-juega.md` §3.1). No hay `mapperfile` propio: usa
el layout de teclado nativo del juego, sin remapeo de DOSBox.

## Mapeo local (capa 3)

No aplica en el sentido de "botón físico": es un juego 100% de teclado, y el
teclado es fijo en el gabinete (§3.2). No hay panel que mapear.

## Inicio

Doble clic/Enter en Pegasus lanza `dosbox.exe --working-dir ... --nolocalconf
--conf dosbox.conf`, que corre el `autoexec` (`mount c "Prehisto"`, `HISTORIK.EXE`).
Sin pasos manuales adicionales para arrancar — a diferencia del arcade, no
hace falta insertar crédito.

## Salida

**Ctrl+F9**, confirmado en el gabinete (A2, 2026-09-27) para un DOS de config
generada. **No se probó específicamente en Prehistorik** — se confirmó en
otro DOS de la misma categoría (config generada, sin `mapperfile` propio,
`joysticktype = disabled`), y se extiende por analogía. Prehistorik entra en
esa misma categoría (ver Entradas técnicas), así que no hay motivo para
esperar una tecla distinta, pero es una inferencia, no una medición directa
sobre este juego puntual.

## Multijugador

1 jugador (según `metadata.pegasus.txt`: `players: 1`).

## Periféricos

Ninguno — mouse no usado, palanca deshabilitada a propósito.

## Desconocidos

- Mapeo exacto de teclas del juego (salto, disparo, pausa).
- Si `Ctrl+F9` es literalmente la misma tecla en este juego o si el juego
  intercepta alguna combinación antes de llegar a DOSBox (poco probable en
  un DOS real, pero no medido).

## Conflictos

Ninguno detectado.

## Trabajo manual

Ninguno de contenido nuevo en este piloto. Existen `dosbox.conf.backup-*` y
`.bak-*` de sesiones anteriores en la carpeta del juego — historial de ajuste
previo a esta feature, no revisado en detalle para este expediente.
