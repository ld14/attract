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

### 1.2 ¿Cómo se nombra la carpeta de un juego?
<Una **regla**, no un ejemplo.>

> Restricciones que no son opinables:
> - Windows prohíbe `< > : " / \ | ? *`, los nombres CON PRN AUX NUL COM1-9 LPT1-9,
>   y terminar en espacio o punto. **Tu juego #3 tiene `:` en el título.**
> - Todo en NFC. macOS descompone y no te avisa.
> - Con **merged**, `sf2ce.zip` no es un juego: es una familia. Ver ADR-004.
> - Identidad ≠ presentación. `dino` es la identidad; *Cadillacs and Dinosaurs* es
>   cómo se muestra.

### 1.3 ¿Dónde van los assets?
<Y los scans de revista, que son N páginas por número.>

> Pegasus auto-descubre en `media/<archivo-sin-extensión>/<asset>.<ext>`.
> Con merged eso **agrupa por familia**: una carátula para todos los clones.
> ¿Lo aceptás o necesitás `assets.*` explícitos?

### 1.4 ¿Dónde van los datos ricos?
<Según ADR-001.>

---

## 2 · CAMPOS

### 2.1 Mapeo

| Campo del mockup | Origen | ¿Obligatorio? | Si falta, la pantalla… |
|---|---|---|---|
| `title` | `title` | | |
| `year` | `releaseYear` | | |
| `dev` | `developer` | | |
| `genre` | `genre` | | |
| `players` | `players` (entero máx) | | |
| `synopsis` | `summary` / `description` | | |
| `system` | ❌ no existe → `game.collections` | | |
| `cover` | `assets.boxFront` | | |
| `video` | `assets.video` | | |
| `review.score` | `rating` (0.0–1.0) | | |
| `review.cats[6]` | `x-` | | |
| `mags[]` | ADR-001 | | |
| `cheats` | ADR-001 | | |
| `manual` | `x-` | | |
| badge FORMATO | `assets.cartridge` + ? | | |

### 2.2 Cadenas de fallback
<Escribilas. Un arcade no tiene caja: Maze of the Kings tiene `marquee` y `poster`.>

```
cover:  boxFront → ? → ? → ?
```

### 2.3 El desnudo
<Qué muestra la pantalla en cada bloque cuando el juego es Maze of the Kings.>

- Bloque NOTA DE LA CRÍTICA sin reseña → ?
- El `94` gigante cuando `rating` default es `0.0` → ?
  *(no podés distinguir "sin nota" de "nota cero")*
- Badge FORMATO en un GD-ROM → ?
- NOTAS EN REVISTAS con `mags:[]` → ?

---

## 3 · PROCEDENCIA

> 🔥 La sección que vas a querer saltear porque es aburrida.
> Es la que te salva en M7, cuando cinco workers escriban sobre el mismo juego
> en paralelo y no sepas quién pisó qué.
> Es gratis hoy y carísima en tres módulos.

### 3.1 ¿Cómo se marca un campo generado por IA vs. curado a mano?
### 3.2 ¿Cómo se marca un campo verificado contra fuente?
### 3.3 Si reproceso un juego, ¿qué se pisa y qué se respeta?

---

## 4 · VALIDACIÓN

### 4.1 ¿Qué hace que una entrada sea **VÁLIDA**?
### 4.2 ¿Qué hace que sea **COMPLETA**?
<No es lo mismo. Son ortogonales. Dame un ejemplo de cada combinación.>

### 4.3 El desnudo tiene que ser VÁLIDO. Escribí por qué.

### 4.4 Chequeos automáticos
<Cuáles ya cubre `attract doctor` y cuáles faltan.>
