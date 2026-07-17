# Mapeo mockup → Pegasus

> 🔴 **Lo completás vos en el LAB 0.2 (Bloque 4 de M0).**
> Una fila por campo, una columna por juego del banco.
> Cada celda: qué valor va, o `DECIDIR` con la pregunta escrita.

| Campo | Striker | Maze of the Kings | SF2 CE | Cadillacs | TMNT NES |
|---|---|---|---|---|---|
| `title` | | | | | |
| `year` | | | | | |
| `system` | | | | | |
| `dev` | | | | | |
| `genre` | | | | | |
| `players` | | | | | |
| `synopsis` | | | | | |
| `cover` | | | | | |
| `video` | | | | | |
| `mags[]` | | `[]` | | | |
| `manual` | | `null` | | | |
| `cheats` | | `null` | | | |
| `review` | 94 | `null` | | | |
| FORMATO | Diskette | **GD-ROM** | PCB | PCB | Cartucho |
| `file:` | | 🔥 **¿cuál?** | 🔥 **¿1 o N juegos?** | | |

## Las preguntas que la tabla te fuerza

**`system`** — el mockup muestra `AMIGA · DOS`. En Pegasus son colecciones y un juego
puede estar en varias. ¿Todas? ¿La primera? ¿Una `x-system-label`?

**`players`** — Pegasus guarda un entero (máximo). Striker es `'1-2'`. TMNT arcade es 4,
TMNT NES es 2. ¿Perdés el rango o agregás `x-players-label`? Si agregás las dos,
¿cuál gana cuando discrepan?

**`rating`** — Pegasus: float 0.0–1.0. Vos: entero sobre 100. `94 → 0.94 → 94` sobrevive.
¿Y `0.945`? **El default es `0.0`: no podés distinguir "sin nota" de "nota cero".**
Tu mockup muestra un `94` gigante. ¿Qué muestra con el desnudo?

**`cartridge`** — `mediaFor()` mapea ARCADE → cartucho y miente con 4 de tus 5 juegos:

| Juego | Medio real | `mediaFor()` |
|---|---|---|
| Maze of the Kings | GD-ROM | ❌ Cartucho |
| SF2 CE | PCB JAMMA | ❌ Cartucho |
| Cadillacs | PCB CPS1 | ❌ Cartucho |
| Metal Slug (Neo Geo MVS) | **cartucho de verdad** | ✅ |

Acierta solo en el juego que cortamos del banco. ¿El badge es un asset
(`assets.cartridge`), un texto (`x-formato`), o los dos? ¿Quién decide — la ingesta
o el theme?

**`cover` para arcades** — Maze of the Kings y SF2 CE no tienen caja. Tienen `marquee`
y `poster`. Escribí la cadena de fallback. **Esa cadena es parte del contrato.**

**`file:` con merged** — corré esto y anotá:

```bash
mame -listxml sf2ce | grep -c "<machine"     # ¿cuántos sets en la familia?
unzip -l sf2ce.zip | tail -1                  # ¿cuántos archivos adentro?
mame -listxml mok | grep -E "disk name|romof|<machine name"
```

El primer número te va a decir cuántos juegos viven dentro de un archivo que creías
que era uno.
