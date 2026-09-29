# 028 · Cómo se juega — theme

**Estado:** aprobada — depende de que
[027](../027-como-se-juega/spec.md) tenga los datos que esta feature lee.
Nace de partir la spec 027 original en datos (027) y theme (028), decisión
del autor del 2026-09-28, mismo patrón que el manual (012/013/014).

## Qué hace

Suma "Cómo se juega" como **primera** tarjeta de "Contenido extra" del detalle.
Las cuatro (Cómo se juega, Galería, Hacks, Manual) van en **una fila de
tarjetas compactas**, y debajo una línea con el detalle de la enfocada:
conteos, o "No Disponible".

La tarjeta abre un panel sobre el detalle con título, diagrama de controles,
objetivo, primeros pasos (hasta 3), reglas esenciales (hasta 3), cómo salir
(una instrucción), JUGAR y VOLVER, más accesos a Hacks y al Manual. Al Manual
se accede solo si tiene páginas. Un juego sin guía propia muestra la ayuda
general del gabinete y de su emulador (crédito, start, salir), con el aviso
"Sin guía específica para este juego".

Lee, sin escribir nunca, los tres archivos que produce
[027](../027-como-se-juega/spec.md): el bloque `guia` de `data.json`, el
perfil físico del gabinete y el artefacto de correspondencia. Restaura el
contexto completo al volver de JUGAR según
[ADR-0038](../../decisions/0038-restaurar-contexto-al-volver-de-jugar.md).

## Por qué

Una persona sin experiencia frente al gabinete no sabe qué hacer, qué apretar,
cómo empezar ni cómo salir. La guía se lo dice en la ficha del juego, antes de
jugar y sin obligar a leerla: JUGAR sigue lanzando directo.

## Criterios de aceptación

- [ ] A 1280×720, las cuatro tarjetas entran en una fila sin pisar la columna
      derecha; la sinopsis pierde como mucho el alto de la línea de detalle.
- [ ] La línea de detalle muestra los conteos de la tarjeta enfocada, o "No
      Disponible".
- [ ] Orden de foco: JUGAR → video → carrusel → Cómo se juega → Galería →
      Hacks → Manual → Favoritos.
- [ ] La tarjeta siempre abre. Sin guía propia muestra la ayuda general y el
      aviso "Sin guía específica para este juego".
- [ ] Cerrar la guía devuelve el foco a su tarjeta. Cerrar Hacks o Manual
      abiertos desde la guía vuelve a la guía. La tecla que cierra no dispara
      nada en la pantalla de abajo.
- [ ] JUGAR desde la guía lanza el juego; al volver, según
      [ADR-0038](../../decisions/0038-restaurar-contexto-al-volver-de-jugar.md),
      la plataforma, el juego, el detalle y la guía de ese juego están
      restaurados tal como estaban.
- [ ] Un botón físico se señala solo si el artefacto de correspondencia
      (027) lo trae como **verificado**. Si no, se muestra la entrada lógica
      ("botón 2 del jugador 1") y no hay diagrama que sugiera otra cosa.
- [ ] "Sin uso" y "acción desconocida" se ven distintos.
- [ ] Un juego DOS indica teclado o mouse, y que la palanca no funciona
      cuando la configuración efectiva (leída por 027) la deshabilita.
- [ ] "Cómo salir" muestra la tecla efectiva para ese juego, tal como la
      calculó 027 — no una constante fija del emulador en el theme.
- [ ] Un periférico que el gabinete no tiene (según el perfil de 027) se
      muestra como requisito, no como un botón.
- [ ] Una guía ausente, parcial o con un JSON roto no rompe el theme y JUGAR
      sigue accesible — mismo criterio de degradación que `GameData.qml` ya
      aplica al resto de `data.json`.
- [ ] El diagrama se dibuja en QML solo con `Rectangle`, `Text` y
      `Repeater` — sin `QtQuick.Shapes` ni ningún `import` nuevo.
- [ ] Sin dependencias nuevas, sin assets nuevos, sin excepciones nuevas a la
      regla de fixtures de 0 bytes.

## Fuera de alcance

- El contrato de datos, la validación de `doctor`, el perfil físico y el
  comando de correspondencia: eso es
  [027-como-se-juega](../027-como-se-juega/spec.md).
- Ayuda durante la partida, dentro del emulador.
- Remapear controles desde la guía.
- Guías de estrategia, o repetir lo que ya está en Hacks
  ([007](../007-theme-trucos/spec.md)).
- Unificar el vocabulario de botones con los trucos: en la v1 son
  independientes.
- Habilitar el joystick en DOSBox, o una combinación de salida en el panel.
- Juegos que usan los flippers: están en el perfil, pero ningún juego de la
  v1 los necesita.
- Editar la guía dentro de ATTRACT: se corrige en COINDOOR
  ([016](../016-import-coindoor/spec.md)).
- La prueba con una persona nueva: no hay quién, queda como limitación
  declarada.
