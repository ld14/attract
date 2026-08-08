# 009 · Librería con estantes — Spec

**Estado:** borrador

## Qué hace

Reemplaza el rail único de `screens/LibraryScreen.qml` por la pantalla
**Browse** del handoff `design_handoff_home/`: barra superior con dos
pestañas reales (TODOS / FAVORITOS), hero del juego enfocado, y un **stack
vertical de estantes** — CONTINUAR JUGANDO, MÁS JUGADOS, hasta dos géneros,
y CATÁLOGO — sobre el catálogo completo, con orden y filtro por
letra/año/nota/jugados.

Suma dos piezas compartidas que el resto del theme va a reusar: el dueño
único del catálogo (pool, orden, filtro) y el traductor de botones
A/B/X/Y/direccionales.

**No incluye** la pantalla de Buscar (feature `010`) ni el selector de
ediciones del detalle (feature `011`).

## Por qué

Hoy la librería es un `ListView` plano sobre `api.allGames`, con pestañas
decorativas que no filtran nada (`LibraryScreen.qml:9-11`) y sin ninguna
forma de ordenar ni de saltar dentro del catálogo. Con la librería real del
autor —1200+ juegos— recorrer de a una tarjeta con el joystick no es
navegación, es una cinta transportadora.

El handoff resuelve exactamente eso, y su lectura completa (incluido lo que
el prototipo hace y el README no dice) está en el plan de sesión aprobado el
2026-08-05.

## Criterios de aceptación

- [ ] Dado un catálogo con juegos jugados, cuando se abre la librería,
      entonces aparece el estante CONTINUAR JUGANDO y **no** aparece si
      ningún juego tiene `playCount > 0`.
- [ ] Dado el foco en un estante, cuando se aprieta ▼, entonces baja al
      estante siguiente conservando una columna válida (nunca un índice
      fuera de rango del estante nuevo).
- [ ] Dado el foco en el primer estante, cuando se aprieta ▲, entonces el
      foco vuelve a la barra superior.
- [ ] Dado `X`, entonces abre el panel de orden, se recorre entero con las
      flechas, `A` confirma y `B` cancela sin dejar filtro aplicado.
- [ ] Dado un filtro de letra activo, entonces el estante dice
      "CATÁLOGO · LETRA C" y su conteo es el real, no una constante.
- [ ] Un juego sin `data.json`, sin carátula y sin año se dibuja igual:
      wash de accent neutro y "Sin Informacion" donde corresponda
      (`CONVENCION.md` §2.3).
- [ ] Recorrer el estante CATÁLOGO de punta a punta con 1200+ juegos no
      instancia más de ~20 tarjetas vivas a la vez.

## Fuera de alcance

- Buscar con teclado en pantalla — feature [010](../010-theme-buscar/spec.md).
- Ediciones/plataformas y `X` = favorito — feature
  [011](../011-theme-ediciones/spec.md); hasta entonces el hero no dice
  "N EDICIONES".
- Escribir `rating:`/`sort-by:` en `metadata.pegasus.txt` desde el pipeline.
  Sin eso, ordenar por NOTA manda todo al final (`rating` vuelve `0.0`) —
  el orden existe y degrada, pero no significa nada todavía.
