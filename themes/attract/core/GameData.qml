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

    // `manual` es una LISTA de documentos (ADR-0023): un juego real puede
    // tener mas de uno (manual de uso, de servicio, otro idioma). Con un solo
    // elemento -el caso de hoy- se ve exactamente igual que antes de esta ADR:
    // no hay migracion que hacer, `manualActivo` cae en el unico que hay.
    readonly property var manuales: (datos && Array.isArray(datos.manual)) ? datos.manual : []

    // Cual de los documentos esta mostrando la tarjeta/el visor ahora mismo.
    // El dueño de este indice es theme.qml (igual que magIdx con las
    // revistas); GameData solo lo usa para calcular sobre CUAL documento.
    property int manualIdx: 0

    readonly property var manualActivo:
        (manualIdx >= 0 && manualIdx < manuales.length) ? manuales[manualIdx] : null

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

    // `hayManual*` es sobre el JUEGO: hay algo que mostrar en la tarjeta si
    // ALGUN documento de la lista tiene contenido, no solo el activo - la
    // tarjeta se decide antes de entrar al visor y de elegir cual documento.
    readonly property bool hayManual: manuales.length > 0

    // Estos dos son del documento ACTIVO (ADR-0021): paginas escaneadas que
    // hojea el visor, y/o un PDF que abre el sistema operativo, del elemento
    // que este seleccionado ahora.
    readonly property bool hayManualPaginas:
        manualActivo !== null && manualActivo.pages !== undefined && manualActivo.pages.length > 0
    readonly property bool hayManualPdf:
        manualActivo !== null && typeof manualActivo.file === "string" && manualActivo.file !== ""

    // El NOMBRE del archivo del documento activo, no la ruta: la ruta la arma
    // core/Paths.
    readonly property string manualPdf: hayManualPdf ? String(manualActivo.file) : ""

    // Las pestañas del visor cuando hay mas de un manual: [{etiqueta}]. Vacio
    // con uno solo -sin fila de pestañas, como antes de ADR-0023.
    readonly property var manualPestanas: {
        if (manuales.length <= 1) return [];
        var out = [];
        for (var i = 0; i < manuales.length; i++)
            out.push({ etiqueta: String(manuales[i].label || "") });
        return out;
    }

    // --- los grupos de trucos, normalizados ------------------------------
    //
    // `cheats` acepta CUALQUIER clave, no solo combos/codes (ADR-0020). Cada
    // grupo puede venir de dos formas:
    //
    //   "combos":   [ {name, input} ]                        lista directa
    //   "secretos": { label: "...", items: [ {name, input} ] }  con titulo
    //
    // Aca las dos se aplanan a { clave, label, items } para que el overlay
    // dibuje una sola forma y no repita el "¿cual de las dos era?" por
    // seccion. El orden de las claves del JSON se respeta: es el orden en
    // que el autor las escribio, y no hay ninguno mejor que ese.
    readonly property var gruposCheats: {
        if (!cheats || typeof cheats !== "object") return [];
        var out = [];
        for (var clave in cheats) {
            var v = cheats[clave];
            var items = null;
            var label = "";

            if (Array.isArray(v)) {
                items = v;
            } else if (v && typeof v === "object" && Array.isArray(v.items)) {
                items = v.items;
                if (typeof v.label === "string") label = v.label;
            }

            if (!items || items.length === 0) continue;
            out.push({ clave: clave, label: label || _labelDe(clave), items: items });
        }
        return out;
    }

    // El titulo de un grupo sin `label` propio. combos/codes conservan el
    // texto que ya tenian; cualquier otra clave se muestra tal cual, en
    // mayusculas y sin guiones bajos ("dos_jugadores" -> "DOS JUGADORES").
    function _labelDe(clave) {
        if (clave === "combos") return "▶ COMBOS";
        if (clave === "codes") return "★ CÓDIGOS SECRETOS";
        return String(clave).replace(/_/g, " ").toUpperCase();
    }

    readonly property bool hayCheats: gruposCheats.length > 0
    readonly property bool hayReview: review !== null

    // El total de TODOS los grupos, no solo de combos/codes: con claves
    // libres, contar dos claves fijas dejaria afuera lo que el autor sumo.
    readonly property int cheatsCount: {
        var n = 0;
        for (var i = 0; i < gruposCheats.length; i++)
            n += gruposCheats[i].items.length;
        return n;
    }

    readonly property int manualPaginas: hayManualPaginas ? manualActivo.pages.length : 0

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

        // Sin esto, entrar al segundo documento de un juego y despues volver
        // al mismo -o abrir otro con menos documentos- deja manualActivo en
        // null hasta que alguien vuelva a tocar el indice a mano.
        manualIdx = 0;

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
