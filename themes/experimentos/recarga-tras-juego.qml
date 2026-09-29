// EXPERIMENTO — ¿Pegasus recarga el theme entero al volver de un juego?
//
// Contexto: la decision 11 de docs/como-se-juega.md dice que al volver de
// JUGAR, la guia de ese juego (feature 027) tiene que aparecer abierta como
// estaba. Si Pegasus RECARGA el theme (el QML se destruye y se crea de
// nuevo), ninguna property normal sobrevive y hace falta api.memory,
// escribiendo una clave justo antes de game.launch() y leyendola al volver.
// Si NO recarga (el QML sigue vivo, solo perdio el foco de la ventana),
// alcanza con una property comun y api.memory no hace falta para esto.
//
// PREDICCION: Pegasus SI recarga el theme entero al volver de un juego — es
// el comportamiento tipico de un frontend que le cede toda la pantalla al
// emulador. Lo que NO se sabe y es lo que importa:
//
//   1. Si de verdad recarga (el contador de Component.onCompleted pasa de 1
//      a 2 despues de UN solo juego jugado), o si solo pierde y recupera el
//      foco de la ventana sin destruir nada.
//   2. Si la clave escrita justo antes de game.launch() sigue estando ahi al
//      volver — es el mecanismo exacto que necesita la decision 11.
//
// SI ESTO FALLA (no recarga): la decision 11 se resuelve mas simple, con una
// property de QML comun en vez de api.memory.
// SI ESTO CONFIRMA que recarga: la guia de la feature 027 escribe en
// api.memory justo antes de cada game.launch(), tal como ya predijo el plan.
//
// CÓMO SE CORRE (lo hace el autor, en el gabinete — necesita Pegasus y un
// juego que arranque; no se puede medir desde acá):
//
//   1. Instalar attract-debug si no está (make theme-debug, o copiar
//      themes/attract-debug a $LOCALAPPDATA/pegasus-frontend/themes/) y
//      copiar este archivo encima de su theme.qml:
//        cp themes/experimentos/recarga-tras-juego.qml \
//           "$LOCALAPPDATA/pegasus-frontend/themes/attract-debug/theme.qml"
//   2. Abrir Pegasus, elegir el theme "ATTRACT Debug" en Configuración.
//   3. Con ARRIBA/ABAJO elegir cualquier juego que hoy arranque bien (un DOS,
//      o un arcade si el `launch:` de §8 ya está corregido) y apretar ENTER.
//   4. Salir del juego con la tecla que corresponda (confirmada en la
//      Etapa A2 si es DOS).
//   5. Anotar qué dice la pantalla al volver: el contador y la clave
//      "antes-de-lanzar".
//   6. Repetir el lanzamiento una vez más para confirmar que no es casualidad
//      (un solo dato no alcanza para decir "recarga" o "no recarga").
//   7. Terminado: apretar R para borrar las claves, y volver a copiar el
//      theme.qml original de "attract" sobre attract-debug (o simplemente
//      elegir de nuevo el theme "attract" en Configuración).

import QtQuick 2.0

FocusScope {
    id: root
    focus: true
    anchors.fill: parent

    readonly property string claveContador: "experimento-recarga-contador"
    readonly property string claveAntesDeLanzar: "experimento-recarga-antes-de-lanzar"

    property var juegos: []
    property int seleccion: 0
    property var lineas: []

    Rectangle { anchors.fill: parent; color: "#0d1117" }

    Text {
        anchors { fill: parent; margins: 40 }
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 14
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        text: root.lineas.join("\n")
    }

    Component.onCompleted: {
        subirContador();
        cargarJuegos();
        leer();
    }

    function existeApi() {
        return typeof api.memory === "object" && api.memory !== null
            && typeof api.memory.get === "function";
    }

    function subirContador() {
        if (!existeApi()) return;
        var n = api.memory.get(claveContador);
        n = (typeof n === "number") ? n + 1 : 1;
        api.memory.set(claveContador, n);
    }

    function cargarJuegos() {
        // Sin ordenar ni filtrar: es un experimento de una sola pregunta, no
        // un catalogo. Alcanza con los primeros N para elegir uno con flechas.
        var gs = api.allGames.toVarArray();
        root.juegos = gs.slice(0, 30);
    }

    function leer() {
        var out = [];
        out.push("=== EXPERIMENTO recarga-tras-juego ===");
        out.push("");
        out.push("  ARRIBA/ABAJO elegir juego   ENTER lanzarlo   R borrar claves");
        out.push("");

        if (!existeApi()) {
            out.push("api.memory  : NO EXISTE en este binario.");
            out.push("-> la decision 11 no puede usar api.memory; hace falta otro mecanismo.");
            root.lineas = out;
            return;
        }

        var contador = api.memory.get(claveContador);
        out.push("veces que este theme.qml cargo desde que se abrio Pegasus:");
        out.push("  " + JSON.stringify(contador));
        out.push("  ^ si sube de 1 a 2 despues de UN solo juego jugado, Pegasus recarga el theme.");
        out.push("");

        var antes = api.memory.get(claveAntesDeLanzar);
        out.push("clave escrita justo antes del ultimo game.launch():");
        out.push("  " + JSON.stringify(antes));
        out.push("  ^ si esto sigue apareciendo al volver, el mecanismo de la decision 11 funciona.");
        out.push("");

        out.push("Juego seleccionado (" + (root.juegos.length ? (root.seleccion + 1) : 0) + "/" + root.juegos.length + "):");
        var g = root.juegos[root.seleccion];
        out.push("  " + (g ? g.title : "(sin juegos en api.allGames)"));

        root.lineas = out;
    }

    function mover(delta) {
        if (!root.juegos.length) return;
        root.seleccion = (root.seleccion + delta + root.juegos.length) % root.juegos.length;
        leer();
    }

    function lanzarSeleccionado() {
        var g = root.juegos[root.seleccion];
        if (!g) return;
        if (existeApi()) {
            api.memory.set(claveAntesDeLanzar, "lanzado:" + g.title + "@" + new Date().toISOString());
        }
        g.launch();
    }

    function borrar() {
        if (!existeApi()) return;
        if (typeof api.memory.unset === "function") {
            api.memory.unset(claveContador);
            api.memory.unset(claveAntesDeLanzar);
        } else {
            api.memory.set(claveContador, 0);
            api.memory.set(claveAntesDeLanzar, "");
        }
        leer();
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Up) { mover(-1); event.accepted = true; }
        else if (event.key === Qt.Key_Down) { mover(1); event.accepted = true; }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { lanzarSeleccionado(); event.accepted = true; }
        else if (event.key === Qt.Key_R) { borrar(); event.accepted = true; }
    }
}

// #RESULTADO OBSERVADO (2026-09-28, Windows, gabinete real)
//
// Metodologia: R (reset) -> confirmar "undefined" en pantalla -> lanzar
// Civilization (DOS) UNA vez -> salir con Ctrl+F9 (A2) -> leer la pantalla
// al volver, sin tocar nada mas.
//
//   despues de R      : contador = undefined, clave = undefined
//   despues de volver : contador = 1,          clave = "lanzado:Civilization@2026-09-28T04:28:01.272Z"
//
// PEGASUS SI RECARGA EL THEME al volver de un juego: el contador solo puede
// pasar de "undefined" a 1 si Component.onCompleted volvio a correr, y la
// unica forma de que eso pase es que Pegasus haya destruido y recreado el
// QML entero al volver (no solo le devolvio el foco a la ventana).
//
// Y LA CLAVE ESCRITA JUSTO ANTES DE game.launch() SOBREVIVIO a esa
// recarga: fue leida correctamente al volver, con el titulo y el timestamp
// intactos.
//
// -> CONFIRMA LA PREDICCION Y CIERRA LA DECISION 11: la guia de la feature
//    027 escribe en api.memory justo antes de cada game.launch() (que
//    juego, y que la guia estaba abierta) y la lee en Component.onCompleted
//    para reabrirse como estaba. No hace falta ningun otro mecanismo.
//
// UNA CORRIDA ANTERIOR (2026-09-28T04:22:19.908Z, mismo dia) ya habia
// mostrado la clave sobreviviendo, pero sin resetear antes no probaba el
// reload por si sola (el contador ya venia en 4 de antes). Esta corrida,
// con reset previo, es la que cierra el punto.
