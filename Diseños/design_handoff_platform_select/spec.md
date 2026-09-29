# 025 · Selector de plataforma

**Estado:** borrador

## Qué hace

Pantalla previa a la librería. Presenta las plataformas **de una en una** a
pantalla completa (carrusel con `←`/`→`), cada una con su nombre, su conteo de
ítems, su logo, su imagen emblema y un video de gameplay aleatorio de juegos de
esa plataforma por detrás de todo. Al aceptar, abre el catálogo **filtrado** por
esa plataforma; con cancelar, vuelve al selector.

La primera opción del carrusel es `TODAS`: no filtra nada y el catálogo muestra
la unión de todas las plataformas, con la plataforma de cada juego en su tarjeta.

Recibe: las colecciones de Pegasus (`api.collections`) y, por plataforma, los
assets opcionales de `library/_platforms/<dir>/`. Produce: la plataforma elegida
como filtro del catálogo.

Fuera de su responsabilidad: el detalle del juego, la búsqueda, el orden y los
overlays (ya cubiertos por 005-008), y la ingesta de los assets de plataforma
(se cargan a mano, como el resto del arte de `library/`).

## Por qué

Hoy el catálogo mezcla todas las plataformas en un solo espacio. En un gabinete
con mil juegos y diez sistemas, "quiero jugar algo de SNES" obliga a recorrer
filas de todo lo demás. El selector convierte la plataforma en el primer corte
del recorrido, que es como el usuario del gabinete piensa antes de elegir juego.

Además da un lugar natural al video de gameplay a nivel plataforma, reusando la
fuente (`media/video.mp4`) que ya existe para el hero (feature 017).

## Criterios de aceptación

- [ ] Dado un gabinete con N colecciones, cuando se abre el selector, entonces
      el carrusel tiene N+1 entradas (las N colecciones más `TODAS`) y el foco
      arranca en `TODAS`.
- [ ] Dado el selector, cuando se pulsa `→` en la última plataforma, entonces el
      foco vuelve a la primera (wrap circular); `←` en la primera va a la última.
- [ ] Dada una plataforma con M juegos, cuando se acepta, entonces el catálogo
      muestra únicamente juegos de esa plataforma y la pill de filtro dice
      `FILTRO · <AB>`.
- [ ] Dado `TODAS`, cuando se acepta, entonces el catálogo muestra juegos de más
      de una plataforma, la pill dice `SIN FILTRO` y cada tarjeta muestra su
      propia plataforma en el badge.
- [ ] Dado el catálogo abierto, cuando se cancela, entonces se vuelve al selector
      con la **misma** plataforma enfocada que al entrar.
- [ ] Dada una plataforma cuya ruta está montada y no tiene juegos, cuando se
      acepta, entonces se muestra el estado vacío con la ruta
      `library/<dir>/<carpeta-juego>/` y `make doctor-lib`, y no una grilla vacía.
- [ ] Dada una plataforma sin ningún juego con `media/video.mp4`, cuando se
      enfoca, entonces no se dibuja panel de video y el nombre de la plataforma
      **no** cambia de posición respecto de una plataforma con video.
- [ ] Dada una plataforma sin `logo.png`, cuando se enfoca, entonces la barra
      superior no reserva espacio para el logo ni muestra un hueco.
- [ ] Dado un `data.json` de plataforma ausente o corrupto, cuando se enfoca,
      entonces se usa un acento por defecto y la pantalla se dibuja completa
      (no crashea, no queda a medio pintar).
- [ ] El video reproduce siempre en silencio y en cadena: al terminar un clip
      arranca otro juego al azar de la misma plataforma.
- [ ] El video nunca se dibuja por encima del emblema, los textos, la barra
      superior, las flechas, la leyenda ni el catálogo.

## Fuera de alcance

- Filtrar por año, letra o género — eso es el popover de orden ya existente
  (005-008) y la búsqueda global, feature
  [023-busqueda-global](../023-busqueda-global/spec.md).
- Favoritos como filtro del selector — feature
  [024-favoritos-detalle](../024-favoritos-detalle/spec.md).
- Reproducir audio del video o darle controles: el preview es ambiental, igual
  que en [017-hero-video-preview](../017-hero-video-preview/spec.md).
- Ingestar automáticamente logos y emblemas de plataforma.
