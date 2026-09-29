# 027 · Cómo se juega — Plan

_Cómo se implementa lo descrito en `spec.md`. Respeta `constitution/`._

## Enfoque

Tres piezas con dueños distintos ([ADR-0036](../../decisions/0036-guia-tres-capas.md)),
las tres verificables con `pytest` sin abrir Pegasus:

1. **Validación** del bloque editorial (`doctor.py`, extiende
   `chk_data_contrato`).
2. **Un archivo versionado** (`gabinete.json`) que describe el panel físico
   — sin él, ni la ayuda general ni el diagrama tienen de dónde salir,
   incluso si nadie corrió nunca el comando de correspondencia.
3. **Un comando nuevo** (`attract controles`) que combina el perfil con la
   configuración real de MAME/DOSBox de esta máquina y escribe un artefacto
   por colección. No escribe nada de configuración, solo lee.

El theme (028) no interpreta ninguna configuración de emulador — lee estas
tres piezas ya resueltas. Es la misma frontera que
[ADR-0036](../../decisions/0036-guia-tres-capas.md) fija en su Alternativa C
descartada.

## Implementación

1. `src/attract/doctor.py` — `chk_data_contrato` gana la validación de
   `guia` según la tabla de
   [ADR-0037](../../decisions/0037-forma-bloque-guia-data-json.md). Nueva
   función `chk_correspondencia_vencida(biblioteca)`, llamada por
   `revisar()` **fuera** de `CHEQUEOS_UNIVERSALES` (es estado local de la
   máquina, no compatibilidad cruzada) — se saltea si no encuentra
   `_controles.json` o si las fuentes (MAME/DOSBox reales) no están en esta
   máquina.
2. `themes/attract/core/gabinete.json` — perfil físico del panel final,
   ver forma exacta en §Decisiones. Lo instala `make theme` en las dos
   máquinas (vive dentro del theme, no en `library/`).
3. `src/attract/controles.py` — nuevo módulo, mismo patrón que
   `magazines.py` (dry-run por defecto, `--apply` escribe). Funciones:
   - `mame_path_de(metadata)` / `mame_ini_de(...)` — salen del `launch:` real
     de la colección arcade, nunca de una ruta fija (`library/_mame32` es
     de esta máquina, en el Mac vive en otro lado).
   - `listxml(mame_exe, romset)` — invoca `-listxml`, parsea con
     `xml.etree.ElementTree` (mismo patrón que `ingest.py`), sin red.
   - `leer_cfg(cfg_path)` — parsea `<port>/<newseq>` de un `.cfg` de MAME
     (`default.cfg`, `ctrlr/<activo>.cfg` si `mame.ini` declara uno,
     `cfg/<sistema>.cfg` como excepción por juego).
   - `resolver_dosbox(carpeta_juego)` — lee las tres capas: config primaria
     (`%LOCALAPPDATA%\DOSBox\dosbox-staging.conf` en Windows, o la que
     declare el SO), `dosbox.conf` del juego, y `mapperfile` si el juego trae
     uno propio.
   - `calcular_huella(entradas_normalizadas, mame_version, revision_perfil)`
     — hash estable sobre lo que realmente afecta la entrada, no sobre
     archivos crudos (ver criterio de aceptación de `spec.md`).
   - `generar(coleccion, perfil, metadata) -> dict` — arma el artefacto
     completo para una colección; marca cada control lógico como
     verificado solo si la cadena se resuelve entera Y el perfil trae esa
     posición como medida (hoy: ninguna, porque la Etapa F no corrió).
   - `escribir(coleccion, artefacto, apply: bool)` — dry-run imprime el
     resumen (cuántos controles por juego, cuántos verificados, qué
     excepciones de `.cfg` encontró); `--apply` escribe
     `library/<coleccion>/_controles.json`.
4. `src/attract/cli.py` — subcomando `controles <coleccion> [--apply]`.
5. `tests/test_controles.py` — nuevo, mismo criterio que `test_magazines.py`
   (dry-run vs. apply, idempotencia, casos límite): `.cfg` ausente,
   `mapperfile` propio, dos placas con el mismo `VID/PID` (no se puede medir
   sin hardware, así que el test cubre que el comando **no falla**, no que
   resuelva el orden).
6. `tests/test_gabinete.py` — nuevo: `gabinete.json` es JSON válido, tiene
   los campos obligatorios, los vocabularios (`perifericos`, tipos de
   control) coinciden con los de
   [ADR-0037](../../decisions/0037-forma-bloque-guia-data-json.md). No es
   parte de `doctor` porque `doctor` recibe una librería, y el perfil vive
   en el theme, no en la librería.
7. **Fixtures** (`fixtures/arcade/media/dino/data.json`,
   `fixtures/arcade/media/mok/`): `dino` gana un bloque `guia` sintético
   completo (los 7 campos de ADR-0037, con `perifericos: []` — no necesita
   ninguno); `mok` queda **sin** `guia`, es su caso (mismo patrón que
   `manual`/`gallery` en ADR-0015/0030). Un artefacto
   `fixtures/arcade/_controles.json` escrito a mano, con un control
   `verificado: true` para poder probar ese camino sin depender de que
   `attract controles` corra contra un MAME real dentro del test.

## Decisiones

- **Perfil dentro del theme, artefacto por colección en `library/`** —
  decisión del autor, 2026-09-28 (Etapa C, pregunta 2 de
  `docs/como-se-juega.md` §4.C). El perfil viaja con `make theme` sin que el
  theme necesite conocer el repo; el artefacto es derivado, una colección
  tiene un solo emulador, y `Paths.dirColeccionDe` ya sabe llegar ahí.
  `scripts/reset-pegasus.sh` lo borra junto con la colección — es lo
  correcto porque es un artefacto de build, mismo criterio que
  [ADR-0002](../../decisions/0002-metadata-fuente-o-artefacto.md) para
  `metadata.pegasus.txt`.
- **Forma del perfil (`gabinete.json`)**:

  ```json
  {
    "revision": 1,
    "jugadores": [
      { "numero": 1, "instalado": true,
        "botones": ["superior-1","superior-2","superior-3","superior-4",
                     "inferior-1","inferior-2","inferior-3","inferior-4"],
        "start": { "instalado": false }, "coin": { "instalado": false } },
      { "numero": 2, "instalado": false, "botones": ["..."],
        "start": { "instalado": false }, "coin": { "instalado": false } }
    ],
    "flippers": { "cantidad": 2, "instalado": false },
    "perifericos": {
      "keyboard": { "instalado": true }, "mouse": { "instalado": true },
      "trackball": { "instalado": false }, "dial": { "instalado": false },
      "paddle": { "instalado": false }, "lightgun": { "instalado": false }
    },
    "salida": {
      "mame": { "tecla": "Esc", "fuente": "mame.ini: confirm_quit=0" },
      "dosbox": {
        "porDefecto": { "tecla": "Ctrl+F9",
          "fuente": "gabinete real, A2, 2026-09-27", "confianza": "comprobado" },
        "excepciones": {
          "fifa-international-soccer": { "motivo": "mapperfile propio (mapper-ECE.map), sin confirmar" },
          "monkey-island": { "motivo": "mapperfile propio (mapper-SVN.map), config de pack, sin confirmar" }
        }
      }
    }
  }
  ```

  El vocabulario de `perifericos` es el mismo que
  [ADR-0037](../../decisions/0037-forma-bloque-guia-data-json.md) usa en
  `guia.perifericos[]` — el cruce es una comparación de strings, sin
  traducción (confirmado a mano en el piloto, caso Shuffleshot).
  `jugadores[].botones` usa los nombres de posición de
  `docs/como-se-juega.md` §3.3 (fila + columna desde el stick), no el
  número que reporta la placa.
- **La huella es de las entradas normalizadas, no de los archivos** — ver
  criterio de aceptación de `spec.md`; un `.cfg` reescrito por MAME al
  cerrar el juego (créditos, mezclador) no puede vencer la huella o
  `doctor` avisaría después de cada partida.
- **El aviso de correspondencia vencida no va en `CHEQUEOS_UNIVERSALES`** —
  es estado de esta máquina, no compatibilidad Mac/Windows. Se saltea si
  las fuentes no existen (Mac sin este MAME instalado, por ejemplo).
- **Sin dependencias nuevas** — `xml.etree.ElementTree` (stdlib, ya lo usa
  `ingest.py`), `hashlib` (stdlib) para la huella.

## Riesgos

- **Dos placas con el mismo `VID/PID`** (§3.1/§6 de `docs/como-se-juega.md`):
  el comando no puede resolver el orden sin las dos conectadas. Se mitiga
  dejando esos controles sin verificar (comportamiento correcto, no un bug)
  y documentando `<mapdevice>` en `-ctrlr` como la vía cuando llegue la
  Etapa F (confirmado contra `docs/MAME.pdf` §7.7-7.8 durante la Etapa A).
- **Config de DOSBox en capas** (primaria + del juego + `mapperfile`): si el
  comando solo lee `dosbox.conf` del juego, puede anunciar mal la tecla de
  salida. Se mitiga leyendo las tres capas siempre, marcando como excepción
  cualquier juego con `mapperfile` propio (hoy: FIFA, Monkey Island).
- **Remapeos provisorios tomados como excepciones legítimas** (`simpsons.cfg`,
  `finalb.cfg`, del panel de hoy con 1 jugador): si siguen ahí al instalar
  el panel final, el comando los reporta como si fueran remapeos
  intencionales. Mitigación: el dry-run los marca explícitamente, y el
  autor los revisa antes de la Etapa F (ya anotado en
  `docs/como-se-juega.md` §6).
