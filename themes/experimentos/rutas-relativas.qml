// EXPERIMENTO — ¿de dónde saca el theme la ruta de media/<set>/ sin hardcodearla?
//
// Contexto: los dos experimentos ya archivados de esta carpeta
// (json-chain-test.qml y pdf-qtquick.qml) funcionan, pero ambos anotan la
// MISMA deuda conocida: la ruta base está hardcodeada al Mac del autor
// ("file:///Users/familyhouse/workplace/attract/fixtures/arcade/media/").
// Eso rompe ADR-0003 — en el gabinete Windows esa ruta no existe.
//
// El theme de producción no puede heredar esa deuda: necesita descubrir en
// runtime dónde vive media/<set>/data.json partiendo solo del objeto `api`.
//
// PREDICCIÓN: Pegasus expone los archivos de un juego en `game.files`, y de
// ahí sale la ruta absoluta de la ROM. El directorio que la contiene es el
// directorio de la colección (donde vive metadata.pegasus.txt), y de ahí
// cuelga media/<set>/. El <set> sale de x-set (game.extra["set"][0]), con
// fallback al nombre del archivo sin extensión — el bloque EXPERIMENTO del
// fixture no tiene x-set y hay que cubrirlo.
//
// PLAN B (si `game.files` no existe o no da la ruta): derivar la base de
// cualquier asset nativo — assets.boxFront devuelve una URL absoluta, y
// sacarle el nombre de archivo deja media/<set>/. Este experimento mide las
// dos vías a la vez para saber cuál usar, no solo si la primera anda.
//
// ADVERTENCIA SOBRE EL PLAN B, medida el 2026-07-29 con el harness de
// attract-debug: **el plan B no alcanza, y en un caso miente.** Tres razones,
// todas con evidencia:
//
//   a) Un asset puede ser una URL REMOTA, no un file://. Un juego que entra
//      por el provider de Steam devuelve
//      "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/
//      255710/header.jpg?t=..." en boxFront. Derivar el directorio de ahí da
//      una ruta http, no una carpeta del disco. (Ver ADR-0017: esos providers
//      se apagan, pero el theme no puede asumir que alguien lo hizo.)
//   b) El fixture TEST MULTIFILE no tiene NINGUN asset — boxFront, cartridge
//      y marquee vienen vacíos. Sin assets no hay nada de donde derivar.
//   c) El juego de library/arcade tampoco tiene assets ni x-set.
//
// Y el fallback por x-set tampoco alcanza solo: el fixture EXPERIMENTO (dino)
// NO tiene x-set. O sea que las dos vías por separado fallan en fixtures
// distintos y se complementan — por eso hace falta `files[0].path`.
//
// RESULTADO OBSERVADO: PARCIAL — `game.files` EXISTE y tiene `.count`.
// Confirmado de rebote el 2026-07-29 por el panel de diagnóstico del esqueleto
// del theme (feature 005, tarea 1), que lista `[files: N]` por juego y devolvió
// `[files: 2]` para el fixture TEST MULTIFILE y `[files: 1]` para el resto. O
// sea: `files` es un modelo de Qt con `count`, no un array de JS, y la Via 1 de
// abajo es la correcta.
//
// LO QUE SIGUE PENDIENTE, y es lo que de verdad bloquea `Paths.qml`: si
// `files.get(0).path` devuelve la ruta ABSOLUTA de la ROM. Sin eso no hay de
// dónde derivar el directorio de la colección. Correr este experimento y
// anotar acá la forma exacta que tiene ese `path`.
//
// Cómo correrlo:
//   1. cp rutas-relativas.qml <themes de Pegasus>/attract-debug/theme.qml
//   2. abrí Pegasus apuntando a fixtures/ y recorré los juegos con las flechas
//   3. anotá arriba qué vía resolvió, para qué juegos, y con qué forma exacta
//
// Los 4 juegos del fixture cubren los casos que importan:
//   mok       -> x-set presente, assets presentes, SIN data.json
//   sf2ce     -> x-set presente, assets presentes, data.json con ref colgado
//   dino      -> SIN x-set (bloque "EXPERIMENTO"), assets + data.json buenos
//   multifile -> x-set presente, DOS file:, sin assets ni data.json

import QtQuick 2.0

FocusScope {
    id: root
    focus: true

    property int idx: 0
    property var g: api.allGames.count > 0 ? api.allGames.get(idx) : null

    Rectangle { anchors.fill: parent; color: "#0d1117" }

    Text {
        anchors.centerIn: parent
        width: parent.width * 0.92
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 14
        wrapMode: Text.WrapAnywhere
        textFormat: Text.PlainText
        text: root.g ? reporte(root.g) : "Sin juegos."
    }

    function tipoDe(v) {
        if (v === undefined) return "undefined";
        if (v === null) return "null";
        if (Array.isArray(v)) return "Array[" + v.length + "]";
        return typeof v;
    }

    // Via 1: game.files. No se asume nada de su forma - puede ser un modelo de
    // Qt (con count/get) o un array de JS, o directamente no existir.
    function viaFiles(g) {
        var out = [];
        if (g.files === undefined) { out.push("  game.files: NO EXISTE"); return out; }

        out.push("  game.files            : " + tipoDe(g.files));
        out.push("  game.files.count      : " + g.files.count);
        out.push("  game.files.length     : " + g.files.length);

        var primero = null;
        if (g.files.get !== undefined && g.files.count > 0) primero = g.files.get(0);
        else if (g.files.length > 0) primero = g.files[0];

        if (primero === null) { out.push("  no pude sacar el [0]"); return out; }

        out.push("  files[0]              : " + tipoDe(primero));
        out.push("  files[0].path         : " + primero.path);
        out.push("  files[0].name         : " + primero.name);
        out.push("  DIR de la coleccion   : " + dirDe(String(primero.path)));
        return out;
    }

    // Via 2 (plan B): cualquier asset nativo. Se prueban los tres de la cadena
    // de fallback de CONVENCION 2.2 mas video, en ese orden.
    function viaAssets(g) {
        var out = [];
        var candidatos = ["boxFront", "poster", "marquee", "video"];
        var encontrado = null;
        for (var i = 0; i < candidatos.length; i++) {
            var v = g.assets[candidatos[i]];
            out.push("  assets." + candidatos[i] + " : " + (v || "(vacio)"));
            if (v && encontrado === null) encontrado = String(v);
        }
        out.push("  DIR de media/<set>/   : " + (encontrado ? dirDe(encontrado) : "NO HAY NINGUN ASSET"));
        return out;
    }

    // Corta el ultimo segmento de una ruta/URL. Deja la barra final.
    function dirDe(ruta) {
        var i = ruta.lastIndexOf("/");
        return i < 0 ? "(sin barra: " + ruta + ")" : ruta.substring(0, i + 1);
    }

    // El <set>: x-set primero, si no el basename del archivo sin extension.
    function setDe(g) {
        var xs = g.extra["set"];
        if (xs && xs[0]) return xs[0] + "   (via x-set)";

        var primero = null;
        if (g.files !== undefined) {
            if (g.files.get !== undefined && g.files.count > 0) primero = g.files.get(0);
            else if (g.files.length > 0) primero = g.files[0];
        }
        if (primero === null) return "NO SE PUDO (sin x-set y sin files)";

        var base = String(primero.path);
        base = base.substring(base.lastIndexOf("/") + 1);
        var punto = base.lastIndexOf(".");
        if (punto > 0) base = base.substring(0, punto);
        return base + "   (via basename del file:)";
    }

    function reporte(g) {
        var out = [];
        out.push("=== EXPERIMENTO: RUTAS SIN HARDCODEAR ===");
        out.push("  <- ->  navegar");
        out.push("");
        out.push("juego " + (root.idx + 1) + " de " + api.allGames.count + ": " + g.title);
        out.push("");
        out.push("--- VIA 1: game.files (la apuesta) ---");
        out = out.concat(viaFiles(g));
        out.push("");
        out.push("--- VIA 2: assets nativos (plan B) ---");
        out = out.concat(viaAssets(g));
        out.push("");
        out.push("--- el <set> ---");
        out.push("  " + setDe(g));
        return out.join("\n");
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Right) {
            root.idx = (root.idx + 1) % api.allGames.count;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.idx = (root.idx - 1 + api.allGames.count) % api.allGames.count;
            event.accepted = true;
        }
    }
}
