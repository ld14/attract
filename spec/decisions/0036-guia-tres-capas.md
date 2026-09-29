---
id: 0036
title: "Separar la guía en contenido editorial (data.json), perfil del gabinete (repo) y correspondencia física generada localmente"
status: accepted
date: "2026-09-24"
supersedes: null
superseded-by: null
tags: [data, frontend, proceso]
---

# 0036 — La guía "Cómo se juega" en tres capas, cada una con su dueño

## Contexto

La feature [027](../features/027-como-se-juega/spec.md) muestra, por juego,
qué hacer y qué apretar. "Qué apretar" encadena tres capas que no tienen el
mismo dueño:

1. **Qué hace el jugador** en el juego (*saltar*). Es propio del juego y vale
   en cualquier máquina.
2. **Qué entrada lógica del emulador** lo dispara (*P1_BUTTON2*). También
   propio del juego y de su versión.
3. **Qué control físico del panel** genera esa entrada (*fila superior,
   columna 2*). Depende del gabinete y de cómo esté configurado el emulador
   **en esa máquina**.

Lo que se encontró el 2026-09-24 muestra que la capa 3 es frágil y local:

- **`cfg/default.cfg` de MAME no reasigna nada**, y cada juego tiene un
  remapeo propio e inconsistente con los demás: en `simpsons.cfg`
  P1_BUTTON1 va a `JOYCODE_1_BUTTON5`, y en `finalb.cfg` a `BUTTON1`.
  MAME reescribe esos archivos **al cerrar cada juego**, aunque nadie haya
  remapeado: `simpsons.cfg` también guarda el contador de créditos
  (`<counters>`) y el mezclador de audio (`<mixer>`).
- **El panel está en transición.** Hoy tiene 1 jugador. El final va a tener 2,
  con dos placas idénticas (`0079:0006`) cuyo orden Windows puede
  intercambiar.
- **DOSBox tiene la palanca deshabilitada** en 17 de 19 juegos
  (`joysticktype = disabled`, lo escribe `dosbox.py`). Pero la config del
  juego no es la única: el `launch:` no pasa `--noprimaryconf`, así que debajo
  queda una config primaria (`joysticktype = auto`, con su `mapperfile`), y
  dos juegos traen su propio `mapperfile`.

Y hay restricciones que ya estaban decididas:

- [ADR-0027](0027-contrato-paquete-import-coindoor.md): reimportar un paquete
  **pisa todo el `data.json`**, salvo `mags`.
- **El autor decidió** que el contenido de la guía se corrige **solo en
  COINDOOR**, y que el perfil del panel **se versiona en el repo**.
- **COINDOOR ya trae de ArcadeDB las capas 1 y 2** para arcade
  (`buttons_colors`: `P1_BUTTON1:Red:Attack`), con procedencia por campo. No
  sabe nada del gabinete.
- **El theme no es buen lugar para lógica compleja.** `core/InputTokens.js` es
  la única pieza verificable sin abrir Pegasus, y `GameData.qml` degrada todo
  el `data.json` a "sin-datos" si no parsea.
- **`doctor` no rechaza claves de primer nivel desconocidas en `data.json`.**
  Es el modo de falla que describe [ADR-0020](0020-cheats-grupos-libres.md).

## Decisión

**Cada capa vive donde vive su dueño, y el theme solo lee.**

1. **Contenido editorial → un bloque opcional dentro de `data.json`.**
   - Incluye objetivo, acciones con su nombre original, entradas lógicas,
     primeros pasos, reglas, multijugador, periféricos, fuentes y estado de
     revisión por grupo.
   - Lo produce y lo corrige COINDOOR. Reimportar lo pisa, igual que el resto
     del archivo, y ADR-0027 no cambia.
   - **Nunca nombra un botón físico.**
   - Los nombres de los campos se fijan después del piloto
     ([`docs/como-se-juega.md`](../../docs/como-se-juega.md) §4.B), no acá.
2. **Perfil físico del gabinete → un único archivo versionado en el repo.**
   - Describe el panel final: posiciones, botones de sistema, dispositivos, y
     la tecla de salida por defecto de cada emulador.
   - Guarda también **lo medido en el gabinete**: qué número manda cada
     posición, de qué placa y en qué fecha. Es el único lugar donde eso
     sobrevive, porque el artefacto se regenera.
   - Su historia en git marca cuándo cambió el panel.
   - De acá sale la ayuda general (crédito, start, salir), que se muestra
     aunque el juego no tenga guía.
3. **Correspondencia resuelta → un artefacto local generado.**
   - Lo escribe un comando de ATTRACT (stdlib) combinando el perfil con la
     configuración real del emulador:
     - en MAME, la asignación global más la excepción de `cfg/<sistema>.cfg`
       cuando existe;
     - en DOSBox, la config primaria más la del juego y su `mapperfile`, que
       puede cambiar la tecla de salida.
   - Guarda una huella de **las entradas que leyó**, no de los archivos
     enteros. Una huella del archivo crudo se vencería con cada partida,
     porque MAME reescribe el `.cfg` al cerrar el juego.
   - Un control queda **verificado** solo si la cadena se resuelve entera y
     su posición figura como medida en el perfil.
   - No se edita a mano y no va a git.
4. **El theme lee el bloque, el perfil y el artefacto; no interpreta
   configuraciones de emuladores.**
   - Lee el perfil directamente: la ayuda general y el diagrama funcionan
     aunque el comando no se haya corrido nunca.
   - Sin correspondencia vigente y verificada para un control, muestra la
     entrada lógica y ningún botón físico.

## Alternativas consideradas

### A · Todo en `data.json`, incluido el botón físico

- A favor: un solo archivo por juego; ningún comando nuevo.
- En contra: el botón físico depende del gabinete, y quien escribe `data.json`
  (COINDOOR) no lo conoce. Reimportar pisaría la parte local, y el mismo panel
  quedaría repetido en cada juego.
- **Descartada porque:** mezcla un dato editorial, portable entre máquinas,
  con uno local que cambia al remapear. Es la frontera que la propuesta pide
  no cruzar: COINDOOR no puede afirmar dónde está un botón del gabinete.

### B · La guía en un archivo aparte dentro del paquete

- A favor: un JSON roto en la guía no apagaría trucos, galería y reseña.
  Además tendría política de reimport propia.
- En contra: es un miembro nuevo del paquete. Obliga a ampliar ADR-0027, los
  prefijos permitidos del zip en `instalar.py` y el preflight, y a sumar una
  segunda lectura en el theme.
- **Descartada porque:** el riesgo que resuelve ya está cubierto. El import
  valida el JSON antes de instalar (`instalar._preflight_data_json` →
  `doctor.chk_json_valido`), y la guía no se edita a mano en la librería.
  Tampoco hace falta una política de reimport propia: la decisión del autor es
  pisar.

### C · El theme lee los `.cfg` de MAME en vivo

- A favor: siempre al día, sin comando que correr.
- En contra: habría que reimplementar en QML la herencia de MAME
  (`default.cfg`, `ctrlr/`, por juego, `joystick_map`) y además el formato de
  DOSBox. Todo sin tests, en la capa que menos se puede verificar sin abrir
  Pegasus.
- **Descartada porque:** vuelve al theme responsable de interpretar
  configuraciones ajenas. La lógica va en Python, testeable con pytest.

### D · El perfil físico solo en `library/`

- A favor: queda junto a los datos de esa máquina, como `_dosbox.json`.
- En contra: `library/` no va a git. Se perdería la historia de los cambios del
  panel y el Mac no podría dibujar el diagrama.
- **Descartada porque:** decisión del autor del 2026-09-24. El panel es un
  hecho estable del único gabinete del proyecto, y el cambio a 2 jugadores
  tiene que quedar registrado para invalidar lo verificado antes.

### E · La correspondencia versionada en el repo

- A favor: se revisaría en un diff.
- En contra: se deriva de `library/_mame32/cfg`, que es local, no se versiona y
  cambia cada vez que alguien remapea.
- **Descartada porque:** es un artefacto de build, no una fuente. Es el mismo
  criterio de [ADR-0002](0002-metadata-fuente-o-artefacto.md) para
  `metadata.pegasus.txt`.

### F · Preguntarle a MAME en ejecución (API Lua o plugin)

- A favor: da las entradas efectivas de una máquina concreta.
- En contra: convierte una ejecución de MAME en requisito para preparar una
  guía, y no cubre DOSBox.
- **Descartada porque:** la propuesta la deja como experimento aparte, a
  evaluar solo si el piloto muestra que aporta algo que no se obtiene más
  simple.

## Consecuencias

**Positivas**

- Cada dato tiene un dueño y un lugar donde se corrige: COINDOOR, el repo o
  el comando.
- `attract import` y ADR-0027 no cambian de política. Un paquete sin guía
  sigue siendo válido.
- El theme queda en leer y dibujar. La lógica de resolución vive en Python
  con tests.
- Un juego sin guía propia igual muestra ayuda útil, porque sale del perfil.

**Coste asumido**

- **Hay que correr el comando de correspondencia** después de cambiar el panel
  o de remapear en MAME. El theme no puede detectar que quedó vencida. Lo
  marca `attract doctor`, como aviso, comparando la huella.
- **Hasta instalar el panel final y medirlo, ningún control está
  verificado.** La guía muestra entradas lógicas, que es el comportamiento
  correcto y no una falla.
- **`doctor` tiene que sumar** la validación del bloque de guía y un aviso por
  claves desconocidas en `data.json`.
- **Un error de sintaxis en `data.json` sigue apagando todo el archivo** en el
  theme. Se acepta porque el import lo frena antes de instalar.
- **La ruta exacta del perfil y del artefacto** se decide en el `plan.md` de la
  feature, después del piloto. Condición: el perfil tiene que llegar al theme
  instalado en las dos máquinas, porque el theme lo lee (§Decisión 4).

**Qué habría que revisar si esto se replantea**

- Si el piloto muestra que la guía necesita correcciones locales frecuentes
  que no pueden esperar a COINDOOR: ahí se reabre la Alternativa B.
- Si COINDOOR no puede producir el bloque con la procedencia que pide la
  propuesta.
- Si aparece un segundo gabinete: un perfil único en el repo deja de alcanzar.

## Referencias

- [ADR-0001](0001-transporte-datos-ricos.md): datos ricos en `data.json`.
- [ADR-0002](0002-metadata-fuente-o-artefacto.md): artefacto de build frente a
  fuente.
- [ADR-0020](0020-cheats-grupos-libres.md): el modo de falla de las claves que
  nadie lee.
- [ADR-0021](0021-manual-pdf-app-del-sistema.md): el manual en PDF se abre
  fuera de ATTRACT.
- [ADR-0027](0027-contrato-paquete-import-coindoor.md): el contrato del paquete
  y el reimport que pisa.
- [ADR-0032](0032-perfiles-dosbox-import.md): precedente de artefacto local con
  estado y fuentes (`_dosbox.json`).
- [Spec 027](../features/027-como-se-juega/spec.md) y
  [`docs/como-se-juega.md`](../../docs/como-se-juega.md) §2 y §3: decisiones e
  inventario del 2026-09-24.
