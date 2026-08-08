// EXPERIMENTO — ¿aguanta el patrón de estantes con 1200+ juegos?
//
// Contexto: el handoff de design_handoff_home/ cambia el rail único de la
// librería por estantes tipo Netflix — un ListView vertical de estantes,
// cada estante un ListView horizontal de tarjetas — sobre un catálogo real
// de 1200+ juegos, y con orden y filtro que se recalculan en vivo.
//
// El README del handoff dice que en QML esto "es más simple que en el
// prototipo web" porque ListView virtualiza nativo. Es cierto para el
// RENDER. No dice nada del otro costo, que es el que preocupa:
//
//     ordenar 1200 juegos exige leer propiedades de 1200 QObjects, y un
//     comparador que lea g.title corre O(n log n) -> ~12.000 lecturas por
//     cada cambio de criterio.
//
// PREDICCIÓN: toVarArray() + un array paralelo de claves primitivas
// (calculado UNA vez) + Array.sort sobre las claves da un tiempo
// despreciable (<50ms), y el ListView anidado nunca instancia más de ~15
// tarjetas por estante vivo. Si la predicción falla, el plan B es ordenar
// una sola vez al arranque por cada criterio y cachear los cuatro arrays.
//
// LO QUE HAY QUE MEDIR:
//
//   1. Cuánto tarda api.allGames.toVarArray() con el catálogo real.
//   2. Cuánto tarda construir el array de claves (title/year/rating/
//      playCount/lastPlayed/genre/favorite), que es la lectura cara.
//   3. Cuánto tarda ordenar 1200 por cada criterio.
//   4. **Cuántos delegates existen a la vez.** Es la medición que decide si
//      el patrón sirve: si al scrollear el contador sube y no baja, no está
//      virtualizando y la pantalla se va a comer la memoria del gabinete.
//   5. Que el foco anidado funcione: currentIndex del ListView de afuera
//      mueve de estante, el de adentro mueve de tarjeta.
//
// SOBRE EL CATÁLOGO SINTÉTICO, que es una trampa a la vista: fixtures/ tiene
// un puñado de juegos, no 1200. Este experimento REPITE los juegos reales
// hasta llegar a 1200 entradas. Eso mide bien el costo de ordenar y de
// virtualizar (que dependen de la CANTIDAD), y NO mide nada sobre datos
// reales distintos — los accents, las carátulas y los data.json de 1200
// juegos distintos son otro experimento. Está anotado acá para que nadie
// lea este resultado como "el theme anda con la librería real".
//
// Cómo se corre: cp themes/experimentos/estantes-perf.qml \
//   "$PEGASUS_THEMES/attract-debug/theme.qml" y elegir ATTRACT Debug.

import QtQuick 2.0

FocusScope {
    id: root
    focus: true
    anchors.fill: parent

    // Minuscula: en QML una propiedad no puede empezar con mayuscula.
    readonly property int objetivo: 1200

    property var juegos: []          // el catalogo sintetico
    property var claves: []          // array paralelo de primitivas
    property var medidas: []
    property int vivos: 0            // delegates instanciados AHORA
    property int picoVivos: 0

    Rectangle { anchors.fill: parent; color: "#0d1117" }

    Component.onCompleted: preparar()

    function preparar() {
        var out = [];
        var t0 = Date.now();

        // 1. toVarArray sobre el catalogo real
        var reales = api.allGames.toVarArray();
        var t1 = Date.now();
        out.push("toVarArray()      : " + (t1 - t0) + " ms  (" + reales.length + " juegos reales)");

        if (reales.length === 0) {
            root.medidas = ["No hay juegos. Revisa game_dirs.txt."];
            return;
        }

        // 2. inflar al objetivo repitiendo (ver nota del encabezado)
        var infl = [];
        while (infl.length < root.objetivo)
            infl.push(reales[infl.length % reales.length]);
        root.juegos = infl;
        var t2 = Date.now();
        out.push("inflar a " + root.objetivo + "     : " + (t2 - t1) + " ms");

        // 3. LA LECTURA CARA: una pasada, todas las propiedades que ordenan
        var ks = [];
        for (var i = 0; i < infl.length; i++) {
            var g = infl[i];
            ks.push({
                i: i,
                orden: String(g.sortBy || g.title || "").toLowerCase(),
                anio: g.releaseYear,
                nota: g.rating,
                jugadas: g.playCount,
                ultima: g.lastPlayed ? g.lastPlayed.getTime() : 0,
                genero: g.genre || "",
                fav: g.favorite
            });
        }
        root.claves = ks;
        var t3 = Date.now();
        out.push("claves x" + infl.length + "      : " + (t3 - t2) + " ms   <- la lectura cara");

        // 4. ordenar por cada criterio, sobre las claves y no sobre los QObjects
        out.push(medir("LETRA  ", function(a, b) { return a.orden.localeCompare(b.orden); }));
        out.push(medir("ANIO   ", function(a, b) { return a.anio - b.anio; }));
        out.push(medir("NOTA   ", function(a, b) { return b.nota - a.nota; }));
        out.push(medir("JUGADOS", function(a, b) { return b.jugadas - a.jugadas; }));

        // 5. control: ordenar leyendo el QObject en el comparador, que es lo
        //    que NO hay que hacer. La diferencia contra "LETRA" es el numero
        //    que justifica el array de claves.
        var t4 = Date.now();
        infl.slice().sort(function(a, b) {
            return String(a.title).localeCompare(String(b.title));
        });
        out.push("CONTROL (leyendo g.title en el comparador) : " + (Date.now() - t4) + " ms");

        root.medidas = out;
    }

    function medir(nombre, cmp) {
        var t = Date.now();
        root.claves.slice().sort(cmp);
        return "sort " + nombre + "     : " + (Date.now() - t) + " ms";
    }

    // ------------------------------------------------------------- pantalla
    Text {
        id: reporte
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 24 }
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 13
        textFormat: Text.PlainText
        text: "=== EXPERIMENTO ESTANTES / 1200 JUEGOS ===\n"
            + "  flechas: mover foco   (estante " + (estantes.currentIndex + 1) + " de " + estantes.count + ")\n\n"
            + root.medidas.join("\n")
            + "\n\ndelegates vivos: " + root.vivos + "   pico: " + root.picoVivos
            + "\n(si el pico sube sin parar al scrollear, NO esta virtualizando)"
    }

    // Cuatro estantes sobre el mismo catalogo: alcanza para medir el patron
    // sin inventar la logica de shelvesData(), que es de la fase 009.
    ListView {
        id: estantes
        anchors { top: reporte.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        anchors.topMargin: 20
        model: 4
        spacing: 18
        focus: true
        clip: true

        preferredHighlightBegin: 0
        preferredHighlightEnd: 190
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 300

        delegate: FocusScope {
            width: estantes.width
            height: 190

            readonly property bool esFoco: ListView.isCurrentItem

            Text {
                id: etiqueta
                text: "ESTANTE " + (index + 1) + "  ·  " + root.juegos.length + " juegos"
                color: parent.esFoco ? "#f1f3f8" : "#6a7081"
                font.family: "monospace"
                font.pixelSize: 12
            }

            ListView {
                anchors { top: etiqueta.bottom; left: parent.left; right: parent.right }
                anchors.topMargin: 8
                height: 150
                orientation: ListView.Horizontal
                spacing: 16
                model: root.juegos
                focus: true
                clip: true

                // La tarjeta enfocada en la 2a ranura, como el handoff
                // (.dc.html:652 -> tx = (col-1)*STRIDE).
                preferredHighlightBegin: 148 + 16
                preferredHighlightEnd: 2 * (148 + 16)
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: 300

                delegate: Rectangle {
                    width: 148
                    height: 150
                    radius: 10
                    color: ListView.isCurrentItem ? "#1f6feb" : "#161b22"
                    border.color: ListView.isCurrentItem ? "#7ee787" : "#30363d"

                    Text {
                        anchors { fill: parent; margins: 8 }
                        wrapMode: Text.WordWrap
                        color: "#c9d1d9"
                        font.family: "monospace"
                        font.pixelSize: 10
                        text: index + "\n" + (modelData ? modelData.title : "")
                    }

                    // El contador que decide el experimento (punto 4).
                    Component.onCompleted: {
                        root.vivos += 1;
                        if (root.vivos > root.picoVivos) root.picoVivos = root.vivos;
                    }
                    Component.onDestruction: root.vivos -= 1
                }
            }
        }
    }
}

// #RESULTADO OBSERVADO (2026-08-05, Pegasus alpha16-82-gc3462e68, macOS,
// 10 juegos reales inflados a 1200)
//
//   toVarArray()                              :  0 ms
//   inflar a 1200                             :  1 ms
//   claves x1200                              :  3 ms
//   sort LETRA                                : 14 ms
//   sort ANIO / NOTA / JUGADOS                :  1 ms cada uno
//   CONTROL (leyendo g.title en el comparador): 16 ms
//
//   delegates vivos 44, pico 47 despues de recorrer hasta el indice 32 y de
//   bajar por los cuatro estantes. NO subio mas.
//
// -> VIRTUALIZA. Cuatro estantes de 1200 mantienen ~11 tarjetas vivas cada
//    uno. El patron de estantes anidados sirve tal cual esta planificado.
//
// -> EL FOCO ANIDADO SE COMPORTA: el ListView horizontal se queda con las
//    flechas laterales y deja pasar las verticales al de afuera. No hubo que
//    interceptar nada. El plan B (manejar las cuatro direcciones desde el
//    FocusScope de la pantalla) queda sin usar.
//
// -> LA TARJETA ENFOCADA CAE EN LA 2a RANURA, como pide el handoff.
//    preferredHighlightBegin/End con ApplyRange lo resuelve solo.
//
// LA PREDICCION SOBRE EL COSTO ESTABA MAL ENCUADRADA, y conviene decirlo:
// se predijo que la lectura de propiedades del QObject era el costo dominante.
// No lo es. Ordenar por LETRA con las claves ya extraidas tarda 14 ms y
// hacerlo leyendo `g.title` dentro del comparador tarda 16 ms: **los ~12.000
// accesos a propiedades cuestan unos 2 ms**. Los 14 ms son `localeCompare`,
// que es caro por si mismo y no lo evita ningun cache. El array de claves
// igual se justifica —es gratis y saca esos 2 ms— pero no es la optimizacion
// que se creia, y **ninguna de las dos se percibe**: 16 ms es un cuadro.
//
// TRES LIMITES DE ESTA MEDICION, para que nadie la lea de mas:
//
//   1. Son 10 titulos distintos repetidos 120 veces. Con 1200 titulos REALES,
//      localeCompare compara strings mas largas y variadas y los 1200 QObject
//      son distintos (peor localidad). Este numero es un PISO, no un techo.
//   2. Se midio en el Mac de desarrollo, no en el gabinete Windows.
//   3. Las tarjetas de este experimento son un Rectangle con un Text. Las de
//      verdad traen un GameData (XHR + cache) y una imagen de caratula: el
//      costo por delegate va a ser otro. Lo que quedo probado es CUANTAS
//      viven, no cuanto pesa cada una.
//
// UNA DIFERENCIA CON EL PROTOTIPO, encontrada de casualidad: cada ListView
// horizontal recuerda SU PROPIA columna. Al bajar de estante, el nuevo
// arranca donde lo dejaste, no en la columna del estante anterior. El
// prototipo usa una sola variable `col` global y la clampea (.dc.html:565).
// La memoria por estante es la que sale gratis en QML y es la que usa
// cualquier libreria tipo Netflix; se adopta esa y se anota como divergencia
// consciente.
