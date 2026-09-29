# Oh No! More Lemmings — E · DOS de mouse

## Identidad

| Campo | Valor |
|---|---|
| Título | Oh No! More Lemmings |
| Plataforma | MS-DOS (DOSBox Staging) |
| Identificador exacto | `x-set: oh-no-more-lemmings`, carpeta `library/msdos/oh-no-more-lemmings/`, arranque vía `Lemmings.bat` (ver `autoexec`) |
| Variante | La copia instalada — no verificada contra una fuente externa |
| Emulador y versión | DOSBox Staging |
| Desarrollador/editor | DMA Design / Psygnosis, 1995 |

## Fuentes

- `library/msdos/oh-no-more-lemmings/dosbox.conf` (generado por ATTRACT).
- `library/msdos/metadata.pegasus.txt` (summary, genre, launch).
- Conocimiento general del juego original (mecánica de asignar habilidades
  con el mouse) — **no verificado con una fuente citable con URL** en este
  piloto; sale de lo que documenta el propio `summary`, que es consistente
  con lo conocido públicamente del juego.

## Objetivo

Guiar a un grupo de lemmings a través de niveles con obstáculos y trampas,
asignando a cada uno habilidades especiales (bloqueador, explosivo,
constructor de puentes, etc.) para salvar a la mayor cantidad posible antes
de que caigan en un peligro o se pierdan. Más de 70 niveles.

## Controles originales (capa 1)

Point-and-click con mouse: clic para seleccionar una habilidad de la barra
inferior, clic sobre un lemming para asignársela. Es la razón por la que
esta categoría se llama "E · DOS de mouse" — no hay control de movimiento
directo del jugador, todo es indirecto sobre los lemmings.

## Entradas técnicas (capa 2)

`dosbox.conf`: `[joystick] joysticktype = disabled`, sin `mapperfile` propio
— igual patrón que Prehistorik (config generada, sin capas extra).

**Ojo con Monkey Island, que NO es este caso:** el plan (`docs/como-se-juega.md`
§4.A) ya advertía que Monkey Island no representa bien esta categoría porque
su config es "de pack" (arranca un menú que junta dos juegos) y trae
`mapperfile` propio (`joysticktype = auto`). Por eso se eligió este juego en
su lugar para la muestra — decisión ya tomada antes de este piloto, no algo
que este expediente decida.

## Mapeo local (capa 3)

No aplica a un botón del panel: el control es 100% mouse, y el mouse es fijo
en el gabinete (§3.2). No hay remapeo de MAME/DOSBox que lo afecte porque no
usa `joystick` ni teclado para jugar.

## Inicio

Lanzamiento directo desde Pegasus, sin pasos manuales — el `autoexec` corre
`Lemmings.bat` solo.

## Salida

**Ctrl+F9 por analogía** (misma categoría de config que Prehistorik: sin
`mapperfile`, `joysticktype = disabled`) — **no probado directamente en este
juego**. Mismo nivel de confianza que en Prehistorik: alto por similitud de
config, pero no una medición propia.

## Multijugador

1 jugador (`players: 1`).

## Periféricos

Mouse — ya presente y fijo en el gabinete, no es un requisito adicional.
Palanca deshabilitada (no la necesita el juego).

## Desconocidos

- Si el juego usa alguna tecla de teclado además del mouse (típicamente
  pausa, avance rápido o "nuke" con un botón en pantalla, no con teclado —
  no verificado).

## Conflictos

Ninguno detectado.

## Trabajo manual

Ninguno de contenido nuevo en este piloto. Existe `dosbox.conf.bak-*` de una
sesión anterior — no revisado en detalle.
