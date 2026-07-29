# Mapeo mockup → Pegasus

> 🔴 **Lo completás vos en el LAB 0.2 (Bloque 4 de M0).**
> Una fila por campo, una columna por juego del banco.
> Cada celda: qué valor va, o `DECIDIR` con la pregunta escrita.

| Campo      | Striker | Maze of the Kings | SF2 CE | Cadillacs | TMNT NES |
|------------|---------|-------------------|---------|-----------|----------|
| `title`    | Striker | The Maze of the Kings | Street Fighter II': Champion Edition | Cadillacs and Dinosaurs | Teenage Mutant Ninja Turtles II: The Arcade Game |
| `year`     | 1988 | 1995 | 1992 | 1993 | 1990 |
| `system`   | Amiga | Sega NAOMI | Capcom CPS-1 | Capcom CPS-1 | Nintendo Entertainment System (NES) |
| `dev`      | Diggers Studio / Eclipse Software | Sega AM1 | Capcom | Capcom | Konami |
| `genre`    | Deportes / Fútbol | Light Gun Shooter | Fighting | Beat 'em Up | Beat 'em Up |
| `players`  | 1-2 | 1-2 | 1-2 | 1-3 | 1-2 |
| `synopsis` | Simulador de fútbol con vista superior, muy popular en ordenadores Amiga y Atari ST. | Shooter sobre raíles en el que los jugadores exploran un laberinto lleno de criaturas mitológicas utilizando pistolas de luz. | Versión mejorada de Street Fighter II con ajustes de equilibrio, nuevos movimientos y posibilidad de elegir a los cuatro jefes finales. | Beat 'em up basado en el cómic Xenozoic Tales donde los protagonistas luchan contra bandas y dinosaurios en un mundo postapocalíptico. | Adaptación doméstica del arcade de TMNT donde las Tortugas Ninja recorren distintos niveles para rescatar a April y derrotar a Shredder. |
| `cover`    | striker.jpg | maze_of_the_kings.jpg | street_fighter_ii_ce.jpg | cadillacs_and_dinosaurs.jpg | tmnt2_arcade_game.jpg |
| `video`    | striker.mp4 | maze_of_the_kings.mp4 | sf2ce.mp4 | cadillacs.mp4 | tmnt2.mp4 |
| `mags[]`   | [] | [] | [] | [] | [] |
| `manual`   | null | null | null | null | null |
| `cheats`   | null | null | null | null | null |
| `review`   | 94 | null | 95 | 93 | 90 |
| FORMATO    | Diskette | GD-ROM | PCB | PCB | Cartucho |
| `file:`    | Striker.adf | maze.zip | sf2ce.zip | dino.zip | Teenage Mutant Ninja Turtles II - The Arcade Game (USA).nes |

## Las preguntas que la tabla te fuerza

**`system`** — el mockup muestra `AMIGA · DOS`. En Pegasus son colecciones y un juego
puede estar en varias. ¿Todas? ¿La primera? ¿Una `x-system-label`?

**Decisión:** se nombran todas las plataformas donde existió el juego, pero
`game.collections` (el campo real, el que determina qué colección lo puede
lanzar) solo incluye las versiones de las que hay ROM/imagen jugable. Striker
existe en Amiga y DOS; acá solo hay ROM de Amiga → `system` en la práctica es
Amiga únicamente, porque DOS no es ejecutable en este banco.

**Resuelto:** dos campos custom. `x-system-otros` lista las plataformas
donde existió el juego pero no hay ROM (Striker → `DOS`). `x-system-aviable`
*(revisar ortografía: "disponible")* marca cuáles sí están en `collections`
— es decir, cuáles son jugables acá.

**Pendiente menor:** si `x-system-aviable` termina siendo siempre "lo mismo
que `game.collections`", es un campo redundante — `collections` ya te dice
eso. Piensa si le agrega algo o si te alcanza con `x-system-otros` solo.

**`players`** — Pegasus guarda un entero (máximo). Striker es `'1-2'`. TMNT arcade es 4,
TMNT NES es 2. ¿Perdés el rango o agregás `x-players-label`? Si agregás las dos,
¿cuál gana cuando discrepan?

**Decisión:** se muestra el máximo de jugadores que permite cada juego. Sin
`x-players-label` — se pierde el rango (`'1-2'` queda en `2`), a propósito,
para no mantener dos fuentes de verdad que puedan discrepar.

**`rating`** — Pegasus: float 0.0–1.0. Vos: entero sobre 100. `94 → 0.94 → 94` sobrevive.
¿Y `0.945`? **El default es `0.0`: no podés distinguir "sin nota" de "nota cero".**
Tu mockup muestra un `94` gigante. ¿Qué muestra con el desnudo?

**Decisión (actualizada en el LAB 0.3):** resuelto, no hace falta aceptar la
colisión. El bloque NOTA DE LA CRÍTICA no lee el `rating` nativo de Pegasus
para decidir si hay nota o no — lee `data.json → review`, que sí puede ser
`null` de verdad (Maze of the Kings) vs. un objeto con datos (Striker). Si es
`null`, el bloque se muestra vacío con `"Sin Información"`; si no, se muestra
el puntaje. El `rating` nativo se sigue seteando por compatibilidad con
Pegasus (ordenar, favoritos), pero la pantalla no confía en él para esto. La
escala a 1-10 sigue siendo un detalle de presentación aparte. Ver
`docs/CONVENCION.md` §2.3.

**`cartridge`** — `mediaFor()` mapea ARCADE → cartucho y miente con 4 de tus 5 juegos:

| Juego | Medio real | `mediaFor()` devuelve realmente |
|--------------------------|---------------------------|--------------|
| Maze of the Kings | GD-ROM | `MediaType.CARTRIDGE` ❌ |
| SF2 CE | PCB JAMMA (CPS-1) | `MediaType.CARTRIDGE` ❌ |
| Cadillacs and Dinosaurs | PCB CPS-1 | `MediaType.CARTRIDGE` ❌ |
| Metal Slug (Neo Geo MVS) | Cartucho MVS | `MediaType.CARTRIDGE` ✅ (de casualidad) |

`mediaFor()` no mira el juego individual — mira la **colección**. Para
cualquier cosa dentro de `Arcade` devuelve siempre `CARTRIDGE`, sin evaluar
nada del juego puntual. No es capaz de devolver `GDROM` ni `PCB` en ningún
caso: no tiene esa granularidad. Acierta en Metal Slug de pura casualidad
(sí es cartucho de verdad), no porque haya distinguido algo.

**Decisión (LAB 0.3):** el badge se arma siempre desde `x-formato` — el dato
real por juego, ya presente en el fixture (`x-formato: GD-ROM`, `x-formato:
PCB`) — ignorando lo que devuelva `mediaFor()`. Es texto (`x-formato`), no un
asset: no hace falta un ícono gráfico por cada medio posible, alcanza con la
etiqueta. La ingesta decide el valor (lo escribe al generar el metadata); el
theme solo lo muestra tal cual.

**`cover` para arcades** — Maze of the Kings y SF2 CE no tienen caja. Tienen `marquee`
y `poster`. Escribí la cadena de fallback. **Esa cadena es parte del contrato.**

**Resuelto:** `boxFront` → `poster` → `marquee` → cover genérico (placeholder)
si no hay ninguno de los tres. Cadena completa, sin pendientes.

**`file:` con merged** — corré esto y anotá:

```bash
mame -listxml sf2ce | grep -c "<machine"     # ¿cuántos sets en la familia?
unzip -l sf2ce.zip | tail -1                  # ¿cuántos archivos adentro?
mame -listxml mok | grep -E "disk name|romof|<machine name"
```

El primer número te va a decir cuántos juegos viven dentro de un archivo que creías
que era uno.

### Resultados

**`mok` — resuelto, 1 juego.** El `-listxml` devuelve una sola `<machine>`
jugable (`name="mok"`, sin `runnable="no"`), que depende de un romset padre
(`romof="naomigd"`) y usa un disco GD-ROM (`disk name="gds-0022"`). Todo lo
demás que aparece en el grep (`z80`, `speaker`, `nvram`, `aica`...) son
componentes internos del hardware — CPU, sonido, memoria — marcados
`isdevice="yes" runnable="no"`. No son "otros juegos adentro del zip", son
piezas del emulador. Confirma la fila `file:`: `mok.zip` + `naomigd` como
BIOS, un solo juego real.

<details>
<summary>Salida completa de <code>mame -listxml mok</code></summary>

```
<!ATTLIST machine romof CDATA #IMPLIED>
    <!ATTLIST disk name CDATA #REQUIRED>
<machine name="mok" sourcefile="sega/naomi.cpp" romof="naomigd">
    <disk name="gds-0022" sha1="ddd6bf6a93f44f04199b278149ded19b26cdcab4" region="gdrom" index="0" writable="no"/>
<machine name="24c01" sourcefile="devices/machine/i2cmem.cpp" isdevice="yes" runnable="no">
<machine name="93c46_16" sourcefile="devices/machine/eepromser.cpp" isdevice="yes" runnable="no">
<machine name="93c46_8" sourcefile="devices/machine/eepromser.cpp" isdevice="yes" runnable="no">
<machine name="aica" sourcefile="devices/sound/aica.cpp" isdevice="yes" runnable="no">
<machine name="aicartc" sourcefile="devices/machine/aicartc.cpp" isdevice="yes" runnable="no">
<machine name="arm7_le" sourcefile="devices/cpu/arm7/arm7.cpp" isdevice="yes" runnable="no">
<machine name="ata_slot" sourcefile="devices/bus/ata/atadev.cpp" isdevice="yes" runnable="no">
<machine name="cdda" sourcefile="devices/sound/cdda.cpp" isdevice="yes" runnable="no">
<machine name="dc_g2if" sourcefile="sega/dc_g2if.cpp" isdevice="yes" runnable="no">
<machine name="gdrom" sourcefile="devices/bus/ata/gdrom.cpp" isdevice="yes" runnable="no">
<machine name="gdrom_image" sourcefile="devices/imagedev/cdromimg.cpp" isdevice="yes" runnable="no">
<machine name="ide_gdrom" sourcefile="sega/naomigd.cpp" isdevice="yes" runnable="no">
<machine name="idectrl32bm" sourcefile="devices/machine/idectrl.cpp" isdevice="yes" runnable="no">
<machine name="jvs13551" sourcefile="sega/jvs13551.cpp" isdevice="yes" runnable="no">
<machine name="m3comm" sourcefile="sega/m3comm.cpp" isdevice="yes" runnable="no">
<machine name="m68000" sourcefile="devices/cpu/m68000/m68000.cpp" isdevice="yes" runnable="no">
<machine name="maple_dc" sourcefile="sega/maple-dc.cpp" isdevice="yes" runnable="no">
<machine name="mie" sourcefile="sega/mie.cpp" isdevice="yes" runnable="no">
<machine name="mie_jvs" sourcefile="sega/mie.cpp" isdevice="yes" runnable="no">
<machine name="nvram" sourcefile="devices/machine/nvram.cpp" isdevice="yes" runnable="no">
<machine name="pci_root" sourcefile="devices/machine/pci.cpp" isdevice="yes" runnable="no">
<machine name="pic16c622" sourcefile="devices/cpu/pic16c62x/pic16c62x.cpp" isdevice="yes" runnable="no">
<machine name="powervr2" sourcefile="sega/powervr2.cpp" isdevice="yes" runnable="no">
<machine name="ram" sourcefile="devices/machine/ram.cpp" isdevice="yes" runnable="no">
<machine name="screen" sourcefile="emu/screen.cpp" isdevice="yes" runnable="no">
<machine name="sega315_6154" sourcefile="sega/315-6154.cpp" isdevice="yes" runnable="no">
<machine name="segadimm" sourcefile="sega/naomigd.cpp" isdevice="yes" runnable="no">
<machine name="sh7091" sourcefile="devices/cpu/sh/sh4.cpp" isdevice="yes" runnable="no">
<machine name="speaker" sourcefile="emu/speaker.cpp" isdevice="yes" runnable="no">
<machine name="timer" sourcefile="devices/machine/timer.cpp" isdevice="yes" runnable="no">
<machine name="tmp90ph44" sourcefile="devices/cpu/tlcs90/tlcs90.cpp" isdevice="yes" runnable="no">
<machine name="x76f100" sourcefile="devices/machine/x76f100.cpp" isdevice="yes" runnable="no">
<machine name="z80" sourcefile="devices/cpu/z80/z80.cpp" isdevice="yes" runnable="no">
```

</details>

**`sf2ce` — resuelto.** `grep -c "<machine"` había dado `10`, pero contaba
también los `isdevice="yes" runnable="no"` (CPU, sonido, etc.), no solo los
sets jugables. Primer intento de filtro (`runnable="yes"` explícito) no
devolvió nada — las máquinas jugables no llevan ese atributo, se omite por
default; solo los dispositivos internos marcan `runnable="no"`. Filtro
correcto:

```bash
mame -listxml sf2ce | grep '<machine name' | grep -v 'runnable="no"'
```

**Resultado contra la librería real: 1 sola línea.**

```
<machine name="sf2ce" sourcefile="capcom/cps1.cpp">
```

**Conclusión:** en esta librería, `sf2ce.zip` es **1 solo juego jugable**, sin
otros clones empaquetados en el mismo archivo. Los 27 archivos que contaba
`unzip -l` no son 27 juegos — son las ROMs individuales de los chips de una
placa CPS1 (programa, gráficos, sonido...). A diferencia de `mok`, acá no hay
`romof`/BIOS externa: `sf2ce` corre autónomo. La dependencia externa
("1 archivo ≠ autónomo") es un problema de `mok`, no de `sf2ce`.

**Ojo con generalizar:** este resultado es específico de *este* archivo
concreto de tu librería. Un set "merged" de la familia completa de Street
Fighter II (con todos los clones — CE, Turbo, WW, etc. empaquetados juntos
bajo un solo parent) daría más de una línea acá. Si algún día cambiás de
fuente de ROMs, volvé a correr este chequeo — no asumas que el resultado de
hoy vale para siempre (la misma lógica de ADR-0005 con la versión de MAME).

**`unzip -l sf2ce.zip` contra el fixture** — falla porque `fixtures/arcade/sf2ce.zip`
pesa 0 bytes a propósito (es un archivo vacío para que `attract doctor` tenga
estructura que masticar sin pesar 260 MB, ver `CLAUDE.md` §Reglas de trabajo).
Sin bytes no hay directorio central de zip que leer — la pregunta no tiene
respuesta contra el fixture, y no hace falta que la tenga.

**`unzip -l sf2ce.zip` contra la librería real — resuelto:**

```
  8194511                     27 files
```

**27 archivos** dentro del zip real. Confirma lo que sospechabas: `sf2ce.zip`
con merged no es un solo romset, es un paquete con varios sets adentro
(parent + clones + samples/dispositivos compartidos). Para saber cuántos de
esos 27 son juegos jugables (vs. samples de audio u otros datos empaquetados),
hace falta cruzarlo con el resultado filtrado de `mame -listxml sf2ce`
(comando de arriba) — el zip te dice *cuántos archivos*, el `-listxml` te dice
*cuántos son máquinas jugables*. Son dos preguntas relacionadas, no la misma.