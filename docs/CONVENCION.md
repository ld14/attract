# CONVENCIÓN ATTRACT

> 🔴 **PLANTILLA. La escribís vos en el LAB 0.3 (Bloque 5 de M0).**
>
> Este es **el** documento del proyecto. Un tercero tiene que poder implementar
> la ingesta leyendo solo esto.
>
> El contrato es un documento, no código. Si vive solo en tu parser, no es contrato.

---

## 1 · ESTRUCTURA

### 1.1 ¿Dónde vive cada colección?

Una colección por sistema. Cada sistema tiene su propia carpeta de nivel
superior en `library/` (real) / `fixtures/` (test), con su propio
`metadata.pegasus.txt` y su propio `collection: <Nombre>`.

```
library/arcade/metadata.pegasus.txt   collection: Arcade
library/nes/metadata.pegasus.txt      collection: NES
```

Un juego que existe en varios sistemas (Striker: Amiga y DOS) tiene una
entrada por sistema del que hay ROM jugable — ver §2.1, fila `system`.

### 1.2 ¿Cómo se nombra la carpeta de un juego?
<Una **regla**, no un ejemplo.>

> Restricciones que no son opinables:
> - Windows prohíbe `< > : " / \ | ? *`, los nombres CON PRN AUX NUL COM1-9 LPT1-9,
>   y terminar en espacio o punto. **Tu juego #3 tiene `:` en el título.**
> - Todo en NFC. macOS descompone y no te avisa.
> - Con **merged**, `sf2ce.zip` no es un juego: es una familia. Ver ADR-0004.
> - Identidad ≠ presentación. `dino` es la identidad; *Cadillacs and Dinosaurs* es
>   cómo se muestra.

**Regla:** la carpeta se llama igual que el identificador físico que el juego
ya trae en `library/<sistema>/` — nunca el título de presentación, nunca algo
inventado por ATTRACT. Según cómo esté guardado el juego:

1. **Un solo archivo** (ROM, disco, cassette) → el nombre de archivo, sin
   extensión. `tmnt.zip` → `tmnt`.
2. **Romset de MAME con dependencias** (ROM + CHD + BIOS, como `mok`) → el
   nombre del `set` que reporta `mame -listxml`. En la práctica coincide
   siempre con el nombre del `.zip` sin extensión, porque MAME **exige** esa
   coincidencia para poder resolver el romset — no hace falta correr
   `-listxml` para saberlo, ya viene forzado por cómo MAME arma sus carpetas.
3. **Múltiples archivos sueltos sin MAME de por medio** (ej. un juego de
   MS-DOS: `.exe`, `.cfg`, assets propios, todo en una carpeta) → el nombre
   del **directorio** que los contiene.

En los tres casos, después se le aplican las restricciones no negociables de
arriba (NFC, sin caracteres prohibidos, sin terminar en espacio/punto) —
`attract doctor` ya las valida.

**Pendiente menor:** ¿el nombre se normaliza siempre a minúsculas? Tus
fixtures de Arcade ya vienen así (`dino`, `mok`, `sf2ce`) porque MAME nombra
sus sets en minúscula, pero `Striker.adf` (Amiga) tiene mayúscula inicial.
Si querés forzar minúsculas siempre, decilo — si no, la regla es "tal cual
viene el archivo/directorio".

### 1.3 ¿Dónde van los assets?
<Y los scans de revista, que son N páginas por número.>

> Pegasus auto-descubre en `media/<archivo-sin-extensión>/<asset>.<ext>`.
> Con merged eso **agrupa por familia**: una carátula para todos los clones.
> ¿Lo aceptás o necesitás `assets.*` explícitos?

Dos estructuras separadas, y a **dos alturas distintas** del árbol:

```
<raíz-librería>/
├─ _magazines/<revista>-<número>/    ← las revistas, UNA sola vez
│  ├─ magazine.json                   ← contrato completo (ver ADR-0024)
│  ├─ cover.jpg                       ← la tapa, en la raíz de la revista
│  └─ pages/
│     └─ p001.jpg … pNNN.jpg          ← todas las páginas del escaneo
│
└─ <sistema>/                         ← arcade/, nes/, pc/ …
   ├─ metadata.pegasus.txt
   └─ media/
      └─ <juego>/                     ← media/<archivo-sin-extensión>/
         ├─ boxFront.jpg, video.mp4…  ← PLANO, auto-descubierto por Pegasus
         └─ data.json                 ← datos ricos propios + mags:[{ref}]
```

**`_magazines/` está fuera del árbol de cualquier sistema** (ADR-0024). Una
revista habla de juegos de varios sistemas a la vez — `micromania-34` cubre
Golden Axe (arcade), Dr. Mario (NES) y Monkey Island (PC) — así que meterla
adentro de uno obligaría a copiarla en los tres. El theme la resuelve como
`<dir-colección>/../_magazines/<ref>/`, un nivel arriba de lo que Pegasus
tiene en `game_dirs.txt`.

**Las páginas van en `pages/`, la tapa no.** `magazine.json → pages[]` trae
el nombre pelado (`"p002.jpg"`) y el prefijo lo pone quien lee. `cover` vive
en la raíz de la revista. `attract doctor` verifica que todo resuelva
(`chk_magazine_assets`): sin ese chequeo, una carpeta mal armada solo se ve
como una página en blanco en el visor.

**`startPage` es el número de página impresa, no un índice.** `startPage: 46`
significa el archivo `p046.jpg`, y se resuelve buscándolo dentro de `pages[]`.
No es lo mismo que "el elemento 46 del array": una revista real arranca en
`p002.jpg` porque la página 1 es la tapa, así que contar posiciones corre
todo un lugar.

`media/<juego>/` es **plano**, sin subcarpetas por tipo — se acepta el
auto-descubrimiento de Pegasus tal cual (`assets.boxFront`, `assets.video`,
y a futuro `assets.<sonido>` cuando exista esa categoría). No se declaran
`assets.*` explícitos salvo excepción puntual.

Con **merged**, esto agrupa por familia: todos los clones de `sf2ce`
compartirían la misma `media/sf2ce/` y la misma carátula. Se acepta — es
consistente con que la identidad real la da `mame -listxml`, no el
filesystem (ver ADR-0004).

`_magazines/` lleva guión bajo adelante a propósito: lo separa
alfabéticamente de las carpetas de juego y evita que choque si algún día un
`set` de MAME se llamara igual que una revista.

### 1.4 ¿Dónde van los datos ricos?
<Según ADR-0001.>

Fuera de `metadata.pegasus.txt`. Cada juego tiene un `data.json` en su propia
`media/<juego>/` con lo que le pertenece solo a él (`review`, `cheats`) más
una referencia a la revista por `ref` (`mags: [{ref: "<revista>-<número>"}]`)
— nunca copia las páginas. El theme lee `data.json` con `XMLHttpRequest` y lo
parsea con `JSON.parse`. Ver ADR-0001 (accepted) para el detalle completo y
la evidencia del experimento del Bloque 3.

**Distinto de lo anterior:** `<sistema>/_synopsis/<set>.json` (uno por
juego, junto a `metadata.pegasus.txt`, no dentro de `media/`) **no** es un
dato rico que el theme lea en runtime — es la fuente de la que
`attract synopsis` toma el texto para escribirlo en el campo nativo
`summary:` de `metadata.pegasus.txt`. Lo produce un sistema de scraping
externo a ATTRACT; el juego lo recibe, no lo genera. Ver
[`ADR-0011`](../spec/decisions/0011-fuente-synopsis-regeneracion-campo.md).

---

## 2 · CAMPOS

### 2.1 Mapeo

| Campo del mockup | Origen | ¿Obligatorio? | Si falta, la pantalla… |
|---|---|---|---|
| `title` | `title` | **Sí** — Pegasus no permite `game:` sin título | No es un caso de "falta": `attract doctor` rechaza la entrada antes de llegar a pantalla (§4) |
| `year` | `releaseYear` | No | `"Sin Información"` |
| `dev` | `developer` | No | `"Sin Información"` |
| `genre` | `genre` | No | `"Sin Información"` |
| `players` | `players` (entero máx) | No — **CONFIRMAR** | Ver nota 1 abajo |
| `synopsis` | `summary` / `description` | No | `"Sin Información"` |
| `system` | ❌ no existe → `game.collections` | **Sí** | Sin colección el juego no aparece en ningún menú — no es un estado de pantalla, es un juego invisible. `attract doctor` debería marcarlo |
| `cover` | `assets.boxFront` | No | Cadena de fallback §2.2 — nunca queda vacío |
| `video` | `assets.video` | No — **CONFIRMAR** | Ver nota 2 abajo |
| `review.score` | `rating` (nativo) + `data.json → review.score` | No | `"Sin Información"` si `review` es `null` — §2.3 |
| `review.cats[6]` | `data.json → review.cats` | No | Igual que arriba: es parte del mismo objeto `review`, va con `score`. Ver nota 3 abajo |
| `mags[]` | `data.json → mags` (ADR-0001) | No | `"Sin cobertura en revistas"` — §2.3 |
| `cheats` | `data.json → cheats` (ADR-0001) | No | `"No Disponible"` |
| `manual` | `data.json` / `x-` | No | `"No Disponible"` |
| badge FORMATO | `x-formato` | **Sí** — se conoce siempre por el sistema/tipo de ROM | — (§2.3, ya resuelto) |

**Nota 1 — `players` → resuelto.** Se acepta el default `1` de Pegasus tal
cual, sin distinguir "no sé" de "es de 1 jugador de verdad" — a diferencia de
`rating`, acá la colisión no molesta: un `1` por defecto casi nunca es una
mentira dañina en juegos retro. No se lee de `data.json`, no hace falta el
mismo tratamiento que `review`.

**Nota 2 — `video` → resuelto.** No desaparece: si no hay `assets.video`, el
bloque muestra el `cover` (con su propia cadena de fallback de §2.2) en su
lugar, como si fuera un video pausado en el primer frame. Nunca queda un
hueco vacío en el layout.

**Nota 3 — `review.cats[6]` → resuelto.** Las categorías ya estaban definidas
en tu propio mockup (`docs/mockup-referencia.html`, línea 625) — no hacía
falta inventarlas: **ORIGINALIDAD, GRÁFICOS, ADICCIÓN, SONIDO, DIFICULTAD,
ANIMACIÓN**, cada una de 0 a 100.

Dos niveles de "sin dato", no uno:

- Si `review` entero es `null` → no hay reseña, bloque completo dice
  `"Sin Información"` (ninguna categoría se muestra).
- Si `review` existe pero **una categoría puntual** no tiene valor cargado
  (pasa en la práctica: reseñas parciales, con algunas categorías evaluadas
  y otras no) → esa categoría muestra `"-"` en vez de número/barra, el resto
  de las categorías que sí tienen dato se muestran normal.

### 2.2 Cadenas de fallback
<Escribilas. Un arcade no tiene caja: Maze of the Kings tiene `marquee` y `poster`.>

```
cover:  boxFront → poster → marquee → genérico (placeholder)
```

Decidida en el LAB 0.2 (`docs/mapeo-mockup-pegasus.md`). Se prueba primero la
carátula real; si no hay, el poster de la revista/promocional; si no hay
ninguno de los dos, el marquee (cartel luminoso del gabinete); si tampoco hay
eso, un cover genérico para que la pantalla nunca quede sin imagen.

### 2.3 El desnudo
<Qué muestra la pantalla en cada bloque cuando el juego es Maze of the Kings.>

**Regla general:** ningún bloque desaparece. La estructura del diseño se
mantiene siempre igual, tenga datos o no — lo que cambia es el contenido:

- Bloques de **texto** sin dato → `"Sin Información"`.
- Bloques de **juegos/trucos/manuales** sin dato → `"No Disponible"`.

- **Bloque NOTA DE LA CRÍTICA sin reseña →** se muestra vacío, con
  `"Sin Información"`. El theme decide esto mirando `data.json → review`:
  si es `null` (Maze of the Kings), no hay nota; si es un objeto, hay nota.

- **El `94` gigante cuando `rating` default es `0.0` → resuelto, ya no es un
  problema.** La colisión del campo nativo de Pegasus (`rating`, que no
  distingue "sin nota" de "nota cero") deja de importar porque el bloque
  nunca lee ese campo para decidir qué mostrar — lee `review` de `data.json`,
  que sí puede ser `null` de verdad. `rating` (nativo) se sigue seteando por
  compatibilidad con Pegasus (ordenar por nota, favoritos), pero la pantalla
  no confía en él para este bloque.

- **Badge FORMATO en un GD-ROM → resuelto.** No es un caso de "falta info":
  Maze of the Kings SÍ tiene el dato (`x-formato: GD-ROM` en el fixture). El
  problema era de dónde lo lee el theme — `mediaFor()` (la función nativa
  que mapea colección → ícono) asume que **todo** lo de Arcade es cartucho,
  sin mirar el juego individual, y se equivoca en 4 de tus 5 juegos (tabla
  completa en `docs/mapeo-mockup-pegasus.md` §`cartridge`). **Decisión:** el
  badge se arma siempre desde `x-formato` (texto, el dato real por juego),
  ignorando lo que devuelva `mediaFor()`. La ingesta decide el valor al
  generar el metadata; el theme solo lo muestra.

- **NOTAS EN REVISTAS con `mags:[]` → resuelto, mensaje propio.** No es lo
  mismo "no tenemos ese dato" (Sin Información) que "este juego
  específicamente no aparece en ninguna revista escaneada todavía" — lo
  segundo es más informativo y evita que un juego con revistas y uno sin
  se lean igual de "vacíos". Mensaje: **`"Sin cobertura en revistas"`**.
  El theme lo muestra cuando `data.json → mags` es `[]` o no existe.

**Pendiente menor:** el mensaje de "Sin cobertura en revistas" lo propuse yo
— si no te cierra el tono, cambialo, es solo texto de UI.

---

## 3 · PROCEDENCIA

> 🔥 La sección que vas a querer saltear porque es aburrida.
> Es la que te salva en M7, cuando cinco workers escriban sobre el mismo juego
> en paralelo y no sepas quién pisó qué.
> Es gratis hoy y carísima en tres módulos.

### 3.1 ¿Cómo se marca un campo generado por IA vs. curado a mano?

**Decisión:** no se distingue. Todos los campos son iguales, sin importar
quién o qué los escribió. Riesgo aceptado a propósito: si algún día corre un
reproceso automático (`attract ingest`, M7) sobre un juego que ya fue
corregido a mano, no hay forma de que el sistema sepa que no debe tocar ese
campo — lo va a pisar igual que a cualquier otro.

**Nota:** `fixtures/arcade/metadata.pegasus.txt` tiene `x-procedencia: manual`
en `mok` y `sf2ce`, de antes de esta decisión. Se deja sin tocar a propósito
— hoy no lo lee nada, pero si esta decisión se revisita más adelante, ya hay
un ejemplo real de cómo se vería el campo, en vez de tener que inventarlo de
cero.

### 3.2 ¿Cómo se marca un campo verificado contra fuente?

Consecuencia directa de 3.1: si no se distingue origen, tampoco hay campo de
verificación — sería un cartelito del mismo tipo, con el mismo problema. No
aplica.

### 3.3 Si reproceso un juego, ¿qué se pisa y qué se respeta?

**Todo se pisa siempre.** El reproceso más reciente gana, sin excepción,
sobre cualquier campo — no hay noción de "esto no se toca". Consecuencia
práctica: si en algún momento existe un reproceso automático, correrlo sobre
un juego ya corregido a mano deshace esa corrección sin aviso. La mitigación,
dado este contrato, no es técnica sino de proceso — revisar el resultado de
cualquier reproceso antes de aceptarlo, no confiar en que respeta lo tocado
antes.

---

## 4 · VALIDACIÓN

### 4.1 ¿Qué hace que una entrada sea **VÁLIDA**?
### 4.2 ¿Qué hace que sea **COMPLETA**?
<No es lo mismo. Son ortogonales. Dame un ejemplo de cada combinación.>

**Decisión:** son dos ejes independientes.

- **VÁLIDA** = no rompe nada técnico — nombres legales en Windows, sin bytes
  inválidos, JSON bien formado, todo lo que `attract doctor` chequea. No
  depende de cuánta información tiene.
- **COMPLETA** = tiene todos los datos deseables (sinopsis, cover, video,
  reseña...). No depende de si algo está roto.

Las 4 combinaciones, con ejemplos reales del banco:

| | Válida | Inválida |
|---|---|---|
| **Completa** | Striker: tiene todo y nada roto | Un juego con toda la data cargada, pero la carpeta tiene `:` en el nombre o el `data.json` tiene un byte inválido |
| **Incompleta** | Maze of the Kings, el desnudo: casi todo en `null`, pero técnicamente perfecto | Un juego casi vacío que además tiene el nombre de carpeta mal formado — lo peor de los dos mundos |

### 4.3 El desnudo tiene que ser VÁLIDO. Escribí por qué.

**Decisión: sí, siempre.** La misión del proyecto dice que el juego pelado es
el caso principal — de miles de juegos, la enorme mayoría se queda sin scan
ni reseña para siempre. Si un juego pelado pudiera ser inválido, la mayoría
de la colección podría estar rota por diseño, lo opuesto de lo que se está
construyendo. La completitud es opcional; la validez, no — nunca dependen la
una de la otra.

### 4.4 Chequeos automáticos
<Cuáles ya cubre `attract doctor` y cuáles faltan.>

**Criterio general:** Windows es el estándar, siempre — es el más estricto
de los dos sistemas, y todo lo que Windows rechazaría tiene que fallar en el
Mac (filosofía ya escrita en `src/attract/doctor.py`, no es nueva acá, se
reafirma). Todo carácter, nombre y regla se valida contra la norma de
Windows, nunca contra la de macOS.

**Ya cubre** (`CHEQUEOS_UNIVERSALES` + `chk_metadata` en `doctor.py`):

- Encoding UTF-8 válido en todo archivo de texto.
- Sin `CRLF` (Pegasus espera `LF`).
- Nombres ilegales en Windows: caracteres prohibidos (`< > : " / \ | ? *`),
  nombres reservados (`CON`, `PRN`, `AUX`, `NUL`, `COM1-9`, `LPT1-9`),
  terminar en espacio o punto.
- Nombres en NFC (no NFD, que es lo que produce macOS por default).
- Basura de macOS (`.DS_Store`, `._*`, etc.) que Pegasus puede confundir con
  un juego.
- Solo dentro de `*.pegasus.txt`: contenido en NFC (no solo el nombre del
  archivo), separador de ruta (avisa si usás `\` en vez de `/`), y que cada
  `assets.*` apunte a un archivo que existe de verdad en disco.
- `data.json` y `magazine.json` son JSON **sintácticamente válido**
  (`chk_json_valido`) — ERROR si no. Un `data.json` con una coma de más ya
  no pasa en silencio, explota en `doctor`, no en el theme.
- `mags[].ref` de un `data.json` apunta a una carpeta real en
  `<raíz-librería>/_magazines/` (`chk_mags_ref`) — **AVISO**, no ERROR: la
  degradación con un `ref` colgado es un caso soportado a propósito (ver
  `fixtures/arcade/media/sf2ce/`, ADR-0008), no bloquea el viaje a
  Windows, pero se nota.
- Cada página de `pages[]` y el `cover` existen en el disco
  (`chk_magazine_assets`, ADR-0024) — **ERROR**. Las páginas se buscan en
  `<revista>/pages/` y la tapa en la raíz de la revista. Sin este chequeo el
  único síntoma de una carpeta mal armada era una página en blanco en el
  visor, que es el peor lugar para enterarse. Se reportan hasta 5 y después
  el conteo: si el layout está mal, están todas mal.
- El contrato completo de `magazine.json` (`chk_magazine_contrato`,
  ADR-0024): campos obligatorios (`name`, `cover`, `key_id`, `pages`,
  `articles`), tipos correctos, `articles[].confidence` entre 0.0 y 1.0,
  `articles[].type` obligatorio (si no es uno de los conocidos, AVISO no
  ERROR — el enum no es cerrado), `game`/`title` opcionales, flags de
  `review` (`cheats`/`walkthrough`/`tips`) validados como boolean si están
  presentes.

**Falta:**

- (nada pendiente de esta lista por ahora)
