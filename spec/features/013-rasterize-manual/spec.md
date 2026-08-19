# 013 · `attract rasterize` — el PDF del manual a páginas

**Estado:** borrador

## Qué hace

Convierte el PDF declarado en `manual.file` a las páginas que consume el visor
de documentos, y deja el `data.json` apuntando a ellas.

```
attract rasterize <set> [ruta] [--dpi 150] [--force]

media/<set>/_manual/manual.pdf  →  p001.png, p002.png, …
data.json → manual.pages: ["p001.png", "p002.png", …]
```

Recibe: el `<set>` de un juego cuyo `data.json` declara `manual.file`.
Produce: una imagen por página en `media/<set>/_manual/`, y la clave
`manual.pages` escrita en el `data.json` de ese juego.

Con esto el manual se lee **adentro de Pegasus**, en el visor que ya existe
desde la feature 006. No hay UI nueva: `manual.pages[]` es el contrato de
siempre ([`ADR-0014`](../../decisions/0014-manual-digitalizado.md)).

**Fuera de su responsabilidad:** dibujar nada, tocar el theme, y producir el PDF
de origen — escanear sigue siendo trabajo humano
([`ADR-0009`](../../decisions/0009-frontera-produccion-consumo-revistas.md)).

## Por qué

La feature [012](../012-manual-pdf/spec.md) abre el PDF con la app del sistema,
y la medición contra Pegasus real dejó un coste que el theme no puede pagar: el
visor abre por delante y **Pegasus pierde el foco**, sin API para recuperarlo.
En el gabinete, que es solo joystick, es un viaje de ida.

Rasterizar es lo único que hace que el manual **nunca** tenga que salir de
Pegasus. Y hoy no pasa porque convertir 200 páginas a mano es suficiente
fricción como para no hacerlo nunca — lo que rompe la regla de
[`ADR-0001`](../../decisions/0001-transporte-datos-ricos.md): enriquecer un juego
tiene que costar lo mismo que agregarle una carátula.

El porqué de PyMuPDF y las alternativas descartadas están en
[`ADR-0022`](../../decisions/0022-rasterizar-pdf-a-paginas.md).

## Criterios de aceptación

- [ ] Dado un juego con `manual.file` y un PDF de N páginas, cuando se corre
      `attract rasterize <set>`, entonces existen N imágenes `p001…pNNN` en
      `media/<set>/_manual/` y `manual.pages` las lista **en orden**.
- [ ] Los nombres llevan **ceros a la izquierda** con el ancho que haga falta,
      para que el orden alfabético sea el orden real (ADR-0007).
- [ ] `manual.file` **sigue estando** después de correr el comando: el PDF no se
      borra y 012 sigue funcionando como fallback.
- [ ] El comando toca **solo** `manual.pages`. `accent`, `accent2`, `mags`,
      `cheats` y `review` quedan byte por byte como estaban.
- [ ] Es idempotente: correrlo dos veces seguidas deja el mismo `data.json` y
      las mismas imágenes.
- [ ] Dado un `_manual/` que ya tiene páginas, sin `--force` el comando **no
      pisa nada** y lo dice; con `--force` regenera.
- [ ] Dado un juego sin `manual.file`, el comando falla con un mensaje que
      explica qué falta, no con un traceback.
- [ ] Dado un PDF corrupto o ilegible, el comando falla con mensaje explícito y
      **no deja el `data.json` a medias** ni páginas sueltas de una corrida rota.
- [ ] Sin PyMuPDF instalado, el mensaje dice `pip install pymupdf`; y
      `attract doctor`, `attract synopsis` y `attract ingest` siguen corriendo
      **sin instalar nada** (ADR-0012, ADR-0022).
- [ ] Después de rasterizar, `attract doctor` da verde sobre ese juego: las
      páginas declaradas existen y el `file` sigue siendo válido.
- [ ] `--dpi` cambia la resolución de salida y su default es 150.

## Fuera de alcance

- **Rasterizar revistas.** `magazine.json` lo produce un humano y ATTRACT no es
  su dueño (ADR-0009). Esto es solo para manuales, que sí pertenecen a un juego.
- **Correrlo solo.** Nadie rasteriza automáticamente al detectar un PDF; es un
  comando explícito. Un juego con `file` y sin `pages` es un estado válido.
- **OCR, texto seleccionable, miniaturas aparte.** Las páginas son imágenes
  planas; para el texto original está el PDF, que es justamente lo que 012 abre.
- **JPEG y el patrón `p###.png` + `count`.** Son las salidas si el peso en disco
  molesta (ADR-0022 §Qué habría que revisar), no parte de esto.
- **Instalar PyMuPDF por vos.** `make setup` no la instala, igual que con `mcp`.
