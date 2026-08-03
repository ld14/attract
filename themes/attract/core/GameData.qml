// Carga los datos ricos de UN juego: el data.json que vive junto a sus assets
// (ADR-0001), con el contrato de ADR-0015.
//
// Se le pone un `game` y se dispara solo. Nadie mas en el theme hace XHR.
//
// La tecnica (XMLHttpRequest sobre file:// + JSON.parse) esta verificada
// contra Pegasus real desde el Bloque 3, y encadenada dos veces en
// themes/experimentos/json-chain-test.qml. Lo unico que faltaba era de donde
// sacar la ruta sin hardcodearla, y eso lo resuelve core/Paths.qml.
//
// TRES REGLAS QUE NO SON OPCIONALES:
//
//   1. Un 404 NO es un error. Un juego sin data.json es un juego valido, solo
//      menos enriquecido - el fixture media/mok/ existe justamente para eso.
//      Cae en "sin-datos" y cada bloque muestra su mensaje de CONVENCION #2.3.
//   2. Un JSON corrupto TAMPOCO crashea. attract doctor ya lo detecta antes
//      (chk_json_valido), pero el theme no puede confiar en que alguien lo
//      corrio: en el gabinete no hay a quien preguntarle.
//   3. Las respuestas pueden llegar DESORDENADAS. Mover el foco rapido por el
//      rail dispara una peticion por juego, y la del juego 3 puede llegar
//      despues de la del juego 5. Sin proteccion, la ficha mostraria los datos
//      del juego equivocado - un bug silencioso y dificil de reproducir. Cada
//      respuesta se compara contra la url vigente antes de aplicarse.
//
// Se instancia POR PANTALLA, no una sola vez: se liga a un juego puntual y en
// el detalle y en la libreria el juego enfocado no es el mismo.

import QtQuick 2.0
import ".."
import "DataCache.js" as Cache

QtObject {
    id: gd

    // --- entrada ---------------------------------------------------------

    property var game: null
    property var paths: null        // el Paths.qml instanciado en theme.qml

    // --- salida ----------------------------------------------------------

    // "sin-juego" | "cargando" | "listo" | "sin-datos"
    // "sin-datos" cubre los tres casos que degradan igual: no hay data.json,
    // el JSON esta roto, o el juego no vive en el disco (Steam, ver Paths).
    property string estado: "sin-juego"

    property var datos: null        // el objeto crudo, o null

    // El accent pasa por Theme.accentDe(), que centraliza la degradacion de
    // ADR-0013: un juego sin accent no se rompe, se ve apagado.
    readonly property color accent: Theme.accentDe(datos ? datos.accent : null)
    readonly property color accent2: Theme.accent2De(datos ? datos.accent2 : null)

    readonly property var mags: (datos && datos.mags) ? datos.mags : []
    readonly property var manual: (datos && datos.manual) ? datos.manual : null
    readonly property var cheats: (datos && datos.cheats) ? datos.cheats : null
    readonly property var review: (datos && datos.review) ? datos.review : null

    // --- "hay algo que mostrar?" -----------------------------------------
    //
    // OJO: estos NO deciden si un bloque se dibuja. CONVENCION #2.3 manda que
    // ningun bloque desaparezca - deciden si el bloque muestra CONTENIDO o su
    // mensaje ("Sin Informacion" / "No Disponible" / "Sin cobertura en
    // revistas"). Es la divergencia consciente respecto del handoff, que pedia
    // omitir las secciones vacias.

    readonly property bool hayRevistas: mags.length > 0
    readonly property bool hayManual:
        manual !== null && manual.pages !== undefined && manual.pages.length > 0
    readonly property bool hayCheats:
        cheats !== null &&
        ((cheats.combos && cheats.combos.length > 0) ||
         (cheats.codes && cheats.codes.length > 0))
    readonly property bool hayReview: review !== null

    readonly property int combosCount: (cheats && cheats.combos) ? cheats.combos.length : 0
    readonly property int codesCount: (cheats && cheats.codes) ? cheats.codes.length : 0
    readonly property int manualPaginas: hayManual ? manual.pages.length : 0

    // Una categoria de la resena, o null si esa categoria puntual no tiene
    // dato. Los DOS niveles de "sin dato" de CONVENCION #2.3: sin review el
    // bloque entero dice "Sin Informacion"; con review parcial, la categoria
    // que falta muestra "-" y las demas se ven normal.
    function catDe(nombre) {
        if (!review || !review.cats) return null;
        var v = review.cats[nombre];
        return (typeof v === "number") ? v : null;
    }

    // --- interna ---------------------------------------------------------

    // El cache es COMPARTIDO (DataCache.js, .pragma library), no una propiedad
    // de esta instancia: en el rail de la libreria las tarjetas son delegates
    // de un ListView y se destruyen al scrollear. Un cache por instancia se
    // perderia en cada pasada.
    property var _xhr: null
    property string _urlVigente: ""

    onGameChanged: cargar()

    function cargar() {
        if (_xhr) { _xhr.abort(); _xhr = null; }

        if (!game || !paths) {
            _urlVigente = "";
            datos = null;
            estado = "sin-juego";
            return;
        }

        var url = paths.dataJsonDe(game);
        _urlVigente = url;

        // Sin base no hay datos ricos posibles: es un juego que no vive en el
        // disco (Steam devuelve "steam:255710", ver Paths). Degrada, no falla.
        if (url === "") {
            datos = null;
            estado = "sin-datos";
            return;
        }

        if (Cache.tiene(url)) {
            aplicar(url, Cache.leer(url));
            return;
        }

        estado = "cargando";
        datos = null;

        var xhr = new XMLHttpRequest();
        _xhr = xhr;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            gd._xhr = null;

            var parseado = null;
            // Con file:// el status llega 0 aunque haya salido bien; 404 y 0
            // con cuerpo vacio son el mismo caso: no hay data.json.
            if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText) {
                try {
                    parseado = JSON.parse(xhr.responseText);
                    if (typeof parseado !== "object" || parseado === null)
                        parseado = null;   // un JSON valido pero que no es objeto
                } catch (e) {
                    // Regla 2: no crashea. doctor ya lo reporta con detalle
                    // (chk_json_valido); aca solo hay que degradar.
                    console.log("ATTRACT: data.json invalido en " + url + " - " + e);
                    parseado = null;
                }
            }

            // null tambien se cachea: "ya se pidio y no hay data.json" es
            // un resultado, no un fallo que convenga reintentar.
            Cache.guardar(url, parseado);
            gd.aplicar(url, parseado);
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // Regla 3: una respuesta vieja no pisa a la del juego que se esta mirando
    // ahora. Sin esto, mover el foco rapido por el rail mezcla las fichas.
    function aplicar(url, parseado) {
        if (url !== _urlVigente) return;
        datos = parseado;
        estado = parseado ? "listo" : "sin-datos";
    }
}
