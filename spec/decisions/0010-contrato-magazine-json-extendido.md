---
id: 0010
title: "Contrato de magazine.json extendido con evidencia real (supersede 0008)"
status: accepted
date: "2026-07-28"
supersedes: 0008
superseded-by: null
tags: [data, backend]
---

# 0010 — Contrato de `magazine.json` extendido con evidencia real

## Contexto

[`ADR-0008`](0008-modelo-datos-revistas.md) definió el contrato de
`magazine.json` con datos **inventados** para probar la estructura (páginas
no consecutivas, relación muchos-a-muchos). Después de esa ADR apareció un
`magazine.json` **real**, producido fuera de ATTRACT (el subsistema del que
habla [`ADR-0009`](0009-frontera-produccion-consumo-revistas.md)), y no
coincide del todo con el contrato inventado:

**Lo que coincide:** estructura general (`name`, `pages`, `articles[]`),
páginas como imágenes (confirma otra vez ADR-0007).

**Lo que no coincide:**

- `issue` y `year` llegan en `null` — el archivo real no siempre los tiene.
- `name` es el nombre del archivo de origen (`"se-micro80.pdf"`), no un
  nombre limpio para mostrar.
- Falta `color`, que el contrato original pedía.
- Aparecen campos nuevos, no contemplados: `type` (categoría del artículo:
  `publicidad`, `índice`, `review`, `noticia`, `entrevista`, `especial`,
  `hardware`, `preview`…), `confidence` (0.0–1.0, qué tan seguro está el
  proceso que lo generó de esa clasificación), `key_id` (identificador del
  origen, útil para deduplicar), y en artículos de tipo `review`:
  `cheats`/`walkthrough`/`tips` como booleanos.
- No todos los artículos tienen `game` — los que no tratan sobre un juego
  puntual (publicidad, índice, noticias generales) no lo llevan.

Como el subsistema de escaneo/clasificación (ADR-0009) ya produce estos
campos y parecen aportar valor real (no son ruido), el contrato se actualiza
para reflejar lo que efectivamente existe, en vez de mantener uno más pobre
por apego al primer diseño.

## Decisión

Se **amplía** el contrato de `magazine.json`. Campos nuevos u opcionalizados
respecto de ADR-0008, marcados explícitamente:

```json
{
  "name": "string",
  "issue": "string | null",
  "year": "number | null",
  "color": "string (hex) | null",
  "cover": "string",
  "key_id": "string",
  "pages": ["p002.jpg", "..."],
  "articles": [
    {
      "type": "string",
      "game": "string (solo si el artículo trata sobre un juego puntual)",
      "title": "string (ausente en artículos sin título propio, ej. publicidad)",
      "startPage": "number",
      "pages": ["number", "..."],
      "confidence": "number (0.0–1.0)",
      "cheats": "boolean (solo en type == 'review')",
      "walkthrough": "boolean (solo en type == 'review')",
      "tips": "boolean (solo en type == 'review')"
    }
  ]
}
```

Cambios concretos respecto de ADR-0008:

1. **`issue`, `year`, `color` pasan a opcionales** (`null` permitido) — antes
   se asumían siempre presentes.
2. **`type` es obligatorio por artículo** — clasifica qué es cada página
   (anuncio, reseña, entrevista, etc.), no todo artículo trata sobre un
   juego.
3. **`game` y `title` son opcionales**, condicionados al `type` — un aviso
   publicitario no tiene ni uno ni el otro.
4. **`confidence` es obligatorio por artículo** — el theme y `attract doctor`
   pueden usarlo a futuro para marcar visualmente lo que viene con baja
   confianza (por ejemplo, pedir revisión humana antes de mostrarlo).
5. **`cheats`/`walkthrough`/`tips` son específicos de `type: "review"`** —
   indican si esa reseña puntual trae esas secciones, no se usan en otros
   tipos de artículo.
6. **`key_id` se agrega** como identificador del origen — no lo consume el
   theme, es para que el subsistema de generación pueda deduplicar o
   rastrear de qué escaneo salió cada `magazine.json`.

**Lo que NO cambia de ADR-0008:** la relación muchos-a-muchos, que las
páginas son imágenes, que el juego referencia por `ref` sin copiar páginas,
la estructura de carpetas (`media/_magazines/<id>/`). Esta ADR solo amplía
la forma interna de `articles[]` y afloja algunos campos a opcionales.

## Alternativas consideradas

### Adaptar cada `magazine.json` real al contrato viejo, descartando los campos nuevos

- A favor: no hay que tocar ninguna ADR ni el código que ya asuma el
  contrato de 0008.
- En contra: se pierde `type`, `confidence` y los flags de reseña — datos
  que ya vienen generados y que tienen valor real (por ejemplo, filtrar
  publicidad al listar artículos, o priorizar revisión humana en artículos
  de baja `confidence`).
- **Descartada porque:** tirar datos reales para mantener un contrato
  diseñado con datos inventados es al revés de cómo debería funcionar esto
  — el contrato tiene que reflejar la realidad, no una suposición temprana.

## Consecuencias

**Positivas**

- El contrato ahora refleja lo que el subsistema de escaneo realmente
  produce, sin traducción intermedia.
- `type` permite que el theme filtre o trate distinto la publicidad de una
  reseña real, sin heurísticas adicionales.
- `confidence` abre la puerta a mostrar (a futuro) qué artículos conviene
  revisar a mano antes de confiar en ellos ciegamente.

**Coste asumido**

- ~~El `magazine.json` de fixture quedó desactualizado respecto de este
  contrato~~ — **actualizado 2026-07-28**, ver Verificaciones pendientes.
- `attract doctor` no valida ninguno de los campos nuevos todavía (ni
  siquiera los de ADR-0008 originales — ver `docs/CONVENCION.md` §4.4).
- `name` puede llegar "sucio" (nombre de archivo, no nombre de revista
  limpio) — no es responsabilidad de ATTRACT limpiarlo (ADR-0009), pero si
  se muestra tal cual en pantalla, se ve mal. Sin resolver todavía.

**Qué habría que revisar si esto se replantea**

- Si el subsistema de escaneo cambia de forma otra vez (nuevos campos, o
  deja de producir alguno de estos), esta ADR se vuelve a superseder — no
  se edita.

## Verificaciones pendientes

- [x] **Resuelto 2026-07-28** — se actualizó el fixture de `micromania-16`
      al contrato de esta ADR: `key_id`, `type`/`confidence` por artículo,
      flags `cheats`/`walkthrough`/`tips` en el artículo `review`. Se
      aprovechó para agregar un segundo artículo `publicidad` (sin
      `game`/`title`) en la página 6 — la misma página que interrumpe el
      artículo `review`, así el fixture encarna literalmente el motivo de
      la no-consecutividad en vez de solo declararla.
- [x] **Resuelto 2026-07-28** — regla de presentación (no de datos: no
      modifica `magazine.json`, es solo cómo el theme arma el string que
      muestra en pantalla, respeta ADR-0009 porque no persiste nada nuevo):
      si `name` termina en una extensión de archivo conocida (`.pdf`,
      `.cbz`, `.zip`...), el theme le saca la extensión y reemplaza `-`/`_`
      por espacios antes de mostrarlo (`"se-micro80.pdf"` → `"se micro80"`)
      — mejor una limpieza mínima e imperfecta que el nombre de archivo
      crudo. No se intenta capitalizar ni adivinar más estructura: sería
      heurística frágil sin evidencia de qué formas reales toma `name`.
      Si `issue`/`year` están presentes, se anteponen al `name` limpio
      (`"<name> Nº<issue> (<year>)"`); si no, se muestra solo el `name`
      limpio. Sin código todavía porque el theme de producción (el mockup
      React/CSS reescrito en QML) no existe en el repo — esta regla queda
      documentada para cuando se implemente.
- [x] **Resuelto 2026-07-28** — `attract doctor` valida sintaxis JSON de
      `magazine.json`/`data.json` (`chk_json_valido`, ERROR), que
      `mags[].ref` resuelva a una carpeta real (`chk_mags_ref`, AVISO — la
      degradación con `ref` colgado es aceptada a propósito), y el contrato
      completo de campos de `magazine.json` (`chk_magazine_contrato`,
      ADR-0010): obligatorios, tipos, `confidence` en rango, `type` con
      AVISO si no es uno de los conocidos (enum no cerrado).

## Referencias

- [`0008-modelo-datos-revistas.md`](0008-modelo-datos-revistas.md) — ADR
  superseded por esta.
- [`0009-frontera-produccion-consumo-revistas.md`](0009-frontera-produccion-consumo-revistas.md)
  — de dónde sale el `magazine.json` real que motivó este cambio.
- `magazine.json` real subido durante la sesión del 2026-07-28 (archivo de
  origen: `se-micro80.pdf`, 71 páginas) — evidencia empírica de esta ADR.
