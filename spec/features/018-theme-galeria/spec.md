# 018 · Galería de imágenes y videos del juego

**Estado:** implementada (`f332a76`). Falta la verificación visual contra
Pegasus real — ver `tasks.md` §Verificación.

_El diseño de referencia está en [`docs/gallery-spec.md`](../../../docs/gallery-spec.md),
escrito contra un prototipo HTML que ya se corrió. Las cuatro trampas que ese
prototipo destapó están citadas por sección en `plan.md` §Riesgos._

## Qué hace

Agrega una **galería multimedia por juego** a la pantalla de detalle. El acceso
es una tarjeta más de CONTENIDO EXTRA, junto a Hacks y Manual digitalizado; el
contenido vive en un **modal a pantalla completa** con visor, flechas, contador
y riel de miniaturas.

La galería **se compone de dos fuentes** ([`ADR-0030`](../../decisions/0030-contrato-gallery-data-json.md)):
los **assets nativos** que Pegasus ya descubrió y las **piezas curadas** que
COINDOOR deja en `media/<set>/_gallery/` y declara en `gallery` dentro de
`data.json`. El orden es fijo:

```
video → screenshot → gallery[] (orden del array) → boxFront → poster → marquee
```

Un asset ausente se saltea. `logo` queda afuera: es un recurso de interfaz, no
contenido. El tipo de cada pieza sale de la **extensión** del archivo.

No es una tira inline en el detalle: se probó en el prototipo y ensucia la
composición. El acceso es un botón, el contenido está adentro.

## Por qué

Hoy el detalle muestra **un solo** medio del juego: el video de gameplay del
panel de carátula ([`screens/VideoPanel.qml`](../../../themes/attract/screens/VideoPanel.qml),
feature 006). Todo lo demás que el juego ya tiene —la captura, el marquee, la
carátula— solo se ve recortado como fondo de una tarjeta, o no se ve.

Y hay contenido **que ya está en el disco y nadie muestra**: COINDOOR emite
`media/_gallery/` desde hace al menos un paquete (`final-fight.coindoor.zip`,
ocho piezas rotuladas a mano: panel de control, placa PCB, gabinete),
`attract import` **ya lo instala** (`instalar.py:155` copia el subárbol `media/`
entero) y no hay una sola pantalla que lo lea. Esta feature es la que lo saca a
la luz.

Además `gallery` acepta piezas **declaradas sin archivo** (`file: ""`), que se
dibujan como un hueco reconocible. Es el mismo camino de render que necesita un
asset nativo que existe pero **no carga** (caso medido en
[`ui/CoverImage.qml`](../../../themes/attract/ui/CoverImage.qml): un juego de
Steam devuelve `boxFront` como URL remota y el gabinete está offline).

## Criterios de aceptación

### La tarjeta

- [ ] Dado **Final Fight** (5 assets nativos + 8 piezas curadas = 13), cuando se
      abre el detalle, entonces la tarjeta "Galería" aparece **primera** en
      CONTENIDO EXTRA y dice `"13 piezas"`.
- [ ] Dado **Donkey Kong** (5 nativos, sin `_gallery/`), entonces dice
      `"5 piezas"`. Dado **Metal Slug** (sin `marquee`), entonces dice
      `"4 piezas"` — un asset ausente se saltea, no deja hueco. Una galería
      tiene de **1 a N** piezas: el subtítulo no asume ningún largo.
- [ ] Dado un juego con **una sola** pieza, entonces dice `"1 pieza"`, no
      `"1 piezas"`.
- [ ] Dado el desglose por tipo, que es el **primer** nivel de `_acortar()`
      (`"1 video  ·  1 imagen"`), cuando entra en el ancho de la tarjeta,
      entonces el plural y el acento son correctos (1/N videos, 1/N
      **imágenes**); cuando no entra, cae a `"N piezas"` sin romper la tarjeta.
      Con las tarjetas a 200px el desglose entra solo en galerías muy chicas:
      es un lujo que aparece cuando cabe, no el caso normal. Ver `plan.md`
      §Decisiones.
- [ ] Dado un juego **sin ningún** asset ni galería, cuando se abre el detalle,
      entonces la tarjeta **sigue estando**, apagada y con `"No Disponible"`, y
      no se abre al aceptarla — igual que Hacks y Manual hoy (CONVENCION #2.3).
      Esto **contradice a propósito** §1 del diseño de referencia, que la pedía
      condicional; ver `plan.md` §Decisiones.
- [ ] Dado el detalle abierto, cuando se lee la barra superior, entonces el
      botón de volver dice **"◄ BIBLIOTECA"** y no "◄ GALERÍA" — la colisión de
      nombres de §1 se resuelve renombrando el botón, no la tarjeta.

### El foco (§5 — la fuente de bug más probable)

- [ ] Dado el detalle, cuando se recorre con ◄ ►, entonces el orden es
      `[JUGAR] → [video] → [carrusel] → [Galería] → [Hacks] → [Manual]`.
- [ ] Dado el foco en **Hacks**, cuando se acepta, entonces se abre **Hacks** —
      no la galería. Idem Manual. Es el guardarraíl explícito contra el corrimiento
      de índices al insertar una tarjeta nueva en el ciclo.

### El modal

- [ ] Dado el modal abierto, cuando se aprieta ◄ ►, entonces **cambia de pieza
      con wrap** (de la última a la primera) y la sección del detalle de abajo
      **no se mueve**.
- [ ] Dado el modal abierto, cuando se lee la barra de leyenda, entonces dice
      exactamente `◄ ► Imagen / video   B / Esc Cerrar` — y **no** los atajos del
      detalle (`A/⏎ Abrir`, `START Jugar`), que ahí no hacen nada (§6).
- [ ] Dado el modal abierto, cuando se mira el riel de miniaturas, entonces
      **ninguna miniatura queda pintada por la barra de leyenda** (§3).
- [ ] Dado un juego con **una sola** pieza, cuando se abre el modal, entonces
      las flechas ‹ › **no se dibujan**.
- [ ] Dado el modal abierto, cuando se aprieta `B` / `Esc`, entonces se cierra y
      el foco vuelve al detalle con la tarjeta de galería todavía enfocada.

### Las piezas

- [ ] Dada una pieza `img` con archivo, cuando se muestra, entonces se ve
      completa y sin recorte.
- [ ] Dada una pieza `vid` con archivo, cuando se muestra, entonces reproduce
      con **controles visibles** (a diferencia del preview ambiente del hero,
      acá el usuario controla reproducción y volumen).
- [ ] Dada una pieza con `file: ""`, cuando se muestra, entonces se dibuja el
      placeholder rayado 16:9 y **la consola no reporta ni un error de carga de
      recurso** (§7 — el bug del prototipo).
- [ ] Dado un asset nativo que **existe pero no carga** (el caso remoto de
      `ui/CoverImage.qml`), cuando le toca el turno, entonces cae al mismo
      placeholder y la galería sigue navegable — no queda un cuadro negro ni se
      corta el recorrido.
- [ ] Dadas las galerías de **dos juegos distintos, abiertas una después de la
      otra**, cuando se llega a la pieza de video de cada una, entonces **las dos
      muestran imagen** — ningún panel vacío por reusar el player (ADR-0029). Se
      verifica cruzando juegos y no con dos videos del mismo juego porque ese
      dato no existe: ningún paquete trae más de un video y `_gallery/` no trae
      ninguno (ADR-0030 §Contexto).

### El validador

- [ ] Dado un `data.json` con `gallery` mal formado (no lista, ítem que no es
      objeto, `file` que no es string, `label` ausente o vacío), cuando corre
      `attract doctor`, entonces **falla con error explícito** nombrando el
      índice (`gallery[2]`).
- [ ] Dada una pieza cuyo `file` **no existe** en `_gallery/`, cuando corre
      `attract doctor`, entonces **falla con error**.
- [ ] Dada una pieza con una extensión fuera de las listas conocidas
      (`.png/.jpg/.jpeg/.webp` y `.mp4/.webm/.mov`), cuando corre
      `attract doctor`, entonces **falla con error** — el theme no puede
      dibujarla y adivinar sería peor.
- [ ] Dada una pieza con `file: ""`, cuando corre `attract doctor`, entonces sale
      **AVISO, no error**: es un estado declarado válido, no un archivo roto.
- [ ] Dado `files_install/final-fight.coindoor.zip` instalado con
      `attract import`, cuando corre `attract doctor` sobre la librería, entonces
      **pasa sin errores** — el contrato validado es el que COINDOOR ya emite,
      no uno nuevo.

## Fuera de alcance

- **Comando de CLI para armar la galería.** `gallery` se escribe a mano en
  `data.json`, como `manual` antes de `attract rasterize`. Si aparece un flujo
  repetitivo, ahí se evalúa un comando.
- **Zoom y paneo dentro del modal.** Eso es del visor de documentos
  ([`overlays/DocumentViewer.qml`](../../../themes/attract/overlays/DocumentViewer.qml),
  feature 006), que existe para leer texto escaneado. Una captura de pantalla se
  mira entera.
- **Cambiar COINDOOR o el contrato del paquete.** El contrato de `gallery` es el
  que el productor **ya emite**; esta feature lo consume y lo valida, no lo
  redefine. Lo único que se suma del lado de ATTRACT es documentarlo en
  ADR-0030, porque [`ADR-0027`](../../decisions/0027-contrato-paquete-import-coindoor.md)
  no lo nombraba.
- **Tocar `attract import`.** Ya instala `_gallery/` correctamente
  (`instalar.py:155`). No hay nada que agregarle. Ojo: **su comportamiento sí
  cambia**, sin diff — el preflight comparte `doctor.chk_data_contrato`
  (`instalar.py:109-124`), así que a partir de esta feature un paquete con
  `gallery` inválida se rechaza y se revierte entero. Es lo deseado; queda
  anotado porque no se ve en ningún archivo modificado.
- **Deduplicar piezas repetidas.** Si `_gallery/` trae la misma imagen que un
  asset nativo, aparece dos veces. Comparar bytes por pieza al abrir la ficha no
  se paga; ver ADR-0030 §Coste asumido.
- **Tocar el preview de gameplay del hero** (feature 017) o el panel de carátula
  del detalle (feature 006). La galería es contenido nuevo, no reemplaza nada.
