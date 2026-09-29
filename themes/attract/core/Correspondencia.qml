// Lee library/<coleccion>/_controles.json - el artefacto que genera
// `attract controles` (spec 027) - y expone la entrada del juego enfocado.
//
// Mismas tres reglas que GameData (ver su encabezado): un 404 no es error
// (nadie corrio `attract controles` todavia, o el juego no vive en el
// disco), un JSON roto no crashea, y una respuesta vieja no pisa al juego
// que se esta mirando ahora.
//
// A diferencia de GameData, el archivo es POR COLECCION, no por juego: el
// cache (DataCache.js, compartido) guarda el artefacto entero bajo la url de
// la coleccion, y esta clase recorta la parte de `porJuego` que corresponde
// al set actual.
//
// ALCANCE A PROPOSITO: para MAME, `entrada.controles[]` es la lista de
// controles DECLARADOS (type/buttons/ways por control, no boton por boton) -
// alcanza para que el diagrama sepa cuantos botones dibujar. Resolver A CUAL
// posicion fisica corresponde CADA boton es trabajo de la Etapa F, que hoy
// no tiene ningun dato con que operar (Gabinete.algunaPosicionMedida es
// siempre false): el diagrama usa ESE interruptor, no este archivo, para
// decidir si intenta resaltar una posicion. Para DOSBox, `entrada.salida` y
// `entrada.joysticktype` ya son la respuesta final por juego (si esta
// verificada o no), sin nada mas que resolver.

import QtQuick 2.0
import ".."
import "DataCache.js" as Cache

QtObject {
    id: corr

    property var game: null
    property var paths: null

    // "sin-juego" | "cargando" | "listo" | "sin-datos" (sin artefacto,
    // artefacto roto, o juego no identificado - los tres degradan igual: el
    // diagrama sigue mostrando entradas logicas).
    property string estado: "sin-juego"

    property var _artefacto: null
    readonly property string _set: (game && paths) ? paths.setDe(game) : ""

    readonly property var entrada: {
        if (!_artefacto || !_artefacto.porJuego || _set === "") return null;
        var e = _artefacto.porJuego[_set];
        return (e && !e.error) ? e : null;
    }

    readonly property var controlesDeclarados:
        (entrada && Array.isArray(entrada.controlesDeclarados)) ? entrada.controlesDeclarados : []

    // Solo tiene sentido para DOSBox; null en MAME o sin artefacto.
    readonly property var salidaJuego: (entrada && entrada.salida) ? entrada.salida : null
    readonly property string joysticktype: entrada ? (entrada.joysticktype || "") : ""

    property var _xhr: null
    property string _urlVigente: ""

    onGameChanged: cargar()
    Component.onCompleted: cargar()

    function cargar() {
        if (_xhr) { _xhr.abort(); _xhr = null; }

        if (!game || !paths) {
            _urlVigente = "";
            _artefacto = null;
            estado = "sin-juego";
            return;
        }

        var url = paths.controlesDe(game);
        _urlVigente = url;

        if (url === "") {
            _artefacto = null;
            estado = "sin-datos";
            return;
        }

        if (Cache.tiene(url)) {
            aplicar(url, Cache.leer(url));
            return;
        }

        estado = "cargando";
        _artefacto = null;

        var xhr = new XMLHttpRequest();
        _xhr = xhr;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            corr._xhr = null;

            var parseado = null;
            if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText) {
                try {
                    parseado = JSON.parse(xhr.responseText);
                    if (typeof parseado !== "object" || parseado === null) parseado = null;
                } catch (e) {
                    console.log("ATTRACT: _controles.json invalido en " + url + " - " + e);
                    parseado = null;
                }
            }

            Cache.guardar(url, parseado);
            corr.aplicar(url, parseado);
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function aplicar(url, parseado) {
        if (url !== _urlVigente) return;
        _artefacto = parseado;
        estado = parseado ? "listo" : "sin-datos";
    }
}
