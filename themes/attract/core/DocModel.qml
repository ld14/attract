// El modelo de paginas que consume el visor. Es la pieza que hace que
// DocumentViewer sea UNO SOLO y no dos.
//
// Una revista y un manual son cosas distintas -una es una entidad compartida
// entre juegos, el otro pertenece a uno- pero para HOJEARLOS son lo mismo: una
// lista ordenada de imagenes. Ese es exactamente el motivo por el que
// ADR-0014 le dio a manual.pages[] la misma forma que a magazine.json
// -> pages[]. Aca se cobra esa decision.
//
// El visor recibe un DocModel y no sabe cual de los dos le tocó. Toda la
// diferencia vive en como se arma:
//
//   tipo       paginas              inicio               destacadas
//   ---------  -------------------  -------------------  ----------------
//   revista    magazine.pages[]     articulo.startPage   articulo.pages[]
//   manual     manual.pages[]       1                    (ninguna)
//
// LOS INDICES: el contrato habla 1-based (ADR-0010 + spec de la 006), y
// adentro del theme todo es 0-based. La conversion pasa en MagazineData y en
// ningun otro lado. Aca ya llega todo 0-based.

import QtQuick 2.0

QtObject {
    id: doc

    // "revista" | "manual" | ""
    property string tipo: ""

    // Titulo del encabezado del visor.
    property string titulo: ""

    // Nombre de la fuente: la revista, o "Manual". Va al lado del titulo.
    property string fuente: ""

    // Las urls de las paginas, en orden. Ya resueltas: el visor no arma rutas.
    property var paginas: []

    // Donde abre, 0-based.
    property int inicio: 0

    // Que paginas destacar en la tira de miniaturas, 0-based. Para un manual
    // va vacio: no hay "la nota de este juego" dentro de un manual.
    property var destacadas: []

    readonly property int total: paginas.length
    readonly property bool vacio: total === 0

    function url(i) {
        return (i >= 0 && i < paginas.length) ? paginas[i] : "";
    }

    function esDestacada(i) {
        for (var k = 0; k < destacadas.length; k++)
            if (destacadas[k] === i) return true;
        return false;
    }

    // --- constructores ---------------------------------------------------
    //
    // Devuelven un objeto plano, no un DocModel: el visor lo copia a su propio
    // modelo. Asi no hace falta instanciar componentes para preguntar algo.

    // Una revista, entrando por la nota de un juego.
    function desdeRevista(mag, set) {
        var urls = [];
        for (var i = 0; i < mag.totalPaginas; i++) urls.push(mag.urlPagina(i));
        return {
            tipo: "revista",
            titulo: "Revistas de la época",
            fuente: mag.displayName,
            paginas: urls,
            // El visor abre en la nota, pero su modelo son TODAS las paginas
            // de la revista: la nota es la puerta de entrada, no un limite
            // (docs/decisiones/2026-07-23.md #5).
            inicio: mag.inicioDe(set),
            destacadas: mag.paginasDe(set)
        };
    }

    // El manual de un juego.
    function desdeManual(gameData, paths, game) {
        var urls = [];
        var base = paths ? paths.manualDe(game) : "";
        if (base !== "" && gameData.hayManual) {
            var ps = gameData.manual.pages;
            for (var i = 0; i < ps.length; i++) urls.push(base + ps[i]);
        }
        return {
            tipo: "manual",
            titulo: "Manual digitalizado",
            fuente: "",
            paginas: urls,
            inicio: 0,
            destacadas: []
        };
    }
}
