// Los assets opcionales de UNA plataforma: logo.png, los emblemas y data.json
// de library/<coleccion>/_platform/ (ADR-0035). Se le pone una plataforma de
// Catalog.plataformas y se dispara solo.
//
// Es GameData en chico y con las mismas tres reglas (ver su encabezado): un
// 404 no es error, un JSON roto no crashea, y una respuesta vieja no pisa a la
// plataforma enfocada ahora. El cache es el mismo DataCache.js, por url: volver
// a pasar por una plataforma no la vuelve a leer.
//
// TODO ES OPCIONAL, y el caso normal es que no haya nada: al principio ninguna
// plataforma tiene assets cargados. Sin data.json el acento es el neutro y la
// abreviatura es la de la coleccion; sin logo, la URL igual se arma y quien la
// dibuja mira `Image.status` — un PNG que no esta da Error y no se dibuja.
//
// LOS EMBLEMAS SON VARIOS (pedido del autor, 2026-09-22): emblema.png y
// emblema_01.png, emblema_02.png, ... hasta emblema_99.png. Cada vez que se enfoca la plataforma se
// elige uno al azar, distinto del anterior si hay otro. QML no puede listar
// una carpeta, asi que se buscan por nombre con la misma lectura que data.json
// (XMLHttpRequest sobre file://), en el orden de Platforms.nombreEmblema, hasta
// el primer numero que falte. La lista encontrada se cachea por plataforma: la
// busqueda corre una vez por sesion, no en cada pasada del carrusel.

import QtQuick 2.0
import ".."
import "DataCache.js" as Cache
import "Platforms.js" as Platforms

QtObject {
    id: pd

    // --- entrada ---------------------------------------------------------

    property var plataforma: null   // una entrada de Catalog.plataformas
    property var paths: null

    // --- salida ----------------------------------------------------------

    // "" en TODAS y en una plataforma cuyos juegos no viven en el disco.
    readonly property string base:
        (plataforma && !plataforma.todas && paths) ? paths.plataformaDe(plataforma.muestra) : ""

    readonly property string logo: base === "" ? "" : base + "logo.png"

    // Las URLs de los emblemas que existen, y el elegido para esta pasada.
    property var emblemas: []
    property string emblema: ""

    // { accent, abrev, nombre } con "" en lo que falte (Platforms.leerDatos).
    property var datos: null

    // TODAS no es una coleccion y no tiene data.json: su acento es fijo.
    readonly property color accent: (plataforma && plataforma.todas)
        ? Theme.accentTodas
        : Theme.accentDe(datos ? datos.accent : null)

    readonly property string abrev:
        (datos && datos.abrev !== "") ? datos.abrev : (plataforma ? plataforma.abrev : "")

    readonly property string nombre:
        (datos && datos.nombre !== "") ? datos.nombre : (plataforma ? plataforma.nombre : "")

    // --- interna ---------------------------------------------------------

    property var _xhr: null
    property var _xhrEmblema: null
    property string _urlVigente: ""
    property string _baseVigente: ""

    onBaseChanged: cargar()
    // La primera evaluacion de `base` puede no disparar onBaseChanged.
    Component.onCompleted: cargar()

    function cargar() {
        cargarDatos();
        cargarEmblemas();
    }

    function cargarDatos() {
        if (_xhr) { _xhr.abort(); _xhr = null; }

        var url = base === "" ? "" : base + "data.json";
        _urlVigente = url;
        if (url === "") { datos = null; return; }

        if (Cache.tiene(url)) { datos = Cache.leer(url); return; }

        datos = null;
        var xhr = new XMLHttpRequest();
        _xhr = xhr;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            pd._xhr = null;
            // Con file:// el status llega 0 aunque haya salido bien. Un 404 o
            // un cuerpo vacio caen en leerDatos("") y dan los campos vacios.
            var texto = (xhr.status === 200 || xhr.status === 0) ? xhr.responseText : "";
            var leido = Platforms.leerDatos(texto || "");
            Cache.guardar(url, leido);
            if (url === pd._urlVigente) pd.datos = leido;
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // --- emblemas ----------------------------------------------------------

    function cargarEmblemas() {
        if (_xhrEmblema) { _xhrEmblema.abort(); _xhrEmblema = null; }
        _baseVigente = base;

        // El emblema de la plataforma anterior no puede quedar puesto mientras
        // se busca el de esta.
        emblema = "";
        emblemas = [];
        if (base === "") return;

        // La clave no es una url real: es la carpeta mas una marca, para que no
        // choque con ningun archivo del cache.
        var clave = base + "#emblemas";
        if (Cache.tiene(clave)) {
            emblemas = Cache.leer(clave);
            elegirEmblema();
            return;
        }
        _probarEmblema(base, 0, []);
    }

    // Uno por vez y en orden: el resultado de cada nombre decide si hay otro.
    function _probarEmblema(dir, i, encontrados) {
        var url = dir + Platforms.nombreEmblema(i);
        var xhr = new XMLHttpRequest();
        _xhrEmblema = xhr;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            pd._xhrEmblema = null;
            // Mismo criterio que data.json: status 0 con cuerpo = existe;
            // 0 sin cuerpo (o 404) = no esta.
            var existe = (xhr.status === 200 || xhr.status === 0)
                         && xhr.responseText !== undefined && xhr.responseText.length > 0;
            if (existe) encontrados.push(url);

            // Si mientras tanto se enfoco otra plataforma, esta busqueda ya no
            // importa: ni se sigue ni se cachea a medias.
            if (dir !== pd._baseVigente) return;

            var prox = Platforms.siguienteEmblema(i, existe);
            if (prox >= 0) { pd._probarEmblema(dir, prox, encontrados); return; }

            Cache.guardar(dir + "#emblemas", encontrados);
            pd.emblemas = encontrados;
            pd.elegirEmblema();
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // Al azar entre los que hay, distinto del ULTIMO QUE SE MOSTRO en esta
    // plataforma si hay otro. El ultimo se guarda por carpeta en el cache y no
    // en `emblema`, que cargarEmblemas() vacia al cambiar de plataforma: sin
    // eso, volver a una plataforma podia repetir el mismo emblema. Con
    // ninguno, "": quien dibuja no muestra nada.
    //
    // Tambien la llama el selector al volver a verse (desde Home), para que
    // cada visita pueda traer otro.
    function elegirEmblema() {
        if (base === "") { emblema = ""; return; }
        var clave = base + "#ultimo";
        var anterior = Cache.tiene(clave) ? Cache.leer(clave) : "";
        var e = Platforms.siguiente(emblemas, anterior, Math.random);
        emblema = e ? e : "";
        Cache.guardar(clave, emblema);
    }
}
