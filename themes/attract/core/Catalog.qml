// El dueño único del catálogo: pestaña, orden, filtro y armado de estantes.
// Nadie más en el theme toca api.allGames ni ordena nada.
//
// POR QUE CENTRALIZADO, y no cada estante resolviendo lo suyo: ordenar 1200
// juegos significa leer propiedades de 1200 QObjects. Si esa lectura queda
// repartida entre delegates, se repite cada vez que uno se recrea al
// scrollear, sin que nadie lo note. Acá se hace UNA vez, al arrancar.
//
// LO QUE SE MIDIO Y CORRIGIO UNA CREENCIA (themes/experimentos/estantes-perf.qml,
// 2026-08-05): se creia que esa lectura era el costo dominante. No lo es.
// Ordenar por letra con las claves ya extraidas tarda 14 ms y hacerlo leyendo
// g.title dentro del comparador tarda 16: los ~12.000 accesos a propiedades
// cuestan 2 ms, y los otros 14 son localeCompare, que ningun cache evita. El
// array de claves se queda porque es gratis, no porque sea critico.
//
// El array de claves ademas resuelve otra cosa: los nombres de los campos
// quedan en un solo lugar. `rating` vuelve 0.0 por default y `releaseYear`
// vuelve 0 (docs/plataforma-pegasus.md §2); esas colisiones se manejan aca y
// no en cada pantalla.

import QtQuick 2.0

QtObject {
    id: cat

    // --- entrada: lo que el usuario elige --------------------------------

    property int pestana: 0        // indice en `pestanas`

    // 0 = ORDEN, 1 = SELECCION. design_handoff_home/sort-select-spec.md
    // §Concepto: comparten los mismos 4 criterios pero les dan un
    // significado distinto — ORDEN reordena la lista entera, SELECCION la
    // filtra a un valor puntual. Se cambia con alternarModo(), nunca a mano:
    // ese metodo es el que aplica las reglas de reseteo del §Boton 1.
    property int modo: 0

    property int criterio: 0       // indice en `criterios`
    property int direccion: 1      // 1 ascendente, -1 descendente
    property var filtro: null      // null | { campo: "letra"|"anio", valor }

    readonly property var pestanas: ["TODOS", "FAVORITOS"]
    readonly property var criterios: ["LETRA", "AÑO", "NOTA", "JUGADOS"]

    // Los criterios que el modo actual permite ciclar (Boton 2 / atajo X).
    // §Los 4 criterios: en ORDEN los 4 valen; en SELECCION solo LETRA y AÑO
    // — NOTA/JUGADOS no tienen "un valor puntual" con sentido para filtrar.
    readonly property var criteriosDisponibles:
        modo === 0 ? criterios : criterios.slice(0, 2)

    // La direccion (Boton 3) solo aparece en modo ORDEN con LETRA o AÑO.
    // §Boton 3 · En modo ORDEN: NOTA/JUGADOS no tienen reverso que alguien
    // quiera (siempre mejor/mas jugado primero).
    readonly property bool direccionAplica: modo === 0 && criterio <= 1

    // El boton de VALOR (Boton 3) es lo que aparece en su lugar en modo
    // SELECCION — ahi el criterio SIEMPRE es LETRA o AÑO por construccion
    // (criteriosDisponibles ya lo garantiza), asi que no hace falta acotarlo
    // por criterio como con direccionAplica.
    readonly property bool valorAplica: modo === 1

    // Compat: nombre viejo, lo sigue usando SortPanel para decidir si arma
    // la grilla de 26 letras o la de años. Es lo mismo que valorAplica.
    readonly property bool filtroAplica: valorAplica

    signal filtroAplicado()   // §Reseteo de navegacion

    // Boton 1. §Boton 1 — Toggle de modo:
    //   - a Seleccion con NOTA/JUGADOS activo -> el criterio cae a LETRA.
    //   - a Seleccion: el filtro se conserva SOLO si es compatible con el
    //     criterio (posiblemente ya reseteado a LETRA).
    //   - a Orden: el filtro se limpia siempre (Orden nunca filtra).
    function alternarModo() {
        modo = modo === 0 ? 1 : 0;

        if (modo === 0) {
            filtro = null;
            return;
        }

        if (criterio > 1) criterio = 0;
        if (filtro) {
            var campoDeCriterio = criterio === 0 ? "letra" : "anio";
            if (filtro.campo !== campoDeCriterio) filtro = null;
        }
    }

    // Boton 2 / atajo X. §Botón 2: cicla dentro del set permitido por el
    // modo actual — 4 valores en Orden, 2 en Seleccion.
    //
    // BUG REAL corregido el 2026-08-09: esta funcion cambiaba `criterio`
    // pero nunca revisaba si el `filtro` activo seguia siendo compatible.
    // En modo SELECCION, elegir LETRA C (filtro={campo:"letra",valor:"C"})
    // y despues ciclar a AÑO sin pasar por alternarModo() dejaba el filtro
    // VIEJO puesto mientras la grilla, el boton de valor y el sufijo del
    // estante ya mostraban AÑO — cada pieza de la pantalla contando una
    // historia distinta. El mismo principio que alternarModo() ya aplica
    // (el filtro solo vive si combina con el criterio actual) tiene que
    // valer tambien aca, no solo al cambiar de modo.
    function ciclarCriterio(paso) {
        var disp = criteriosDisponibles;
        var pos = disp.indexOf(criterios[criterio]);
        if (pos < 0) pos = 0;
        var n = disp.length;
        var nuevo = disp[(pos + paso + n) % n];
        criterio = criterios.indexOf(nuevo);

        if (modo === 1 && filtro) {
            var campoDeCriterio = criterio === 0 ? "letra" : "anio";
            if (filtro.campo !== campoDeCriterio) filtro = null;
        }
    }

    // Boton 3 en modo SELECCION, sobre una opcion de la grilla del popover.
    // §Botón 3 · En modo SELECCIÓN: clickear una opcion fija el filtro,
    // cierra el popover (lo hace quien llama, el popover no se conoce a si
    // mismo desde aca) y salta a los estantes con el catalogo ya filtrado.
    function elegirValor(valor) {
        var campo = criterio === 0 ? "letra" : "anio";
        // Volver a elegir el mismo valor lo saca — sin esto, quitar un
        // filtro obliga a abrir el popover de nuevo solo para eso.
        if (filtro && filtro.campo === campo && filtro.valor === valor)
            filtro = null;
        else
            filtro = { campo: campo, valor: valor };
        filtroAplicado();
    }

    // --- salida ----------------------------------------------------------

    // [{ tipo, etiqueta, conteo, juegos: [game] }]
    // tipo ∈ "continuar" | "jugados" | "genero" | "catalogo"
    readonly property var estantes:
        _armar(pestana, modo, criterio, direccion, filtro, _generacion)

    // CATALOGO es siempre el ultimo estante que arma _armar. Lo usa
    // BrowseScreen para el "salto a estante 0, columna 0" del §Reseteo de
    // navegacion — que en este theme, sin la numeracion literal del
    // prototipo, significa saltar al estante que de verdad muestra el
    // resultado del filtro.
    readonly property int indiceCatalogo: estantes.length - 1

    readonly property int totalPestana: _pool(pestana, null).length

    function conteoDe(i) {
        return _pool(i, null).length;
    }

    // Los años que existen de verdad en el catalogo, para la grilla del panel
    // de orden. El diseño arranca en 1978 y llega al mas nuevo que haya.
    function aniosDisponibles() {
        var max = 1978;
        for (var i = 0; i < _claves.length; i++)
            if (_claves[i].anio > max) max = _claves[i].anio;
        var out = [];
        for (var y = 1978; y <= max; y++) out.push(y);
        return out;
    }

    // --- interna ---------------------------------------------------------

    property var _juegos: []       // los game objects, en el orden de Pegasus
    property var _claves: []       // paralelo a _juegos, solo primitivas
    property int _generacion: 0    // sube cuando se recarga; despierta el binding

    Component.onCompleted: cargar()

    function cargar() {
        // toVarArray() esta en la API de Pegasus y se midio en 0 ms con el
        // catalogo de fixtures. Con 1200 reales no deberia cambiar de orden de
        // magnitud, pero es la unica linea de este archivo que no se probo a
        // escala real.
        var gs = api.allGames.toVarArray();
        var ks = [];

        for (var i = 0; i < gs.length; i++) {
            var g = gs[i];
            ks.push({
                i: i,
                // sortBy es el titulo canonico de Pegasus (sin articulos
                // iniciales); si esta vacio cae al titulo.
                orden: String(g.sortBy || g.title || "").toLowerCase(),
                inicial: _inicialDe(g.sortBy || g.title || ""),
                anio: g.releaseYear,            // 0 = sin dato, no el año cero
                nota: g.rating,                 // 0.0 = sin dato, misma colision
                jugadas: g.playCount,
                tiempo: g.playTime,
                // Un juego nunca jugado devuelve una fecha invalida, no null:
                // getTime() da NaN y un NaN dentro de un comparador desordena
                // el estante entero en silencio, porque toda comparacion con
                // NaN es false.
                ultima: _instante(g.lastPlayed),
                genero: g.genre || "",
                fav: g.favorite === true
            });
        }

        _juegos = gs;
        _claves = ks;
        _generacion += 1;
    }

    function _instante(fecha) {
        if (!fecha || typeof fecha.getTime !== "function") return 0;
        var t = fecha.getTime();
        return isNaN(t) ? 0 : t;
    }

    // La letra bajo la que se agrupa un titulo. Todo lo que no sea A-Z cae en
    // "#" — un juego que empieza con numero o con simbolo tiene que poder
    // encontrarse igual, y el diseño no le da casilla propia.
    function _inicialDe(titulo) {
        var c = String(titulo).charAt(0).toUpperCase();
        return (c >= "A" && c <= "Z") ? c : "#";
    }

    // Las claves que sobreviven a la pestaña y al filtro.
    function _pool(pest, filt) {
        var out = [];
        for (var i = 0; i < _claves.length; i++) {
            var k = _claves[i];
            if (pest === 1 && !k.fav) continue;
            if (filt) {
                if (filt.campo === "letra" && k.inicial !== filt.valor) continue;
                if (filt.campo === "anio" && k.anio !== filt.valor) continue;
            }
            out.push(k);
        }
        return out;
    }

    function _ordenar(ks, crit, dir) {
        var a = ks.slice();
        if (crit === 0)
            a.sort(function(x, y) { return dir * x.orden.localeCompare(y.orden); });
        else if (crit === 1)
            a.sort(function(x, y) { return dir * (x.anio - y.anio); });
        else if (crit === 2)
            // Sin nota (0.0) al final SIEMPRE, ordene como ordene: un juego sin
            // dato no es un juego malo, y mezclarlo con los peores seria
            // afirmar algo que nadie midio (CONVENCION #2.3).
            a.sort(function(x, y) { return (y.nota || -1) - (x.nota || -1); });
        else
            a.sort(function(x, y) { return y.jugadas - x.jugadas; });
        return a;
    }

    function _juegosDe(ks) {
        var out = [];
        for (var i = 0; i < ks.length; i++) out.push(_juegos[ks[i].i]);
        return out;
    }

    // "1.234 juegos". El separador de miles lo pone toLocaleString, igual que
    // el prototipo.
    function _cuenta(n, palabra) {
        return Number(n).toLocaleString(Qt.locale("es-ES"), "f", 0) + " " + palabra;
    }

    // Los argumentos estan de mas para el calculo — todos son propiedades de
    // este objeto — pero hacen que el binding declare sus dependencias en vez
    // de depender de que QML las descubra dentro de las funciones auxiliares.
    function _armar(pest, mod, crit, dir, filt, gen) {
        if (_claves.length === 0) return [];

        // DOS pools, no uno. El filtro de SELECCION es puntual de CATALOGO
        // (sort-select-spec.md §Efecto sobre el catálogo dice "el estante
        // CATÁLOGO muestra solo..." — no dice que CONTINUAR JUGANDO, MAS
        // JUGADOS o los generos se reduzcan tambien). `pool` es el universo
        // de la pestaña activa, sin tocar; `poolCatalogo` le suma el filtro
        // solo si el modo es SELECCION (alternarModo() ya lo limpia al
        // volver a ORDEN, pero no se confia en esa invariante desde afuera).
        var pool = _pool(pest, null);
        var poolCatalogo = (mod === 1 && filt) ? _pool(pest, filt) : pool;
        var sh = [];

        // 1. CONTINUAR JUGANDO — lo ultimo que se toco, primero.
        //
        // El handoff pide "progreso > 0" y Pegasus no expone nada parecido a un
        // progreso de partida: expone playCount, playTime y lastPlayed
        // (read-only). Asi que el estante es "lo que jugaste", ordenado por
        // cuando lo jugaste. La barra de la tarjeta mide playTime relativo, y
        // eso NO es un porcentaje de juego completado — ver Shelf.qml.
        var cont = [];
        for (var i = 0; i < pool.length; i++)
            if (pool[i].jugadas > 0) cont.push(pool[i]);
        cont.sort(function(x, y) { return y.ultima - x.ultima; });

        if (cont.length > 0) {
            sh.push({
                tipo: "continuar",
                etiqueta: "CONTINUAR JUGANDO",
                conteo: _cuenta(cont.length, "juegos"),
                juegos: _juegosDe(cont)
            });

            // 2. MAS JUGADOS — solo si hay algo jugado. El prototipo lo muestra
            //    siempre (.dc.html:500), pero un ranking donde todos tienen
            //    cero partidas no informa nada: es un top de la nada.
            var top = _ordenar(pool, 3, 1).slice(0, 12);
            sh.push({
                tipo: "jugados",
                etiqueta: "MÁS JUGADOS",
                conteo: "TOP " + top.length,
                juegos: _juegosDe(top)
            });
        }

        // 3. Hasta dos generos, los que mas titulos tengan y al menos 3.
        var porGenero = {};
        for (var j = 0; j < pool.length; j++) {
            var gnr = pool[j].genero;
            if (gnr === "") continue;          // sin genero no arma estante
            if (!porGenero[gnr]) porGenero[gnr] = [];
            porGenero[gnr].push(pool[j]);
        }
        var nombres = [];
        for (var n in porGenero)
            if (porGenero[n].length >= 3) nombres.push(n);
        nombres.sort(function(x, y) {
            return porGenero[y].length - porGenero[x].length;
        });
        for (var m = 0; m < Math.min(2, nombres.length); m++) {
            var gn = nombres[m];
            sh.push({
                tipo: "genero",
                etiqueta: gn.toUpperCase(),
                conteo: _cuenta(porGenero[gn].length, "títulos"),
                juegos: _juegosDe(porGenero[gn])
            });
        }

        // 4. CATALOGO — el unico estante que reacciona a modo/criterio/
        //    direccion/filtro. Los otros tres tienen su propio orden y no se
        //    tocan, igual que en el prototipo (.dc.html:498-509).
        //
        // sort-select-spec.md §Efecto sobre el catálogo, los tres casos:
        //   - modo ORDEN: TODOS los juegos del pool, por criterio+direccion.
        //   - modo SELECCION con filtro: SOLO los que matchean, tambien
        //     ordenados por criterio+direccion (mismo LETRA/AÑO del filtro).
        //   - modo SELECCION sin filtro todavia: "se comporta como si no
        //     hubiera filtro" — mismo caso que ORDEN.
        // Los tres colapsan a la MISMA formula porque poolCatalogo ya vale
        // pool (sin filtrar) en los dos casos que no filtran.
        var todos = _ordenar(poolCatalogo, crit, dir);

        // Un espacio a cada lado del "·", como el prototipo (:508) — el resto
        // del theme usa doble espacio para separadores de metadata, pero este
        // sufijo puntual sigue la cadena literal del diseño. Solo se muestra
        // en SELECCION con filtro activo (§Efecto sobre el catálogo, ultima
        // linea: "el título del estante refleja el filtro cuando corresponde").
        var suf = "";
        if (mod === 1 && filt)
            suf = filt.campo === "letra" ? " · LETRA " + filt.valor
                                         : " · AÑO " + filt.valor;
        sh.push({
            tipo: "catalogo",
            etiqueta: "CATÁLOGO" + suf,
            conteo: _cuenta(todos.length, "juegos"),
            juegos: _juegosDe(todos)
        });

        return sh;
    }
}
