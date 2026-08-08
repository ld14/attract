// EXPERIMENTO — ¿api.memory sobrevive a cerrar y reabrir Pegasus?
//
// Contexto: la pantalla de Buscar del handoff muestra "búsquedas recientes"
// cuando el query está vacío (design_handoff_home/README.md §Pantalla 2).
// Eso necesita persistencia, y el theme no tiene ninguna: data.json es de
// solo lectura (ADR-0001/0015) y escribir en el disco desde QML no está en
// el repertorio verificado.
//
// La documentación oficial dice que api.memory guarda pares clave/valor por
// theme (set/get/has/unset). Acá ya sabemos cuánto vale eso sin medirlo:
// game.extra "es un string" según la doc y es una lista.
//
// PREDICCIÓN: api.memory existe, y el valor sobrevive a ⌘Q + reabrir. Lo que
// NO se sabe y es lo que importa:
//
//   1. Si sobrevive de verdad al reinicio (que es el único caso que le
//      importa a un gabinete que se apaga de la pared).
//   2. Qué tipos aguanta. La lista de recientes es un Array de strings; si
//      set() solo guarda primitivas, hay que serializar con JSON.stringify
//      y el theme necesita saberlo ANTES de escribir la fase 010.
//   3. Cuándo escribe a disco. Si solo persiste al salir limpio, un corte de
//      luz se lleva las recientes — molesto pero tolerable; si ni siquiera
//      persiste al salir limpio, la feature no existe.
//
// SI ESTO FALLA: las "búsquedas recientes" salen de la fase 010 y el panel
// vacío de Buscar muestra los más jugados, que se calculan de playCount y no
// necesitan guardar nada.
//
// CÓMO SE CORRE, y es distinto a los otros dos — este experimento necesita
// DOS corridas:
//
//   1. cp themes/experimentos/memoria.qml \
//        "$PEGASUS_THEMES/attract-debug/theme.qml"
//   2. Abrir Pegasus, elegir ATTRACT Debug, apretar ESPACIO unas veces.
//      Anotar el contador y la lista.
//   3. ⌘Q (cerrar del todo, no cambiar de theme) y volver a abrir.
//   4. Si el contador arranca donde había quedado, persiste.

import QtQuick 2.0

FocusScope {
    id: root
    focus: true
    anchors.fill: parent

    // Minuscula: en QML una propiedad no puede empezar con mayuscula.
    readonly property string claveContador: "experimento-contador"
    readonly property string claveListaJson: "experimento-lista-json"
    readonly property string claveListaCruda: "experimento-lista-cruda"

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

    Component.onCompleted: leer()

    function existeApi() {
        return typeof api.memory === "object" && api.memory !== null
            && typeof api.memory.get === "function";
    }

    function leer() {
        var out = [];
        out.push("=== EXPERIMENTO api.memory ===");
        out.push("");
        out.push("  ESPACIO  sumar una busqueda    R  borrar todo");
        out.push("  Despues: Cmd-Q, reabrir Pegasus, y mirar si el numero quedo.");
        out.push("");

        if (!existeApi()) {
            out.push("api.memory  : NO EXISTE en este binario.");
            out.push("-> las busquedas recientes salen de la fase 010.");
            root.lineas = out;
            return;
        }

        out.push("api.memory  : existe");
        out.push("  has()  : " + (typeof api.memory.has === "function" ? "si" : "NO"));
        out.push("  unset(): " + (typeof api.memory.unset === "function" ? "si" : "NO"));
        out.push("");

        var n = api.memory.get(claveContador);
        out.push("contador guardado : " + JSON.stringify(n)
                 + "   (tipo: " + typeof n + ")");
        out.push("  ^ si volviste de un Cmd-Q y esto NO es undefined, persiste.");
        out.push("");

        // Punto 2: el mismo Array guardado de las dos formas. Cual de las dos
        // vuelve entera decide como se escribe la fase 010.
        var crudo = api.memory.get(claveListaCruda);
        out.push("lista guardada CRUDA (Array directo) :");
        out.push("  tipo  : " + typeof crudo + (Array.isArray(crudo) ? " (Array)" : ""));
        out.push("  valor : " + JSON.stringify(crudo));

        var json = api.memory.get(claveListaJson);
        out.push("lista guardada con JSON.stringify :");
        out.push("  valor : " + JSON.stringify(json));
        var vuelta = null;
        if (typeof json === "string") {
            try { vuelta = JSON.parse(json); } catch (e) { vuelta = "PARSE FALLO: " + e; }
        }
        out.push("  parseada : " + JSON.stringify(vuelta));

        root.lineas = out;
    }

    function sumar() {
        if (!existeApi()) return;

        var n = api.memory.get(claveContador);
        n = (typeof n === "number") ? n + 1 : 1;
        api.memory.set(claveContador, n);

        var lista = null;
        var json = api.memory.get(claveListaJson);
        if (typeof json === "string") {
            try { lista = JSON.parse(json); } catch (e) { lista = null; }
        }
        if (!lista || !lista.length) lista = [];
        lista.unshift("busqueda-" + n);
        lista = lista.slice(0, 4);

        api.memory.set(claveListaJson, JSON.stringify(lista));
        api.memory.set(claveListaCruda, lista);   // a proposito sin serializar

        leer();
    }

    function borrar() {
        if (!existeApi()) return;
        if (typeof api.memory.unset === "function") {
            api.memory.unset(claveContador);
            api.memory.unset(claveListaJson);
            api.memory.unset(claveListaCruda);
        } else {
            api.memory.set(claveContador, 0);
        }
        leer();
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Space) { sumar(); event.accepted = true; }
        else if (event.key === Qt.Key_R) { borrar(); event.accepted = true; }
    }
}

// #RESULTADO OBSERVADO (2026-08-05, Pegasus alpha16-82-gc3462e68, macOS)
//
// api.memory EXISTE, con get/set/has/unset. **Persiste al Cmd-Q**: cinco
// ESPACIO dejaron el contador en 5, se cerro Pegasus del todo, se reabrio, y
// volvio 5 — con tipo `number`, no string.
//
// Y LAS DOS FORMAS DE GUARDAR EL ARRAY VUELVEN ENTERAS:
//
//   crudo (set con el Array directo)  -> object, Array.isArray() true,
//                                        ["busqueda-5","busqueda-4", ...]
//   JSON.stringify                    -> el string, y JSON.parse lo devuelve
//                                        identico
//
// -> LA FASE 010 GUARDA EL ARRAY CRUDO. No hace falta serializar: set()
//    conserva el tipo, incluido `number`, y un paso menos es un paso menos.
//    La rama de JSON.stringify de este experimento existia para el caso en
//    que solo aguantara primitivas; no es el caso.
//
// DOS COSAS QUE ESTO NO MIDIO:
//
//   1. Solo se probo un Array de strings y un number. Objetos anidados
//      (`[{q, cuando}]`) no se probaron — las busquedas recientes son
//      strings, asi que no hizo falta, pero no se puede afirmar del resto.
//   2. Cuando escribe a disco. Se verifico el Cmd-Q limpio, que es el caso
//      normal. Un corte de luz —el gabinete se apaga de la pared— no se
//      probo, y ahi la lista podria perderse. Es tolerable: son busquedas
//      recientes, no datos del usuario.
