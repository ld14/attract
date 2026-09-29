# Matriz de la Etapa B — piloto de datos

Estado por campo, para cada uno de los 6 expedientes de
`spec/features/027-como-se-juega/piloto/`. Valores posibles: **extraído
automáticamente** (un comando/lectura de archivo lo trae solo, sin criterio
humano), **documentado** (razonado o declarado a partir de fuentes escritas,
sin correrlo en el gabinete), **comprobado en el gabinete** (probado a mano
en esta máquina), **pendiente** (falta trabajo, casi siempre la Etapa F física),
**en conflicto** (dos fuentes se contradicen).

| Campo | SFA2 | Pacman | The Simpsons | Shuffleshot | Prehistorik | Oh No! Lemmings |
|---|---|---|---|---|---|---|
| Identidad | extraído auto. | extraído auto. | extraído auto. | extraído auto. | documentado | documentado |
| Objetivo | documentado | documentado¹ | documentado | **en conflicto**² | documentado | documentado |
| Controles originales (capa 1) | extraído auto. | **en conflicto**¹ | extraído auto. | extraído auto. | pendiente³ | documentado |
| Entradas técnicas (capa 2) | extraído auto. | extraído auto. | extraído auto. | extraído auto. | extraído auto. | extraído auto. |
| Mapeo local (capa 3) | pendiente | pendiente | extraído auto.⁴ | pendiente⁵ | documentado⁶ | documentado⁶ |
| Inicio | documentado | documentado | comprobado en el gabinete⁷ | documentado | comprobado en el gabinete⁸ | comprobado en el gabinete⁸ |
| Salida | extraído auto.⁹ | extraído auto.⁹ | extraído auto.⁹ | extraído auto.⁹ | documentado¹⁰ | documentado¹⁰ |
| Multijugador | extraído auto.¹¹ | extraído auto.¹¹ | extraído auto.¹¹ | extraído auto.¹¹ | extraído auto. | extraído auto. |
| Periféricos | documentado | documentado | documentado | **documentado (hallazgo clave)**¹² | documentado | documentado |

**Notas:**

1. Pacman: el `summary` afirma un botón de acción que no existe. El dato de
   controles en sí (0 botones) viene limpio de `-listxml` + `cabinet` de
   COINDOOR; el conflicto es específicamente contra el texto de `summary`.
2. Shuffleshot: el `summary` completo describe un juego distinto
   ("Shuffleship", nave espacial). `genre` y `cabinet` sí son correctos y
   coinciden entre sí y con `-listxml`.
3. Prehistorik: sin fuente equivalente a ArcadeDB para DOS en este proyecto;
   el mapeo de teclas del juego (salto, disparo) no se verificó.
4. The Simpsons: `simpsons.cfg` **existe y se leyó** (extraído
   automáticamente, no documentado a mano) — pero es un remapeo del panel
   **provisorio**, no una posición física medida y verificada del panel
   final. La *existencia* del remapeo es un dato duro; la *posición física*
   sigue pendiente de la Etapa F.
5. Shuffleshot: "pendiente" acá significa "requisito ausente", no "falta
   medir" — el gabinete declarado (§3.2) no tiene trackball ni la va a
   tener. No hay nada que la Etapa F vaya a resolver para este juego en
   particular.
6. Prehistorik / Lemmings: no hay panel que mapear (100% teclado o 100%
   mouse, ambos fijos en el gabinete por decisión ya tomada, §3.2) — "sin
   trabajo pendiente" es en sí un hecho documentado, no una medición.
7. The Simpsons: `COIN1`/`START1` remapeados a botones del panel de 8 según
   `simpsons.cfg`, un archivo que MAME reescribió tras una partida real
   jugada en este gabinete — es la evidencia más "de campo" de los 6.
8. Prehistorik / Lemmings: lanzamiento directo verificado al correr el
   experimento A1 (Civilization) y, para Lemmings, en el flujo normal de
   Pegasus — ningún paso manual de inicio en ninguno de los dos.
9. Salida en arcade: `confirm_quit 0` es una lectura directa de `mame.ini`,
   no una prueba física de apretar Esc en cada juego.
10. Salida en DOS: Ctrl+F9 se comprobó en el gabinete (A2) pero no en estos
    dos juegos puntuales — se extiende por analogía de categoría de config
    (sin `mapperfile`, `joysticktype = disabled`). Ver el detalle en cada
    expediente.
11. Multijugador arcade: el número de jugadores es un dato duro de
    `-listxml`; que el jugador 2 (o 3-4) funcione en la práctica **no** está
    comprobado — el panel de hoy solo tiene el stick del jugador 1.
12. Shuffleshot: el hallazgo de "periférico no disponible" es el más
    importante de toda la muestra para probar ese criterio de aceptación de
    la spec — por eso se marca aparte aunque la categoría de estado sea la
    misma que las demás filas "documentado".

## Tiempo por expediente

**Aviso:** esto no se midió con cronómetro — es una estimación de esfuerzo
relativo hecha por quien escribió los expedientes (Claude), en la misma
sesión de trabajo del 2026-09-28. Sirve para comparar entre sí, no como dato
duro para planificar Etapa D.

| Expediente | Esfuerzo relativo | Por qué |
|---|---|---|
| SFA2 | Medio | Primer juego: incluyó armar el patrón de consulta (`-listxml` + `game.json` de COINDOOR) que los demás reutilizaron |
| Pacman | Medio-alto | El cruce que encontró el conflicto de la sinopsis llevó una vuelta extra de verificación |
| The Simpsons | Alto | Fue el único con `.cfg` real para leer e interpretar (remapeo de 4 entradas) |
| Shuffleshot | Alto | Conflicto de sinopsis más grave (juego distinto, no solo un dato de más) más la calificación de "periférico ausente" contra el perfil del gabinete |
| Prehistorik | Bajo | Sin `-listxml` equivalente para DOS; casi todo salió de `dosbox.conf` y `metadata.pegasus.txt` |
| Oh No! More Lemmings | Bajo | Igual que Prehistorik, más la aclaración de por qué no se usó Monkey Island (ya decidida de antes) |

**Lectura:** los tres arcades con `cabinet.button_list` poblado (SFA2,
Simpsons, Shuffleshot) llevaron más esfuerzo que Pacman (sin botones, tabla
vacía) y que los dos DOS (sin fuente automática de controles). Es exactamente
la señal que necesita la conclusión: automatizar el cruce `-listxml` +
`cabinet` para arcade paga bien; para DOS, hoy no hay con qué automatizar el
mapeo de teclas del juego.
