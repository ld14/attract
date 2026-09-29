// Plataformas del selector (feature 026). Funciones puras, sin QML y sin APIs
// posteriores a Qt 5.15: las prueba tests/test_platforms.cjs con node.
//
// Una plataforma ES una coleccion de Pegasus, salvo TODAS, que no es ninguna:
// es "sin filtro" y vive solo aca, sin carpeta _platform/ en ningun lado.

var ACCENT = /^#[0-9a-fA-F]{6}$/;

// Los nombres de coleccion de un juego. `collections` es un modelo de Qt
// (count + get), no un array — mismo acceso que Search.indexGame.
function coleccionesDe(game) {
    var out = [];
    var cs = game ? game.collections : null;
    if (!cs) return out;
    for (var i = 0; i < cs.count; i++) {
        var c = cs.get(i);
        if (c && c.name) out.push({ nombre: String(c.name), corto: String(c.shortName || "") });
    }
    return out;
}

// claves: las de Catalog (paralelas a juegos), con `colecciones` y `video`.
// Devuelve TODAS en el indice 0 y despues una entrada por coleccion, por nombre.
//
// `clave` es lo que se le asigna a Catalog.coleccion: null en TODAS, el nombre
// de la coleccion en las demas. Existe para que nadie asigne `nombre`, que en
// TODAS es un texto de pantalla y como filtro dejaria Home vacio.
function lista(claves, juegos) {
    var todas = { todas: true, clave: null, nombre: "Todas las plataformas", abrev: "TODAS",
                  conteo: 0, muestra: null, videos: [] };
    // Sin prototipo: una coleccion que se llame "constructor" o "toString" no
    // puede chocar con lo que hereda un {} comun.
    var porNombre = Object.create(null);
    var nombres = [];

    for (var i = 0; i < claves.length; i++) {
        var k = claves[i];
        var g = juegos[k.i];
        todas.conteo += 1;
        if (k.video) todas.videos.push(g);

        var cs = k.colecciones || [];
        for (var j = 0; j < cs.length; j++) {
            var n = cs[j].nombre;
            var p = porNombre[n];
            if (!p) {
                p = porNombre[n] = { todas: false, clave: n, nombre: n,
                                     abrev: (cs[j].corto || n).toUpperCase(),
                                     conteo: 0, muestra: g, videos: [] };
                nombres.push(n);
            }
            p.conteo += 1;
            if (k.video) p.videos.push(g);
        }
    }

    nombres.sort(function(a, b) { return a.localeCompare(b); });
    var out = [todas];
    for (var m = 0; m < nombres.length; m++) out.push(porNombre[nombres[m]]);
    return out;
}

// data.json de plataforma. Nunca tira: ausente, corrupto o con tipos raros
// devuelve los campos vacios y quien llama cae a sus defaults.
function leerDatos(texto) {
    var out = { accent: "", abrev: "", nombre: "" };
    var d;
    try { d = JSON.parse(texto); } catch (e) { return out; }
    if (!d || typeof d !== "object") return out;
    if (typeof d.accent === "string" && ACCENT.test(d.accent)) out.accent = d.accent;
    if (typeof d.abrev === "string") out.abrev = d.abrev.trim();
    if (typeof d.nombre === "string") out.nombre = d.nombre.trim();
    return out;
}

// --- emblemas -------------------------------------------------------------
//
// Una plataforma puede tener varios emblemas: emblema.png y emblema_01.png,
// emblema_02.png, ... hasta emblema_99.png. Dos digitos a pedido del autor
// (2026-09-22): ordenan bien en el explorador de archivos y dan para 99. QML no
// puede listar una carpeta, asi que PlatformData los busca por nombre, en este
// orden, hasta el primer numero que falte (un hueco corta: con _01, _02 y _04,
// el _04 no se ve).
var MAX_EMBLEMAS = 99;

// 0 -> "emblema.png"; n -> "emblema_<nn>.png" (01..99).
function nombreEmblema(i) {
    return i === 0 ? "emblema.png" : "emblema_" + (i < 10 ? "0" : "") + i + ".png";
}

// Despues de probar el indice `i` (que existe o no), cual probar. -1 = listo.
// emblema.png puede faltar sin cortar la busqueda: se sigue con _1.
function siguienteEmblema(i, existe) {
    if (i === 0) return 1;
    if (!existe || i >= MAX_EMBLEMAS) return -1;
    return i + 1;
}

// El proximo video de la cadena —y el proximo emblema—: al azar, distinto del
// actual si hay otro.
// `azar` devuelve [0, 1) (Math.random en el theme, fijo en los tests).
function siguiente(videos, actual, azar) {
    if (!videos || videos.length === 0) return null;
    if (videos.length === 1) return videos[0];
    var candidatos = [];
    for (var i = 0; i < videos.length; i++)
        if (videos[i] !== actual) candidatos.push(videos[i]);
    return candidatos[Math.floor(azar() * candidatos.length) % candidatos.length];
}

// --- el carrusel ---------------------------------------------------------

// ◄/► con vuelta: desde la ultima se pasa a la primera y al reves.
function mover(idx, paso, n) {
    if (n <= 0) return 0;
    return ((idx + paso) % n + n) % n;
}

// X: una al azar, nunca la que ya esta enfocada (si hay otra). Sin eso, una
// de cada N veces el boton "no hace nada" y parece roto.
function alAzar(idx, n, azar) {
    if (n <= 1) return 0;
    var r = Math.floor(azar() * (n - 1)) % (n - 1);
    return r >= idx ? r + 1 : r;
}

// Las plataformas de verdad: todas menos TODAS.
function reales(plataformas) {
    return Math.max(0, (plataformas ? plataformas.length : 0) - 1);
}

// "1 PLATAFORMA", "2 PLATAFORMAS". Con una sola coleccion cargada —el caso de
// hoy en el gabinete— el plural se leia "1 PLATAFORMAS".
function cuenta(n, singular, plural) {
    return n + " " + (n === 1 ? singular : plural);
}

// Barra: "<N> JUEGOS · <M> PLATAFORMAS". N es el conteo de TODAS: un juego en
// dos colecciones es un juego, no dos.
function textoTotal(plataformas) {
    var n = plataformas && plataformas.length > 0 ? plataformas[0].conteo : 0;
    return cuenta(n, "JUEGO", "JUEGOS") + " · " + cuenta(reales(plataformas), "PLATAFORMA", "PLATAFORMAS");
}

// Linea de conteo bajo el nombre (handoff §Columna de contenido, punto 3).
function textoConteo(plataformas, idx) {
    var p = plataformas && plataformas[idx];
    if (!p) return "";
    var items = p.conteo === 0 ? "SIN ÍTEMS" : cuenta(p.conteo, "ÍTEM", "ÍTEMS");
    var m = reales(plataformas);
    return items + " · " + (p.todas ? cuenta(m, "PLATAFORMA", "PLATAFORMAS")
                                    : "PLATAFORMA " + idx + " DE " + m);
}

// Pill de la barra de Home: dice que esta filtrado y por que.
function textoFiltro(abrev, todas) {
    return todas ? "SIN FILTRO" : "FILTRO · " + abrev;
}
