---
name: attract
description: >
  Valida y enriquece la libreria de ATTRACT despues de tocar fixtures/ o
  library/. Usar cuando se agrego o edito un juego, un asset, un
  data.json, un magazine.json o un metadata.pegasus.txt ("agregue un
  juego nuevo", "sume un asset", "edite el data.json de X", "revisa la
  libreria", "esto ya esta listo para commitear"). Tambien usar cuando
  aparece o cambia un archivo library/<sistema>/_synopsis/<set>.json
  ("ya tengo el synopsis de X", "cargue el texto de la revista para X").
  No dispara en preguntas generales sobre el proyecto ni en trabajo que
  no toca fixtures/ ni library/.
---

# ATTRACT — validar y enriquecer la librería

Este skill conecta "qué se acaba de tocar en la librería" con "qué comando
de `attract` corresponde correr" — el mismo chequeo que hasta ahora hacía
Luis a mano antes de dar un cambio por terminado.

## Cuándo correr `doctor`

**Disparador:** se agregó, editó o borró algo bajo `fixtures/` o
`library/` — un juego nuevo, un asset, un `data.json`, un `magazine.json`,
o `metadata.pegasus.txt`.

**Acción:**

```
make doctor
```

o, si `make` no está disponible o hace falta apuntar a otra ruta:

```
PYTHONPATH=src python3 -m attract.doctor <ruta> [--target windows]
```

**Qué hacer con el resultado:**

- **ERROR** — el cambio no está listo. No lo des por terminado ni sugieras
  commitear. Mostrá el hallazgo tal cual lo imprime `doctor` (no lo
  resumas ni lo reinterpretes) y corregilo o preguntá cómo seguir.
- **AVISO** — no bloquea, pero mencionalo explícitamente en tu respuesta.
  Un ejemplo esperado y aceptado a propósito: `mags-ref-faltante` en
  `fixtures/arcade/media/sf2ce/data.json` (degradación intencional, ver
  ADR-0008/0010) — no lo "arregles" sin que te lo pidan, es un fixture de
  prueba.

## Cuándo correr `synopsis`

**Disparador:** apareció o cambió
`library/<sistema>/_synopsis/<set>.json` (o el equivalente en
`fixtures/<sistema>/_synopsis/`) para un juego que **ya existe** como
`game:` en el `metadata.pegasus.txt` de ese sistema.

**Acción:**

```
PYTHONPATH=src python3 -m attract.synopsis <set> <ruta-del-sistema>
```

**Qué hacer con el resultado:**

- Si el comando corre OK, corré `doctor` después (el synopsis escribe
  `metadata.pegasus.txt`, hay que confirmar que sigue limpio).
- Si no hay fuente para ese `set`, **no es un error del skill** — es el
  estado normal: la mayoría de los juegos de la librería nunca van a tener
  synopsis (ver `spec/constitution/mission.md`, "el caso principal es el
  juego pelado"). No inventes un synopsis ni lo escribas a mano en
  `metadata.pegasus.txt` — el synopsis siempre sale de esa fuente
  (ADR-0011), nunca se tipea directo.
- Si `<set>` no matchea ningún `game:`, es una señal de que el juego
  todavía no fue ingresado a la librería — no crear un bloque nuevo (fuera
  de alcance de `synopsis`, ver `spec/features/001-synopsis/spec.md`).

## Reglas duras (no las rompas por no saber que existen)

- **`*.pegasus.txt` nunca se edita a mano** — es artefacto de build, no
  fuente ([`ADR-0002`](../../../spec/decisions/0002-metadata-fuente-o-artefacto.md)).
  Excepción explícita: los de `fixtures/` y `docs/` son entradas de test
  escritas a mano. Si necesitás cambiar un campo (como `summary:`), usá el
  comando correspondiente (`attract synopsis`), no `Edit` directo sobre el
  archivo.
- **`library/` nunca va a git** — no lo agregues ni lo menciones como para
  commitear.
- **Los fixtures son de 0 bytes a propósito**, salvo las excepciones
  documentadas en `CLAUDE.md` (`fixtures/arcade/sf2ce.zip`,
  `multifile-a.zip`/`multifile-b.zip`). No "arregles" un fixture de 0
  bytes agregándole contenido real sin que te lo pidan.
- **Los ADR no se editan** — si una decisión ya tomada choca con lo que
  estás por hacer, no la reinterpretes silenciosamente: decílo y proponé
  una ADR nueva que supersede, no toques el body de una `accepted`.

## Referencias

- `CLAUDE.md` — reglas de trabajo del repo completo.
- `spec/decisions/0002-metadata-fuente-o-artefacto.md`,
  `0008-modelo-datos-revistas.md`, `0010-contrato-magazine-json-extendido.md`,
  `0011-fuente-synopsis-regeneracion-campo.md`.
- `spec/features/001-synopsis/spec.md` — contrato completo de `synopsis`.
