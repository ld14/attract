---
id: 0028
title: "`attract import` revierte todo lo escrito si falla a mitad de camino"
status: proposed
date: 2026-08-22
supersedes: null
superseded-by: null
tags: [backend]
---

# 0028 — `attract import` revierte todo lo escrito si falla a mitad de camino

## Contexto

[`ADR-0027`](0027-contrato-paquete-import-coindoor.md) definió el contrato del
paquete COINDOOR y declaró la filosofía: *"fallar explícito, nunca escritura
parcial"*. La implementación resolvió eso con **orden de escritura**: valida
todo en un staging temporal y recién después escribe assets → ROM → `data.json`
→ bloque `game:`, "minimiza daño si el proceso se corta a la mitad".

Ordenar no es lo mismo que revertir. `aplicar()` tiene errores que solo pueden
aparecer **en el último paso**, cuando ya se escribieron los assets, el ROM y el
`data.json`:

- `mergear_campo_simple()` levanta `InstalarError` si el bloque `game:` existente
  no tiene línea `file:` — se descubre al mergear, no antes, porque hasta ese
  momento no se había leído `metadata.pegasus.txt`.
- Cualquier `OSError` a media copia (disco lleno, permisos, unidad externa
  desmontada — el caso real del gabinete).
- `Ctrl-C` del autor mirando la salida.

El resultado observado es un juego a medias: `media/<set>/` con assets, un ROM
copiado en la raíz del sistema, y **ningún bloque `game:`**. Pegasus no lo
muestra, `doctor` no se queja (los archivos son válidos), y el autor no tiene
forma de saber qué hay que borrar antes de reintentar. La sesión que originó
este ADR terminó con dos SF2 duplicados y una entrada huérfana en
`game_dirs.txt` de un directorio de pruebas ya borrado.

La restricción de fondo: **la ingesta es incremental y a mano**, un paquete por
vez, disparada por el autor. No hay reintentos automáticos ni un proceso que
limpie después. Lo que queda sucio, queda sucio hasta que alguien lo nota.

## Decisión

`attract.instalar.aplicar()` es **transaccional**: registra cada path antes de
tocarlo — lo que no existía queda marcado para borrar, lo que existía se
respalda en un temporal — y ante cualquier excepción, incluido `KeyboardInterrupt`,
deshace en orden inverso y re-lanza. O el juego queda instalado entero, o la
librería queda como estaba.

Cubre los seis puntos de escritura: la colección creada (`<sistema>/` +
`metadata.pegasus.txt`), la línea en `game_dirs.txt` de Pegasus,
`media/<set>/`, cada asset copiado, el ROM (copiado o descomprimido),
`data.json` y el `metadata.pegasus.txt` final.

Vive en `instalar.py`, **no** en `install-coindoor.sh`: el script es un wrapper
de conveniencia y quien escribe en la librería es `aplicar()`. Ponerlo ahí lo
deja cubierto también para `attract import`, para el servidor MCP
([`ADR-0012`](0012-mcp-dependencia-opcional-acotada.md)) y para los tests.

## Alternativas consideradas

### A. Dejarlo como estaba: solo ordenar las escrituras

- A favor: cero código nuevo. Es lo que ADR-0027 ya había decidido.
- En contra: no cubre el fallo del último paso, que es exactamente donde más
  se escribió.
- **Descartada porque:** el fallo se reprodujo. Con una colección que tiene un
  bloque `game:` sin línea `file:`, `install-coindoor.sh` con el paquete real de
  SF2 dejaba 9 escrituras hechas (`media/street-fighter-ii-the-world-warrior/`
  con 7 archivos, el ROM y el `data.json`) y salía con error sin bloque `game:`.
  El orden no lo evita: el merge del bloque es forzosamente el último paso
  porque necesita saber qué assets se copiaron.

### B. Limpieza en el script `install-coindoor.sh` después de un exit ≠ 0

- A favor: el pedido original apuntaba al script; un `trap` de bash es corto.
- En contra: el script no sabe qué escribió Python. Tendría que reconstruirlo
  desde `game.json` (`set`, `system`, `file`), y no puede distinguir un asset
  recién copiado de uno que ya estaba de una instalación anterior — borraría
  datos buenos al reintentar sobre un juego existente.
- **Descartada porque:** duplicaría la lógica de rutas de `aplicar()` en bash y
  dejaría sin cubrir a `attract import` y al servidor MCP, que no pasan por el
  script. Es el mismo criterio de `doctor` en `CLAUDE.md`: el chequeo va donde
  está la lógica, no en un script aparte.

### C. Staging completo + swap atómico de `<sistema>/` con `rename()`

- A favor: atomicidad real del sistema de archivos, sin código de undo.
- En contra: obliga a copiar el directorio del sistema **entero** antes de cada
  import — con la librería real eso son todos los juegos ya cargados, no solo el
  que se instala. Y `rename()` solo es atómico dentro del mismo filesystem: el
  gabinete monta la librería en un disco externo.
- **Descartada porque:** el coste crece con el tamaño de la librería, que es lo
  que el proyecto espera que crezca (ingesta incremental, un juego por vez).
  Instalar un paquete de 1,7 MB copiando 40 GB de librería para poder revertir
  no es una operación que el autor vaya a esperar.

### D. Una librería de PyPI (`atomicwrites`, `transaction`)

- A favor: código probado, menos que mantener.
- En contra: dependencia nueva.
- **Descartada porque:** `spec/constitution/tech-stack.md` §Límites duros lo
  prohíbe explícitamente y ya dice que una tercera excepción obliga a reescribir
  el límite en vez de parcharlo. Además ninguna de las dos cubre el caso real:
  acá no se trata de escribir un archivo atómicamente sino de deshacer un
  conjunto mixto de archivos y directorios. `shutil` + una lista alcanza.

## Consecuencias

**Positivas**

- Un import fallido no deja nada que limpiar a mano. Reintentar es seguro.
- Cubre también reinstalar encima de un juego ya cargado: si falla, vuelven los
  assets y el `data.json` viejos, incluido su `mags[]`.
- `Ctrl-C` es seguro. Se captura `BaseException`, no `Exception`.
- El rollback avisa por stderr (`rollback: N cambios revertidos`) antes del
  mensaje de error, así que el fallo no es silencioso.

**Coste asumido**

- Respaldar un directorio preexistente lo copia **entero** (`media/<set>/`, o el
  ROM ya descomprimido). Con los paquetes reales son ~1,7 MB; marcado con un
  comentario `ponytail:` en el código para ir por archivo si algún día pesa.
- `kill -9` y un corte de luz siguen sin rollback: no hay proceso que lo corra.
  Es el límite inherente de un undo en espacio de usuario, y se acepta.
- ~70 líneas más en `instalar.py` (`_Deshacer`, `_crear_dir`, `_borrar`) y una
  llamada `undo.antes_de_escribir(...)` antes de cada escritura — que hay que
  recordar agregar si se suma un punto de escritura nuevo.

**Qué habría que revisar si esto se replantea**

- Si aparece un punto de escritura sin su `antes_de_escribir()` (síntoma: un
  import fallido deja algo atrás otra vez), el registro manual ya no alcanza y
  hay que ir al swap atómico de la alternativa C, acotado a `media/<set>/` en vez
  del sistema entero.
- Si el respaldo empieza a tardar de forma perceptible al reinstalar, es que
  `media/<set>/` creció más de lo previsto (video largo, manual rasterizado) y
  toca el respaldo por archivo.

## Referencias

- [`ADR-0027`](0027-contrato-paquete-import-coindoor.md) — el contrato y la
  filosofía "nunca escritura parcial" que este ADR termina de implementar.
- `src/attract/instalar.py` — `_Deshacer`, `aplicar()` / `_aplicar()`.
- `tests/test_instalar.py` §18 — `test_rollback_borra_lo_que_creo` (instalación
  nueva) y `test_rollback_restaura_lo_que_piso` (reinstalación encima).
- `spec/constitution/tech-stack.md` §Límites duros — la regla que descarta D.
- `spec/features/016-import-coindoor/`
