// Carga UNA revista: el magazine.json que vive en <raiz-libreria>/_magazines/
// <ref>/, con el contrato de ADR-0024.
//
// Mismo patron que GameData -se le pone un `ref` y se dispara solo- y el mismo
// cache compartido (core/DataCache.js). Acá el cache importa mas todavia: una
// misma revista cubre VARIOS juegos, y de varios sistemas (ese es el motivo
// por el que las revistas son una entidad aparte y viven FUERA del arbol de
// cualquier sistema, ADR-0024), asi que el mismo archivo se pide desde fichas
// distintas.
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

    // Las paginas viven en <rev>/pages/ y `pages[]` trae el nombre PELADO
    // ("p002.jpg"), asi que el prefijo lo pone el consumidor (ADR-0024). Este
    // es el unico lugar que lo hace.
    //
    // La tapa NO lleva el prefijo: cover.jpg vive en la raiz de la revista.
    // Y el manual tampoco, que es plano en media/<set>/_manual/ (ADR-0014) y
    // se arma en DocModel con paths.manualDe() — comparten visor, no layout.
    function urlPagina(indice0) {          // 0-based, como se usa adentro
        if (base === "" || indice0 < 0 || indice0 >= pages.length) return "";
        return base + "pages/" + pages[indice0];
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

    // --- de numero de pagina impresa a indice del array -------------------
    //
    // startPage y articles[].pages son NUMEROS DE PAGINA IMPRESA, no indices
    // sobre pages[] (ADR-0024). La diferencia no se ve en los fixtures, que
    // arrancan todos en p001 y hacen coincidir las dos lecturas; se ve en una
    // revista real, donde pages[] arranca en "p002.jpg" porque la pagina 1 es
    // la tapa y vive aparte en cover.jpg:
    //
    //   pages[0]  = p002.jpg
    //   pages[44] = p046.jpg   <- el articulo con startPage 46
    //   pages[45] = p047.jpg   <- donde caia la resta startPage-1
    //
    // Por eso se BUSCA el archivo en vez de contar posiciones: asi no se
    // asume nada sobre en que pagina arranca la revista ni sobre que la
    // numeracion sea continua, que en un escaneo real no lo es.

    // El numero impreso sale del nombre del archivo: "p046.jpg" -> 46.
    function _numeroDe(nombre) {
        var m = /(\d+)/.exec(String(nombre));
        return m ? parseInt(m[1], 10) : -1;
    }

    // Indice 0-based de una pagina impresa, o -1 si esa pagina no esta.
    function indiceDePagina(numero) {
        for (var i = 0; i < pages.length; i++)
            if (_numeroDe(pages[i]) === numero) return i;
        return -1;
    }

    // En que pagina abre el visor para este juego, 0-BASED. Un startPage que
    // no resuelve degrada a la primera pagina: la revista se abre igual.
    function inicioDe(set) {
        var a = articuloDe(set);
        if (!a || typeof a.startPage !== "number") return 0;
        var i = indiceDePagina(a.startPage);
        return i >= 0 ? i : 0;
    }

    // Las paginas del articulo, 0-based, para marcarlas en las miniaturas.
    // Sale gratis del contrato y es la unica pista visual de por que el visor
    // abrio donde abrio.
    function paginasDe(set) {
        var a = articuloDe(set);
        if (!a || !a.pages) return [];
        var out = [];
        for (var i = 0; i < a.pages.length; i++) {
            var n = indiceDePagina(a.pages[i]);
            if (n >= 0) out.push(n);
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
