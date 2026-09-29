# 026 · Selector de plataforma

**Estado:** en curso

## Qué hace

Pantalla previa a Home. Presenta las plataformas **de una en una** a pantalla
completa (carrusel con `←`/`→`): nombre, conteo de juegos, logo, emblema y un
video de gameplay aleatorio de esa plataforma por detrás de todo. Al aceptar,
abre **Home** (el de siempre: estantes, orden, filas) filtrado a esa
plataforma. La primera entrada es `TODAS`: Home sin filtro, como hoy.

Recibe las colecciones que ya carga `core/Catalog.qml` y, por plataforma, los
assets opcionales de `library/<coleccion>/_platform/` (ADR-0035). Produce la
plataforma elegida como filtro del catálogo.

Diseño de referencia: `Diseños/design_handoff_platform_select/` (medidas,
colores, capas). Su grilla de 7 columnas **no** se implementa: el catálogo es
Home.

## Por qué

Con varios sistemas en el gabinete, "quiero jugar algo de DOS" obliga hoy a
recorrer estantes de todo lo demás. El selector hace de la plataforma el primer
corte, y da un lugar al video a nivel plataforma reusando `assets.video` (017).

## Criterios de aceptación

- [ ] Con N colecciones que tienen al menos un juego, el carrusel tiene N+1 entradas y el foco arranca en `TODAS`.
- [ ] `→` en la última vuelve a la primera y `←` en la primera va a la última; `X` salta a una al azar distinta de la actual.
- [ ] Aceptar una plataforma abre Home con **solo** juegos de esa colección, en
      todos los estantes y conteos; en la barra, una pill `FILTRO · <AB>`.
- [ ] Aceptar `TODAS` abre Home idéntico al actual, con pill `SIN FILTRO`.
- [ ] En Home, activar la pill de la barra (foco + `A`, o click) vuelve al selector con
      la **misma** plataforma enfocada. `B` en Home hace lo de siempre (sube a la barra).
- [ ] `B` en el selector no lo toma el theme (queda para Pegasus), y la leyenda no lo nombra (`◄ ►`, `↵`, `X`, `S`).
- [ ] Buscar (023) sigue recorriendo toda la librería, con o sin filtro.
- [ ] Sin `logo.png`, `emblema.png`, `data.json` ni videos, no queda espacio
      reservado para el logo ni un panel de video vacío.
- [ ] Un `data.json` ausente o corrupto da el acento neutro y no rompe nada.
- [ ] Con `emblema.png`, `emblema_01.png`, `emblema_02.png`… cada visita a la
      plataforma muestra uno al azar, distinto del anterior si hay otro.
- [ ] El nombre de la plataforma no cambia de posición entre una con video y una sin video.
- [ ] El video suena bajo y `S` lo silencia, con el mismo estado que Home:
      silenciar en una pantalla vale en la otra. Muestra como máximo 1 minuto de cada juego y
      pasa a otro al azar al cumplirlo o al terminar el clip, lo que llegue antes;
      nunca queda por encima de textos, flechas, barra ni leyenda.
- [ ] El filtro de tubo (CRT) sigue por encima de todo.

## Fuera de alcance

- Estado vacío de una plataforma sin juegos: no hay caso, las plataformas salen
  de los juegos cargados, no de `api.collections` (tasks §1).
- Filtrar por año, letra o género: orden de Home ([009](../009-theme-estantes/spec.md)) y búsqueda ([023](../023-busqueda-global/spec.md)).
- Controles de transporte del video (pausa, adelantar): es ambiental, igual que
  en 017. Lo único que se controla es el silencio, con `S`.
- Ingestar logos y emblemas automáticamente: se cargan a mano en `library/`.
