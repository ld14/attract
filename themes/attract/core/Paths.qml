// Resuelve en runtime dónde viven los datos ricos de un juego. Es el único
// lugar del theme que sabe armar una ruta: nadie más concatena directorios.
//
// El problema que resuelve: los dos experimentos archivados de
// themes/experimentos/ funcionan pero hardcodean la ruta al Mac del autor, y
// los dos lo anotan como deuda que rompe ADR-0003. Este componente paga esa
// deuda — no hay una sola ruta absoluta en todo el theme.
//
// COMO FUNCIONA, y por qué así (medido contra Pegasus real el 2026-08-02, ver
// themes/experimentos/rutas-relativas.qml #RESULTADO OBSERVADO):
//
//   files[0].path  ->  /Users/…/fixtures/arcade/dino.zip
//   dirname        ->  /Users/…/fixtures/arcade/          (dir de la coleccion)
//   + media/<set>/ ->  /Users/…/fixtures/arcade/media/dino/
//
// El <set> sale de x-set, y si no está, de files[0].name — que Pegasus
// devuelve YA sin extensión ("dino", no "dino.zip"). El fixture EXPERIMENTO no
// tiene x-set justamente para cubrir ese camino.
//
// CUATRO TRAMPAS, las cuatro con evidencia, no supuestas:
//
//   1. `files[0].path` viene SIN esquema, pero los assets vienen CON él
//      ("file:///Users/…"). Para un XMLHttpRequest hace falta el esquema, asi
//      que se agrega acá y en un solo lugar.
//   2. `path` no siempre es una ruta de disco. Un juego del provider de Steam
//      devuelve "steam:255710" — un URI sin ninguna barra. Se detecta y se
//      devuelve "" (sin datos ricos), no una ruta invalida.
//   3. El plan B -derivar el directorio de un asset- esta DESCARTADO, no es un
//      fallback que quedo sin escribir. Falla en tres casos reales medidos: un
//      asset puede ser una URL remota (Steam devuelve https://…), TEST
//      MULTIFILE no tiene ningun asset, y el juego de library/arcade tampoco.
//   4. `conEsquema()` concatena SIN percent-encoding. Para XMLHttpRequest e
//      Image viene funcionando y no se toca. Pero lo que sale de acá para el
//      SISTEMA OPERATIVO (manualPdfDe) si se codifica: ver el comentario de
//      esa funcion.
//
// Y una cosa que NO es una ruta y vive acá igual: abrirAfuera(). Es lo unico
// del theme que le habla al sistema operativo. Esta acá porque theme.qml ya
// instancia este objeto y lo baja a todas las pantallas, asi que un archivo
// propio para una funcion de cuatro lineas seria cableado nuevo a cambio de
// nada. Si crece, se muda.
//
// No es un singleton a proposito (ver spec/features/005-theme-base/plan.md):
// se instancia una vez en theme.qml con un id. Un singleton en subcarpeta
// necesita su propio qmldir y es el mecanismo del que menos se sabe contra
// este binario; se usa el que hace falta y no se apuesta al otro.

import QtQuick 2.0

QtObject {
    id: paths

    // --- API publica -----------------------------------------------------

    // El <set> de un juego: x-set, o el basename del archivo si no esta.
    // "" si no se puede determinar (juego sin x-set y sin archivos).
    function setDe(game) {
        if (!game) return "";

        var xs = game.extra ? game.extra["set"] : undefined;
        if (xs && xs[0]) return String(xs[0]);

        var f = primerArchivo(game);
        return f ? String(f.name) : "";
    }

    // media/<set>/ del juego, como URL lista para XMLHttpRequest o Image.
    // "" cuando el juego no vive en el disco (Steam y compania) o no se le
    // pudo sacar el set. Devolver "" y no una ruta rota es lo que hace que el
    // theme degrade en vez de romperse (CONVENCION #2.3).
    function baseDe(game) {
        var dir = dirColeccionDe(game);
        var set = setDe(game);
        if (dir === "" || set === "") return "";
        return dir + "media/" + set + "/";
    }

    // data.json del juego. "" si no hay base.
    function dataJsonDe(game) {
        var base = baseDe(game);
        return base === "" ? "" : base + "data.json";
    }

    // <raiz-libreria>/_magazines/<ref>/ — la revista no cuelga de ningun
    // sistema: la misma revista cubre juegos de arcade, NES y PC a la vez
    // (ADR-0024), asi que vivir adentro de uno obligaria a copiarla en los
    // tres. Sube UN nivel desde el directorio de la coleccion, que es lo que
    // Pegasus tiene en game_dirs.txt:
    //
    //   dirColeccion  ->  /Users/…/library/arcade/
    //   + ../_magazines/  ->  /Users/…/library/_magazines/
    //
    // El ".." no se resuelve aca a proposito: es un file:// URL y tanto
    // XMLHttpRequest como Image lo normalizan solos. Colapsarlo a mano seria
    // reimplementar path normalization para no ganar nada.
    function magazineDe(game, ref) {
        var dir = dirColeccionDe(game);
        if (dir === "" || !ref) return "";
        return dir + "../_magazines/" + ref + "/";
    }

    function magazineJsonDe(game, ref) {
        var base = magazineDe(game, ref);
        return base === "" ? "" : base + "magazine.json";
    }

    // media/<set>/_manual/ (ADR-0014).
    function manualDe(game) {
        var base = baseDe(game);
        return base === "" ? "" : base + "_manual/";
    }

    // El PDF del manual, listo para abrirAfuera() (ADR-0021). "" si no hay
    // base o no hay nombre.
    //
    // Trampa 4: esto NO va a un XMLHttpRequest, va al sistema operativo. En
    // macOS se midio que las dos formas abren, cruda y codificada
    // (themes/experimentos/abrir-url-externa.qml). Se codifica igual, por dos
    // motivos: es la forma canonica de un file:// URL, y Windows va por
    // ShellExecuteW, que es otro camino y todavia no se midio.
    //
    // Solo el NOMBRE. El directorio ya viene con esquema y barras desde
    // conEsquema(), y codificarlo convertiria las "/" en "%2F".
    function manualPdfDe(game, nombre) {
        var base = manualDe(game);
        if (base === "" || !nombre) return "";
        return base + encodeURIComponent(nombre);
    }

    // Le pasa un documento al sistema operativo para que lo abra la aplicacion
    // predeterminada del usuario (ADR-0021). El theme no nombra ningun visor.
    //
    // Devuelve si el SO ACEPTO el pedido, que no es lo mismo que si el visor
    // arranco — eso no se puede saber, igual que con game.launch(). Lo que si
    // se midio es que una ruta inexistente devuelve false, asi que el `false`
    // alcanza para avisar.
    function abrirAfuera(url) {
        if (!url) return false;
        var ok = Qt.openUrlExternally(url);
        console.log("ATTRACT: abrir afuera " + url + " -> " + ok);
        return ok;
    }

    // --- interna ---------------------------------------------------------

    // `files` es un modelo de Qt: tiene count y get(), NO length.
    function primerArchivo(game) {
        if (!game || game.files === undefined) return null;
        if (game.files.count === undefined || game.files.count < 1) return null;
        return game.files.get(0);
    }

    // El directorio de la coleccion, como URL con esquema y barra final.
    // Es de donde cuelga media/. "" si el juego no esta en el disco.
    function dirColeccionDe(game) {
        var f = primerArchivo(game);
        if (!f || !f.path) return "";

        var ruta = String(f.path);

        // Trampa 2: "steam:255710" no es una ruta. Sin barra no hay directorio
        // que sacar, y cualquier cosa que construyamos seria basura.
        var corte = ruta.lastIndexOf("/");
        if (corte < 0) return "";

        return conEsquema(ruta.substring(0, corte + 1));
    }

    // Trampa 1: `path` viene pelado y XMLHttpRequest necesita el esquema.
    // En Windows la ruta arranca con "C:/" y no con "/", asi que lleva una
    // barra mas (ADR-0003 — el gabinete es Windows, esto no es teorico).
    function conEsquema(ruta) {
        if (ruta.indexOf("file://") === 0) return ruta;
        return ruta.charAt(0) === "/" ? "file://" + ruta : "file:///" + ruta;
    }
}
