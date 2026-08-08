// EXPERIMENTO — ¿existen de verdad X e Y, y qué tecla física los dispara?
//
// Contexto: el handoff de design_handoff_home/ apoya DOS funciones enteras
// sobre botones que el theme todavía no usó nunca:
//
//     X  ->  panel de orden/selección (el único acceso al salto por letra)
//     Y  ->  abrir Buscar
//
// El theme de producción hoy solo usa api.keys.isAccept e isCancel (A y B),
// verificados desde el Bloque 3. isDetails e isFilters aparecen en la
// documentación oficial, pero acá ya sabemos que la documentación de Pegasus
// no es evidencia: game.extra "es un string" según la doc y es una lista
// (ADR-0001), y QtGraphicalEffects no está declarado en el build y sin
// embargo existe (docs/plataforma-pegasus.md §1). Se probó en las dos
// direcciones y falló en las dos.
//
// PREDICCIÓN: api.keys expone isAccept / isCancel / isDetails / isFilters /
// isNextPage / isPrevPage / isPageUp / isPageDown, y en teclado por default
// isDetails cae en alguna tecla tipo Shift/Ctrl y isFilters en otra — el
// mapeo real lo decide settings.txt, que vive fuera del repo y que
// attract doctor no puede validar (§4).
//
// LO QUE HAY QUE MEDIR, y por qué no alcanza con "¿existe la función?":
//
//   1. Que la función exista (no tire ReferenceError).
//   2. Que ALGUNA tecla física la haga dar true. Una función que existe y
//      nunca dispara es peor que una que no existe: se descubre en el
//      gabinete, no acá.
//   3. Que NO se superponga con isAccept/isCancel. Si isDetails también da
//      true con Enter, el panel de orden se abriría al abrir un juego.
//   4. Qué trae event.text en cada caso. La pantalla de Buscar escribe con
//      el teclado físico (typeahead), así que necesita distinguir "esto es
//      texto" de "esto es un botón mapeado" — y el orden de las preguntas
//      en Keys.onPressed depende de esta medición.
//
// SI ESTO FALLA: la fase 009 no arranca como está planificada. El plan B es
// mover el panel de orden a isNextPage/isPrevPage (gatillos) y Buscar a una
// entrada de la barra superior navegable con flechas. Este experimento
// también mide esos dos, para no tener que volver a abrir Pegasus.
//
// Cómo se corre: cp themes/experimentos/teclas-xy.qml \
//   "$PEGASUS_THEMES/attract-debug/theme.qml" y elegir ATTRACT Debug.

import QtQuick 2.0

FocusScope {
    id: root
    focus: true
    anchors.fill: parent

    property var lineas: []
    property int total: 0

    Rectangle { anchors.fill: parent; color: "#0d1117" }

    Text {
        anchors { fill: parent; margins: 40 }
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 14
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        text: cabecera() + "\n" + root.lineas.join("\n")
    }

    function cabecera() {
        var out = [];
        out.push("=== EXPERIMENTO TECLAS X / Y ===");
        out.push("");
        out.push("Sin gamepad se prueba con teclado: settings.txt mapea las");
        out.push("mismas acciones (medido 2026-08-05).");
        out.push("");
        out.push("  I     -> deberia prender isDetails   (X del gamepad)");
        out.push("  F     -> deberia prender isFilters   (Y del gamepad)");
        out.push("  Enter -> isAccept        Esc -> isCancel");
        out.push("  A D Q E -> OJO: son prev-page/next-page, no letras libres");
        out.push("");
        out.push("Buscamos: que isDetails e isFilters prendan SOLOS, sin");
        out.push("prender tambien isAccept o isCancel.");
        out.push("");
        out.push("--- que funciones existen en este binario ---");
        for (var i = 0; i < root.predicados.length; i++) {
            var n = root.predicados[i];
            out.push("  api.keys." + n + " : " + existe(n));
        }
        out.push("");
        out.push("--- ultimos " + root.maxEventos + " eventos (" + root.total + " en total) ---");
        return out.join("\n");
    }

    // En minuscula: en QML una PROPIEDAD no puede empezar con mayuscula
    // ("Property names cannot begin with an upper case letter"). En JS si,
    // por eso core/InputTokens.js puede tener `var FLECHAS`.
    readonly property var predicados: [
        "isAccept", "isCancel", "isDetails", "isFilters",
        "isNextPage", "isPrevPage", "isPageUp", "isPageDown"
    ]

    readonly property int maxEventos: 12

    function existe(nombre) {
        // typeof sobre una propiedad ausente da "undefined" sin tirar; sobre
        // una funcion de Qt da "function". No hace falta try/catch.
        return typeof api.keys[nombre] === "function" ? "SI" : "NO";
    }

    // Cuales de los ocho predicados dan true para ESTE evento. Que la lista
    // traiga mas de uno es justamente el hallazgo que buscamos (punto 3).
    function cualesPrenden(event) {
        var prenden = [];
        for (var i = 0; i < root.predicados.length; i++) {
            var n = root.predicados[i];
            if (typeof api.keys[n] !== "function") continue;
            if (api.keys[n](event)) prenden.push(n);
        }
        return prenden.length ? prenden.join(" + ") : "(ninguno)";
    }

    Keys.onPressed: {
        root.total += 1;

        var l = "";
        l += "key=0x" + event.key.toString(16);
        l += "  text=" + JSON.stringify(event.text);
        l += "  mod=" + event.modifiers;
        l += "\n     -> " + cualesPrenden(event);

        var nuevas = root.lineas.slice();
        nuevas.push(l);
        if (nuevas.length > root.maxEventos)
            nuevas = nuevas.slice(nuevas.length - root.maxEventos);
        root.lineas = nuevas;

        // NO se acepta el evento a proposito: si algo mas arriba lo consume,
        // queremos verlo aca igual.
        event.accepted = false;
    }
}

// #RESULTADO OBSERVADO (2026-08-05, Pegasus alpha16-82-gc3462e68, macOS,
// SIN gamepad — se probo con el teclado, que settings.txt mapea a las mismas
// acciones)
//
// LOS OCHO PREDICADOS EXISTEN. Los cuatro que importan disparan, y ninguno se
// superpone con otro: cada tecla prendio UNO solo.
//
//   tecla        key         predicado      boton del gamepad (settings.txt)
//   -----------  ----------  -------------  --------------------------------
//   I            0x49        isDetails      GamepadX
//   F            0x46        isFilters      GamepadY
//   Enter        0x1000004   isAccept       GamepadA
//   Esc          0x1000000   isCancel       GamepadB
//   A            0x41        isPrevPage     GamepadL1
//   D            0x44        isNextPage     GamepadR1
//   Fn+Flecha    0x1000016   isPageUp       GamepadL2
//                0x1000017   isPageDown     GamepadR2
//
// -> LA FASE 009 VA COMO ESTA PLANIFICADA. El panel de orden en X (isDetails)
//    y Buscar en Y (isFilters) tienen botones propios y limpios. El plan B de
//    los gatillos queda sin usar, pero medido y disponible.
//
// TRES HALLAZGOS QUE NO SE BUSCABAN Y CAMBIAN CODIGO:
//
//   1. LAS LETRAS a d q e f i ESTAN TOMADAS. No son teclas libres: disparan
//      isPrevPage / isNextPage / isFilters / isDetails. La pantalla de Buscar
//      escribe con el teclado fisico, asi que ahi hay que preguntar SOLO
//      isCancel y tratar todo lo demas como texto — si pregunta esX/esY, al
//      tipear "diablo" la d y la i se comen el evento.
//
//   2. F1 (key.menu en settings.txt) NO PRENDE NINGUN PREDICADO. api.keys no
//      expone isMenu; la tecla existe para Pegasus y es invisible para el
//      theme. Por eso la ayuda no puede tener un boton propio y entra en el
//      panel de X.
//
//   3. EN macOS LAS FLECHAS COMUNES LLEGAN CON KeypadModifier
//      (mod=536870912 = 0x20000000). Key_Up es 0x1000013 con ese modificador
//      puesto, no con NoModifier. Cualquier comparacion del tipo
//      `event.modifiers === Qt.NoModifier` sobre una flecha falla en el Mac.
//      Se descubrio confundiendo esos eventos con Fn+Flecha, que es otra cosa
//      distinta y si da Key_PageUp/PageDown de verdad.
//
// Y una advertencia sobre este mismo archivo: la ventana de 12 eventos ocultó
// las primeras dos pulsaciones y hubo que repetir la corrida para ver `I`.
// Si se reusa, subir maxEventos antes de correrlo.
