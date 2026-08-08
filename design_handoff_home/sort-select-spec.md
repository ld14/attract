# Especificación: control ORDEN / SELECCIÓN — Pegasus Home

## Concepto
Un único control de dos botones (más un tercer botón contextual) gobierna cómo se organiza el catálogo. Tiene **dos modos** que comparten los mismos 4 criterios pero les dan un significado distinto:

- **Modo ORDEN** → el criterio define cómo se **reordena** toda la lista de juegos (nunca la reduce).
- **Modo SELECCIÓN** → el criterio define un **filtro puntual**: se elige un valor exacto (una letra o un año) y la lista se reduce solo a esos juegos.

## Los 4 criterios
`LETRA`, `AÑO`, `NOTA`, `JUGADOS` (definidos en ese orden fijo; ciclan en ese orden).

- En modo **ORDEN** están disponibles los 4.
- En modo **SELECCIÓN** solo están disponibles `LETRA` y `AÑO` (NOTA y JUGADOS no tienen "un valor puntual" con sentido para filtrar, así que no se ofrecen en selección — si el usuario estaba en NOTA/JUGADOS y cambia a modo Selección, el criterio cae automáticamente a LETRA).

## Botón 1 — Toggle de modo (ORDEN ⇄ SELECCIÓN)
Botón pill que alterna entre los dos modos. Al cambiar de modo:
- Si pasa a Selección y el criterio actual era NOTA o JUGADOS, el criterio se resetea a LETRA.
- Si pasa a Selección, cualquier filtro anterior se mantiene solo si es compatible; si pasa a Orden, el filtro puntual se limpia (Orden nunca filtra, solo reordena).

## Botón 2 — Selector de criterio (cicla con click)
Un solo botón que muestra el criterio activo (ej. "LETRA") y **cicla al siguiente** en cada click, dentro del set permitido por el modo actual (4 valores en Orden, 2 en Selección).

## Botón 3 — Contextual, cambia según el criterio Y el modo

### En modo ORDEN:
- Con criterio **LETRA** o **AÑO** → aparece un botón de **dirección** (▲/▼) que invierte el sentido del ordenamiento:
  - LETRA: ▲ = A→Z, ▼ = Z→A.
  - AÑO: ▲ = año menor primero, ▼ = año mayor primero.
- Con criterio **NOTA** o **JUGADOS** → no hay botón de dirección (siempre ordenan de mejor/mayor a peor/menor, sentido fijo, un solo orden tiene sentido de producto).

### En modo SELECCIÓN:
- Con cualquier criterio (LETRA o AÑO) → aparece un botón de **valor** que muestra el valor elegido actualmente o "—" si no hay ninguno elegido. Al clickearlo abre un **popover** con una grilla de opciones:
  - Si el criterio es LETRA: grilla de las 26 letras A-Z.
  - Si el criterio es AÑO: grilla de años, **generada como rango continuo desde 1978 hasta el año más reciente presente en el catálogo** (no solo los años que tienen juegos — todos los años del rango, aunque alguno quede sin resultados al elegirlo).
  - Al clickear una opción de la grilla: se fija como filtro exacto, el popover se cierra, y la vista salta a los estantes con el catálogo ya filtrado a esa letra/año puntual.

## Filtro activo
Cuando hay un filtro por selección activo, aparece un chip adicional "✕ LETRA C" o "✕ AÑO 1992" al lado del control. Clickearlo limpia el filtro (vuelve a mostrar todo el catálogo, sin tocar el modo/criterio actual).

## Efecto sobre el catálogo (estante "CATÁLOGO")
- En modo Orden: el estante "CATÁLOGO" muestra **todos** los juegos del pool activo (según tab Todos/Favoritos), ordenados por el criterio+dirección actual.
- En modo Selección con filtro activo: el estante "CATÁLOGO" muestra **solo** los juegos que matchean el valor exacto elegido (misma letra inicial del título, o mismo año de lanzamiento).
- En modo Selección sin filtro activo (recién cambiado de modo, nada elegido todavía): se comporta como si no hubiera filtro — se ve todo el catálogo sin ordenar por ese criterio (o con el último orden vigente), a la espera de que el usuario elija un valor en el popover.
- El título del estante refleja el filtro activo cuando corresponde, ej. "CATÁLOGO · LETRA C".

## Reseteo de navegación
Cada vez que se aplica un nuevo filtro por selección (pickLetter/pickYear), el foco de navegación salta automáticamente a la región de estantes, estante 0, columna 0 — para que el usuario vea el resultado inmediatamente sin tener que navegar manualmente hasta ahí.

## Atajo de teclado/joystick
- **`X`** = equivalente al click en el Botón 2 (cicla el criterio dentro del set permitido por el modo actual).
- No hay atajo dedicado para alternar modo o abrir el popover de valor — solo accesibles por click/mando apuntando al botón (foco direccional + Enter/A también los activa, como cualquier botón enfocable).

## Tabla resumen de combinaciones

| Modo | Criterio | Botón 3 | Efecto |
|---|---|---|---|
| Orden | Letra | Dirección ▲/▼ | Reordena todo A→Z o Z→A |
| Orden | Año | Dirección ▲/▼ | Reordena todo por año, asc/desc |
| Orden | Nota | — | Reordena todo por nota, mejor primero |
| Orden | Jugados | — | Reordena todo por partidas jugadas, más jugado primero |
| Selección | Letra | Valor (popover A-Z) | Filtra a juegos cuyo título empieza con esa letra |
| Selección | Año | Valor (popover 1978→actual) | Filtra a juegos lanzados exactamente ese año |

## Nota de implementación en QML
Esto es estado de UI puro (modo, criterio, dirección, filtro), separable en un objeto/`QtObject` reusable (ej. `CatalogSortState`). El `GridView`/`ListView` de "CATÁLOGO" debe recalcular su `model` (filtrado + ordenado) reactivamente cuando cambie cualquiera de estas 4 propiedades — recomendado usar un `SortFilterProxyModel` (KirigamiAddons o implementación propia) sobre el modelo base de juegos, en vez de reconstruir arrays a mano en cada cambio.
