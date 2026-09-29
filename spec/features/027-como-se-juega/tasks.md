# 027 · Cómo se juega — Tareas

_Checklist accionable derivada del `plan.md`. Tareas pequeñas y concretas;
marca `[x]` al completarlas._

## 0 · Documentos

- [x] `spec.md` partida en 027 (datos) y 028 (theme), decisión del autor
      2026-09-28.
- [x] `plan.md` con la forma exacta del perfil y del artefacto.
- [x] ADR-0037 (forma del bloque `guia`), ADR-0038 (restaurar contexto),
      ADR-0036 a `accepted`.
- [x] Piloto de datos (`piloto/`): 6 expedientes, matriz, conclusión.
- [x] Roadmap: 027 y 028 anotadas (ver `spec/constitution/roadmap.md`).

## 1 · Contrato y validación (`doctor.py`)

- [x] `chk_data_contrato` valida `guia` según la tabla de ADR-0037 (ERROR vs
      AVISO) — `_chk_guia_bloque`. 24 tests nuevos en `test_doctor.py`
      (incluido uno que lee el código fuente para confirmar que `guia` nunca
      nombra una posición física ni una tecla).
- [x] `chk_correspondencia_vencida(raiz, rep)` — nueva función, llamada por
      `revisar()` fuera de `CHEQUEOS_UNIVERSALES`. Verificado: sin
      `_controles.json` no avisa nada; con huella distinta avisa (AVISO, no
      ERROR); sin `themes/attract/` al lado de `raiz` se saltea en silencio.
- [x] Fixture `fixtures/arcade/media/dino/data.json` gana `guia` completo (7
      campos, multijugador cooperativo a tono con el cheat "Modo 3
      jugadores" que ya tenía). `attract doctor fixtures` sigue en 0 errores
      (2 avisos preexistentes, sin cambios).
- [x] Confirmado: `fixtures/arcade/media/mok/` sigue sin `data.json` (su
      caso, sin tocar).

## 2 · Perfil físico (`gabinete.json`)

- [x] `themes/attract/core/gabinete.json` — estado real de hoy: jugador 1
      instalado con 8 posiciones (`medido: false` cada una), jugador 2 no
      instalado, Start/Coin/flippers no instalados, `salida.dosbox` con las
      excepciones de FIFA y Monkey Island.
- [x] `tests/test_gabinete.py` — 8 tests. `pytest` no depende de ninguna
      librería, solo del archivo del theme.

## 3 · Comando de correspondencia (`controles.py`)

Nombres de función finales (distintos de los propuestos en `plan.md`, ajuste
mecánico al escribir el código):

- [x] `launch_de_coleccion` + `emulador_de_launch` + `tipo_emulador` — leen
      la línea `launch:` real de la colección y deciden `mame`/`dosbox`/
      `desconocido` por el nombre del ejecutable.
- [x] `mame_listxml` + `controles_declarados` — `xml.etree.ElementTree`
      sobre XML sintético para los tests, y contra el MAME 0.288 real de
      esta máquina (`library/_mame32/mame.exe`, resuelto por ruta desde
      `launch:`, no por `PATH` — a diferencia de `ingest.py`, que sí depende
      del `PATH` y por eso sus tests de integración se saltean en este
      gabinete).
- [x] `leer_cfg_ports` — contra una copia exacta de `simpsons.cfg`: devuelve
      el remapeo de `COIN1`/`P1_BUTTON1`/`P1_BUTTON2`/`START1` documentado en
      `piloto/the-simpsons.md`. Confirmado también contra el archivo real.
- [x] `resolver_dosbox` — un juego sin `mapperfile` da la tecla del perfil y
      queda verificado; uno con `mapperfile` propio (FIFA, Monkey Island)
      queda `verificado: false`, tenga o no una entrada de excepción en el
      perfil (el mapperfile es lo que decide, la excepción solo aporta el
      motivo). Hecho robusto contra un caso real encontrado al probarlo
      (`monkey-island/dosbox.conf` está en Windows-1252, no UTF-8 — ver
      hallazgo al final de este documento).
- [x] `calcular_huella` — determinista; verificado con datos reales que
      reescribir `<counters>`/`<mixer>` (lo que hace MAME al cerrar el
      juego) no la cambia, y que un `<input>` nuevo sí.
- [x] `generar_coleccion` / `escribir_artefacto` — dry-run por defecto,
      `--apply` escribe. Verificado con la librería real: `library/msdos`
      (19 juegos, 17 verificados) y `library/arcade` (ver hallazgo abajo).
- [x] Subcomando `controles` en `cli.py`, con `--help`.

## Tests

- [x] Caso feliz: `test_generar_coleccion_dosbox_no_necesita_binario` y el
      puñado `@sin_mame_real` contra `library/_mame32/mame.exe` real.
- [x] Caso límite: `test_generar_coleccion_sin_launch_es_controles_error`,
      `test_correspondencia_sin_artefacto_no_avisa_nada`.
- [x] Caso de fallo: `test_leer_perfil_ausente_es_controles_error`,
      `test_leer_perfil_corrupto_es_controles_error`.
- [x] Invariante: todo control declarado sale con `verificado: false` y un
      `motivo` explícito mientras el perfil no tenga ninguna posición
      medida — cubierto por `test_generar_coleccion_dosbox_no_necesita_binario`
      y equivalentes; no hace falta un test aparte porque **hoy no hay
      ningún camino en el código que pueda poner `verificado: true` para
      MAME** (el perfil de esta máquina no tiene nada medido).

**41 tests en `test_controles.py` + 8 en `test_gabinete.py` + 24 nuevos en
`test_doctor.py`. Suite completa: 338 passed, 10 skipped.**

## Hallazgos reales al probar contra `library/` (2026-09-29)

No estaban previstos en el plan; salieron de correr el comando contra datos
reales, que es exactamente el punto de no quedarse solo con fixtures.

1. **`x-set:` de 3 de los 5 arcades importados con COINDOOR no era el set
   real de MAME.** `street-fighter-alpha-2` (debía ser `sfa2`),
   `mortal-kombat-2` (`mk2`) y `the-simpsons` (`simpsons`) tenían el slug del
   título en vez del romset — `pacman` y `shufshot` funcionaban de casualidad
   porque su slug coincide con su romset. Causa confirmada en el código de
   COINDOOR: `backend/bundle/manifest.py:26` exporta `"set":
   str(game.get("id", ""))`, y ese `id` es `safe_id(identity.title)`
   (`backend/store/juegos.py`) — nunca el romset real, ni siquiera cuando
   `identitySource == "mame"`. `ADR-0026` (de este repo) acepta este riesgo a
   propósito ("no hay verificación de que el set/file declarado corresponda
   a un romset real"), pero acá se vio el costo concreto: sin corregirlo,
   `attract controles` no podía leer `-listxml` de esos 3 juegos. Pedido
   formal a COINDOOR en `pedido-coindoor.md`.

   **✅ Parche local aplicado 2026-09-29** (a pedido del autor, sabiendo que
   reimportar antes de que COINDOOR lo arregle lo pisa): se renombraron las
   carpetas `media/street-fighter-alpha-2/` → `media/sfa2/`,
   `media/mortal-kombat-2/` → `media/mk2/`, `media/the-simpsons/` →
   `media/simpsons/` (`Paths.qml::baseDe` arma `media/<x-set>/`, así que
   `x-set` y la carpeta tienen que cambiar juntos) y se actualizaron
   `x-set:` + las 6 líneas `assets.*` de cada uno en
   `library/arcade/metadata.pegasus.txt`. Verificado: `attract controles
   arcade library` ya lee los 5 juegos, `assets.*`/`data.json` siguen
   existiendo en las rutas nuevas, `attract doctor library` no reporta nada
   nuevo sobre `arcade/`.
2. **`.conf` no estaba en `EXT_TEXTO` de `doctor.py`.** Por eso
   `library/msdos/monkey-island/dosbox.conf` (Windows-1252, no UTF-8, CRLF)
   nunca aparecía en ningún `attract doctor library` — `chk_encoding`/
   `chk_crlf` no lo miraban. `resolver_dosbox` ya es robusto a esto
   (`errors="replace"`, con test) independientemente de este punto.

   **✅ Agregado 2026-09-29** (a pedido del autor). Efecto medido contra la
   librería real: **7 hallazgos nuevos**, los tres `dosbox.conf` de "config
   de pack" que el plan ya señalaba como excepción (`fifa-international-soccer`,
   `monkey-island` — incluida una copia en `monkey-island/dos/`, y
   `monkey-island-2-lechuck-s-revenge/.../DOSBox CD/`): CRLF en los tres,
   encoding Windows-1252 en los dos de Monkey Island. **Matiz para el
   autor:** a diferencia de `metadata.pegasus.txt`/`data.json`, un
   `dosbox.conf` no lo lee Pegasus — lo lee DOSBox, que no es sensible a
   CRLF ni al encoding de los comentarios. El aviso de `chk_crlf` dice "Pegasus
   espera LF", que para este archivo puntual no es el motivo real; se
   mantiene por uniformidad del chequeo, no porque vaya a romper algo hoy.

## Cierre

- [x] Validado contra los criterios de aceptación de `spec.md` verificables
      sin Pegasus (todos los de esta feature lo son).
- [x] `spec/constitution/tech-stack.md`: filas de `controles.py`,
      `test_controles.py`, `test_gabinete.py`, `gabinete.json`.
- [ ] Mover 027 a "Hecho" en `spec/constitution/roadmap.md` — pendiente
      hasta que 028 (theme) también avance, se cierran juntas en la
      práctica.
- [x] `docs/CONVENCION.md`: no se tocó. `guia` anotado para el autor si algún
      día se completa ese documento.
