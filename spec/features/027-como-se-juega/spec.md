# 027 · Cómo se juega — contrato de datos

**Estado:** aprobada — piloto cerrado (`piloto/conclusion.md`), spec partida en
027 (esta, datos/backend) y [028](../028-theme-como-se-juega/spec.md) (theme),
decisión del autor del 2026-09-28.

## Qué hace

Todo lo verificable con `pytest`, sin abrir Pegasus, para que el theme (028)
tenga de dónde leer:

- El contrato del bloque editorial `guia` dentro de `data.json`
  ([ADR-0037](../../decisions/0037-forma-bloque-guia-data-json.md)) y su
  validación en `attract doctor`.
- El **perfil físico del gabinete**: un archivo versionado dentro del theme
  (`themes/attract/core/gabinete.json`) que describe el panel final, sus
  periféricos y la tecla de salida por defecto de cada emulador.
- El **comando de correspondencia**: lee el perfil + la configuración real
  de MAME/DOSBox en esta máquina y escribe un artefacto local,
  `library/<coleccion>/_controles.json`, con qué controles lógicos están
  verificados contra una posición física y cuáles no.
- El chequeo en `attract doctor` que avisa cuando la correspondencia está
  vencida.

De dónde sale cada dato lo fija
[ADR-0036](../../decisions/0036-guia-tres-capas.md): contenido editorial en
`data.json` (lo produce COINDOOR), perfil del gabinete en el repo,
correspondencia generada localmente. El **dibujo** del diagrama, la tarjeta y
el overlay son de [028](../028-theme-como-se-juega/spec.md) — esta feature no
toca `themes/attract/screens/` ni `overlays/`.

## Por qué

Sin un contrato firme de dónde vive cada dato y cómo se valida, el theme (028)
no tiene contra qué escribirse, y un bloque de guía mal formado pasaría en
verde hasta que alguien lo viera roto en el gabinete — el modo de falla que
`attract doctor` existe para evitar.

## Criterios de aceptación

- [ ] `attract doctor` rechaza un bloque `guia` mal formado
      ([ADR-0037](../../decisions/0037-forma-bloque-guia-data-json.md) fija
      qué es ERROR y qué es AVISO) y avisa por claves de primer nivel
      desconocidas dentro de `guia`.
- [ ] El perfil físico (`themes/attract/core/gabinete.json`) es un archivo de
      test propio (pytest), no parte de la librería que valida `doctor`.
- [ ] El comando de correspondencia corre en dry-run por defecto, saca las
      rutas de MAME del `launch:`/`mame.ini` reales (no de una ruta fija), y
      solo mira los sistemas presentes en la metadata.
- [ ] Un control queda **verificado** en el artefacto solo si la cadena se
      resuelve entera (perfil → config real → posición física medida). Si
      falta cualquier eslabón, queda como entrada lógica sin verificar.
- [ ] La huella del artefacto se calcula sobre las entradas normalizadas
      (`<port>`/`<newseq>`, `ctrlr` efectivo, claves de `mame.ini`/DOSBox que
      afectan la entrada, versión de MAME, `revision` del perfil) — nunca
      sobre los archivos crudos. Un `.cfg` reescrito por MAME al cerrar un
      juego (créditos, mezclador) no vence la huella; remapear sí.
- [ ] `attract doctor` avisa si la correspondencia está vencida contra la
      librería que se le pasó, salteando el chequeo si las fuentes (MAME/
      DOSBox reales) no existen en esta máquina. No va en
      `CHEQUEOS_UNIVERSALES` — es estado local, no compatibilidad cruzada.
- [ ] Un paquete COINDOOR sin bloque `guia` se importa igual
      ([ADR-0027](../../decisions/0027-contrato-paquete-import-coindoor.md)
      no cambia de política). Reimportar pisa `guia` y no toca el perfil ni
      el artefacto de correspondencia (son locales, no viajan en el paquete).
- [ ] Sin dependencias nuevas.

## Fuera de alcance

- Todo el dibujo en pantalla: tarjeta, overlay, diagrama, foco — eso es
  [028-theme-como-se-juega](../028-theme-como-se-juega/spec.md).
- Escribir en la configuración de MAME o DOSBox: el comando solo lee.
- El mapeo global de MAME (`default.cfg`/`ctrlr/`): lo configura el autor al
  instalar el panel, fuera del repo.
- Editar la guía dentro de ATTRACT: se corrige en COINDOOR
  ([016](../016-import-coindoor/spec.md)).
- Habilitar el joystick en DOSBox.
