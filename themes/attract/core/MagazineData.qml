// Carga UNA revista: el magazine.json que vive en media/_magazines/<ref>/,
// con el contrato de ADR-0010.
//
// Mismo patron que GameData -se le pone un `ref` y se dispara solo- y el mismo
// cache compartido (core/DataCache.js). Acá el cache importa mas todavia: una
// misma revista cubre VARIOS juegos (ese es el motivo por el que las revistas
// son una entidad aparte, ADR-0010), asi que el mismo archivo se pide desde
// fichas distintas.
//
// Es la segunda mitad de la cadena de dos lecturas que ADR-0001 dejo
// verificada: data.json -> mags[].ref -> magazine.json.

import QtQuick 2.0
import ".."
import "DataCache.js" as Cache

QtObject {
    id: md

    // --- entrada ---------------------------------------------------------

    property var game: null         // para resolver la ruta con Paths
    property var paths: null
    property string ref: ""

    // --- salida ----------------------------------------------------------

    // "sin-ref" | "cargando" | "listo" | "sin-datos"
    // "sin-datos" es el ref colgado: apunta a una revista que no existe. Es un
    // caso SOPORTADO a proposito, no un error (fixture: sf2ce).
    property string estado: "sin-ref"

    property var datos: null

    readonly property var pages: (datos && datos.pages) ? datos.pages : []
    readonly property var articles: (datos && datos.articles) ? datos.articles : []
    readonly property int totalPaginas: pages.length

    // El color de marca de la revista. `color` es opcional en el contrato
    // (ADR-0010): sin el, el carrusel usa el accent del juego.
    readonly property string colorMarca:
        (datos && typeof datos.color === "string") ? datos.color : ""

    // La carpeta de la revista, para armar las urls de sus paginas.
    readonly property string base:
        (paths && game && ref) ? paths.magazineDe(game, ref) : ""

    readonly property string urlTapa:
        (base !== "" && datos && datos.cover) ? base + datos.cover : ""

    function urlPagina(indice0) {          // 0-based, como se usa adentro
        if (base === "" || indice0 < 0 || indice0 >= pages.length) return "";
        return base + pages[indice0];
    }

    // --- nombre para mostrar (regla cerrada en ADR-0010) -----------------
    //
    // `name` puede llegar sucio: el subsistema que genera los magazine.json
    // (ADR-0009) a veces pone el nombre del archivo de origen, tipo
    // "se-micro80.pdf". Limpiarlo es PRESENTACION, no dato: no se persiste
    // nada, se arma el string en pantalla.
    //
    // La limpieza es mínima e imperfecta a proposito: sacar la extension y
    // cambiar -/_ por espacios. No se capitaliza ni se adivina mas estructura,
    // que seria heuristica fragil sin evidencia de que formas toma `name`.
    readonly property string displayName: {
        if (!datos || typeof datos.name !== "string") return "";
        var n = datos.name;

        var punto = n.lastIndexOf(".");
        if (punto > 0 && n.length - punto <= 5)      // .pdf .cbz .zip ...
            n = n.substring(0, punto);
        n = n.replace(/[-_]+/g, " ").trim();

        var partes = [n];
        if (datos.issue) partes.push("Nº" + datos.issue);
        if (datos.year) partes.push("(" + datos.year + ")");
        return partes.join(" ");
    }

    // --- articulos -------------------------------------------------------

    // El articulo que trata sobre este juego, o null. `game` es opcional en el
    // contrato: una publicidad o un indice no tratan sobre un juego puntual.
    function articuloDe(set) {
        if (!set) return null;
        for (var i = 0; i < articles.length; i++)
            if (articles[i].game === set) return articles[i];
        return null;
    }

    // En que pagina abre el visor para este juego, 0-BASED.
    //
    // startPage es un indice 1-based sobre pages[] — resuelto en
    // spec/features/006-theme-documentos/spec.md, y no es una preferencia: el
    // fixture tiene 8 paginas y sus articulos referencian 3..8, asi que
    // 0-based dejaria el 8 fuera de rango y el numero impreso no seria
    // mapeable a un archivo. La conversion a 0-based pasa ACA y en un solo
    // lugar: mezclar las dos convenciones es de donde salen los off-by-one.
    function inicioDe(set) {
        var a = articuloDe(set);
        if (!a || typeof a.startPage !== "number") return 0;
        return Math.max(0, Math.min(totalPaginas - 1, a.startPage - 1));
    }

    // Las paginas del articulo, 0-based, para marcarlas en las miniaturas.
    // Sale gratis del contrato y es la unica pista visual de por que el visor
    // abrio donde abrio.
    function paginasDe(set) {
        var a = articuloDe(set);
        if (!a || !a.pages) return [];
        var out = [];
        for (var i = 0; i < a.pages.length; i++) {
            var n = a.pages[i] - 1;
            if (n >= 0 && n < totalPaginas) out.push(n);
        }
        return out;
    }

    // --- carga -----------------------------------------------------------

    property var _xhr: null
    property string _urlVigente: ""

    onRefChanged: cargar()
    onGameChanged: cargar()

    function cargar() {
        if (_xhr) { _xhr.abort(); _xhr = null; }

        if (!game || !paths || ref === "") {
            _urlVigente = ""; datos = null; estado = "sin-ref";
            return;
        }

        var url = paths.magazineJsonDe(game, ref);
        _urlVigente = url;

        if (url === "") { datos = null; estado = "sin-datos"; return; }

        if (Cache.tiene(url)) { aplicar(url, Cache.leer(url)); return; }

        estado = "cargando";
        datos = null;

        var xhr = new XMLHttpRequest();
        _xhr = xhr;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            md._xhr = null;

            var parseado = null;
            // Con file:// el status llega 0 aunque haya salido bien.
            if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText) {
                try {
                    parseado = JSON.parse(xhr.responseText);
                    if (typeof parseado !== "object" || parseado === null)
                        parseado = null;
                } catch (e) {
                    console.log("ATTRACT: magazine.json invalido en " + url + " - " + e);
                    parseado = null;
                }
            }
            Cache.guardar(url, parseado);
            md.aplicar(url, parseado);
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // Una respuesta vieja no pisa a la de la revista que se esta mirando
    // ahora. Mismo cuidado que en GameData: el carrusel puede cambiar de
    // revista mas rapido de lo que llegan las respuestas.
    function aplicar(url, parseado) {
        if (url !== _urlVigente) return;
        datos = parseado;
        estado = parseado ? "listo" : "sin-datos";
    }
}
