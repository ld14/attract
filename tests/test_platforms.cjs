// Ejecutar: node tests/test_platforms.cjs (sin dependencias). Feature 026.
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function load(file, extra = {}) {
    const ctx = vm.createContext(extra);
    vm.runInContext(fs.readFileSync(path.join(__dirname,
        '../themes/attract/core', file), 'utf8'), ctx);
    return ctx;
}

const P = load('Platforms.js');

// Un modelo de Qt de mentira: count + get(i), no un array.
function colls(...names) {
    return {count: names.length, get: i => ({name: names[i], shortName: names[i].slice(0, 3)})};
}

// Con jugadas, fecha y genero: sin eso _armar solo arma CATALOGO y "todos los
// estantes" seria un estante solo. `video: ''` es lo que Pegasus devuelve
// cuando no hay (assets.* son strings, nunca undefined).
function game(title, col, {video = false, fav = false, jugadas = 0, genero = 'Accion'} = {}) {
    return {title, favorite: fav, releaseYear: 1990, genre: genero,
        playCount: jugadas, playTime: jugadas * 60,
        lastPlayed: jugadas ? new Date(2026, 0, jugadas) : new Date(NaN),
        collections: colls(...[].concat(col)),
        assets: {video: video ? 'file:///v/' + title + '.mp4' : ''}};
}

// Los arrays del contexto vm tienen otro prototipo: deepEqual estricto los
// rechaza aunque el contenido sea igual.
const plain = a => Array.from(a);

function catalog(games) {
    const source = fs.readFileSync(path.join(__dirname,
        '../themes/attract/core/Catalog.qml'), 'utf8');
    const methods = source.match(/^    function [\s\S]*?^    }/gm).join('\n');
    const ctx = vm.createContext({Search: load('Search.js'), Platforms: P,
        api: {allGames: {toVarArray: () => games}},
        // _cuenta formatea con Qt.locale; aca alcanza con el numero.
        Qt: {locale: () => undefined},
        _juegos: [], _claves: [], _generacion: 0, coleccion: null,
        pestana: 0, modo: 0, criterio: 0, direccion: 1, filtro: null});
    vm.runInContext(methods, ctx);
    ctx.cargar();
    return ctx;
}

const JUEGOS = [
    game('Final Fight', 'Arcade', {video: true, jugadas: 3}),
    game('Metal Slug', 'Arcade', {video: true, fav: true}),
    game('Dino', 'Arcade', {jugadas: 1}),
    game('Prehistorik', 'MS-DOS', {fav: true, jugadas: 2}),
    game('Elvira', 'MS-DOS'),
    game('Goldaxe', 'MS-DOS'),
];

test('la lista tiene TODAS primero y una entrada por coleccion, por nombre', () => {
    const cat = catalog(JUEGOS);
    const l = P.lista(cat._claves, cat._juegos);
    assert.deepEqual(plain(l.map(p => p.nombre)), ['Todas las plataformas', 'Arcade', 'MS-DOS']);
    assert.equal(l[0].todas, true);
    assert.equal(l[0].abrev, 'TODAS');
    assert.deepEqual(plain(l.map(p => p.conteo)), [6, 3, 3]);
    assert.equal(l[1].abrev, 'ARC');
    assert.equal(l[2].muestra, JUEGOS[3]);
    assert.equal(l[0].videos.length, 2);
    assert.equal(l[2].videos.length, 0);
});

test('clave: null en TODAS y el nombre de la coleccion en las demas', () => {
    const cat = catalog(JUEGOS);
    const l = P.lista(cat._claves, cat._juegos);
    assert.deepEqual(plain(l.map(p => p.clave)), [null, 'Arcade', 'MS-DOS']);
});

test('una coleccion con nombre de propiedad heredada no se pierde', () => {
    const cat = catalog([game('X', 'constructor'), game('Y', 'toString')]);
    const l = P.lista(cat._claves, cat._juegos);
    assert.deepEqual(plain(l.map(p => p.nombre)),
        ['Todas las plataformas', 'constructor', 'toString']);
});

test('sin juegos la lista es solo TODAS con conteo cero', () => {
    const l = P.lista([], []);
    assert.equal(l.length, 1);
    assert.equal(l[0].conteo, 0);
});

test('un juego en dos colecciones cuenta en las dos y una vez en TODAS', () => {
    const cat = catalog([game('Out Run', ['Arcade', 'MS-DOS'])]);
    const l = P.lista(cat._claves, cat._juegos);
    assert.deepEqual(plain(l.map(p => p.conteo)), [1, 1, 1]);
});

test('coleccion recorta los cuatro tipos de estante y sus conteos', () => {
    const cat = catalog(JUEGOS);
    const todos = cat._armar(0, 0, 0, 1, null, null, 0);
    assert.deepEqual(plain(todos.map(e => e.tipo)), ['continuar', 'jugados', 'genero', 'catalogo']);
    assert.equal(todos[3].juegos.length, 6);

    // Por ARGUMENTO, sin tocar cat.coleccion: _armar filtra por lo que recibe.
    const sh = cat._armar(0, 0, 0, 1, null, 'MS-DOS', 0);
    assert.deepEqual(plain(sh.map(e => e.tipo)), ['continuar', 'jugados', 'genero', 'catalogo']);
    for (const e of sh)
        for (const g of e.juegos)
            assert.equal(g.collections.get(0).name, 'MS-DOS', e.tipo + ': ' + g.title);
    assert.deepEqual(plain(sh.map(e => e.juegos.length)), [1, 3, 3, 3]);
    assert.equal(sh[0].conteo, '1 juegos');
    assert.equal(sh[3].conteo, '3 juegos');
});

test('conteoDe y el filtro de SELECCION respetan la coleccion', () => {
    const cat = catalog(JUEGOS);
    cat.coleccion = 'MS-DOS';
    assert.equal(cat.conteoDe(0), 3);
    assert.equal(cat.conteoDe(1), 1);   // favoritos dentro de MS-DOS
    const sel = cat._armar(0, 1, 0, 1, {campo: 'letra', valor: 'E'}, 'MS-DOS', 0);
    assert.deepEqual(plain(sel[sel.length - 1].juegos.map(g => g.title)), ['Elvira']);

    cat.coleccion = null;
    assert.equal(cat.conteoDe(0), 6);
});

test('undefined es sin filtro, y una coleccion que no existe deja solo CATALOGO vacio', () => {
    const cat = catalog(JUEGOS);
    cat.coleccion = undefined;
    assert.equal(cat.conteoDe(0), 6);
    const sh = cat._armar(0, 0, 0, 1, null, 'NoExiste', 0);
    assert.deepEqual(plain(sh.map(e => [e.tipo, e.juegos.length])).map(plain), [['catalogo', 0]]);
});

test('buscar ignora la plataforma elegida', () => {
    const cat = catalog(JUEGOS);
    cat.coleccion = 'MS-DOS';
    assert.equal(cat.buscar('final')[0], JUEGOS[0]);
});

// Las funciones reales de Paths.qml.
function paths() {
    const source = fs.readFileSync(path.join(__dirname,
        '../themes/attract/core/Paths.qml'), 'utf8');
    const methods = source.match(/^    function [\s\S]*?^    }/gm).join('\n');
    const ctx = vm.createContext({});
    vm.runInContext(methods, ctx);
    return ctx;
}
const conArchivo = ruta => ({files: {count: 1, get: () => ({path: ruta})}});

test('los assets de plataforma viven en <coleccion>/_platform/ (ADR-0035)', () => {
    const pa = paths();
    // DOS: el `file:` es una carpeta, sin barra final.
    assert.equal(pa.plataformaDe(conArchivo('D:/x/library/msdos/elvira')),
        'file:///D:/x/library/msdos/_platform/');
    assert.equal(pa.plataformaDe(conArchivo('/Users/a/fixtures/arcade/dino.zip')),
        'file:///Users/a/fixtures/arcade/_platform/');
    assert.equal(pa.plataformaDe(conArchivo('steam:255710')), '');
    assert.equal(pa.plataformaDe(null), '');
});

test('data.json ausente, corrupto o con tipos raros no tira y deja campos vacios', () => {
    const vacio = {accent: '', abrev: '', nombre: ''};
    assert.deepEqual({...P.leerDatos('')}, vacio);
    assert.deepEqual({...P.leerDatos('{roto')}, vacio);
    assert.deepEqual({...P.leerDatos('null')}, vacio);
    assert.deepEqual({...P.leerDatos('{"accent": "rojo", "abrev": 3}')}, vacio);
    assert.deepEqual({...P.leerDatos('{"accent":"#19E3E3","abrev":" DOS ","nombre":"MS-DOS"}')},
        {accent: '#19E3E3', abrev: 'DOS', nombre: 'MS-DOS'});
});

test('siguiente nunca repite el actual si hay otro, y con cero videos da null', () => {
    const vs = ['a', 'b', 'c'];
    const vistos = new Set();
    for (let i = 0; i < 30; i++) {
        const r = i / 30;
        const n = P.siguiente(vs, 'b', () => r);
        assert.notEqual(n, 'b');
        vistos.add(n);
    }
    assert.deepEqual([...vistos].sort(), ['a', 'c']);
    assert.equal(P.siguiente(['solo'], 'solo', Math.random), 'solo');
    assert.equal(P.siguiente([], null, Math.random), null);
});

test('el carrusel da la vuelta en los dos sentidos', () => {
    assert.equal(P.mover(2, 1, 3), 0);
    assert.equal(P.mover(0, -1, 3), 2);
    assert.equal(P.mover(1, 1, 3), 2);
    assert.equal(P.mover(0, 1, 0), 0);
});

test('X nunca cae en la plataforma enfocada si hay otra', () => {
    for (let idx = 0; idx < 4; idx++) {
        const vistos = new Set();
        for (let i = 0; i < 30; i++) {
            const r = P.alAzar(idx, 4, () => i / 30);
            assert.notEqual(r, idx);
            assert.ok(r >= 0 && r < 4);
            vistos.add(r);
        }
        assert.equal(vistos.size, 3);
    }
    assert.equal(P.alAzar(0, 1, Math.random), 0);
});

test('textos de la barra, del conteo y de la pill de Home', () => {
    const cat = catalog(JUEGOS);
    const l = P.lista(cat._claves, cat._juegos);
    assert.equal(P.textoTotal(l), '6 JUEGOS · 2 PLATAFORMAS');
    assert.equal(P.textoConteo(l, 0), '6 ÍTEMS · 2 PLATAFORMAS');
    assert.equal(P.textoConteo(l, 2), '3 ÍTEMS · PLATAFORMA 2 DE 2');
    assert.equal(P.textoConteo([{todas: false, conteo: 0}], 0).split(' · ')[0], 'SIN ÍTEMS');
    assert.equal(P.textoTotal([]), '0 JUEGOS · 0 PLATAFORMAS');
    // Una sola coleccion (el gabinete hoy): singular, no "1 PLATAFORMAS".
    const una = P.lista(catalog([game('Elvira', 'Msdos')])._claves, [JUEGOS[0]]);
    assert.equal(P.textoTotal(una), '1 JUEGO · 1 PLATAFORMA');
    assert.equal(P.textoConteo(una, 0), '1 ÍTEM · 1 PLATAFORMA');
    assert.equal(P.textoFiltro('DOS', false), 'FILTRO · DOS');
    assert.equal(P.textoFiltro('TODAS', true), 'SIN FILTRO');
});

// Recorre la busqueda de PlatformData con un disco de mentira: que nombres
// pide, en que orden, y cuales encuentra.
function buscarEmblemas(existentes) {
    const pedidos = [], encontrados = [];
    let i = 0;
    while (i >= 0) {
        const n = P.nombreEmblema(i);
        pedidos.push(n);
        const existe = existentes.includes(n);
        if (existe) encontrados.push(n);
        i = P.siguienteEmblema(i, existe);
    }
    return {pedidos, encontrados};
}

test('emblemas: emblema.png y emblema_<nn>.png hasta el primer numero que falte', () => {
    assert.equal(P.nombreEmblema(0), 'emblema.png');
    assert.equal(P.nombreEmblema(3), 'emblema_03.png');
    assert.equal(P.nombreEmblema(12), 'emblema_12.png');
    assert.equal(P.nombreEmblema(99), 'emblema_99.png');

    // Sin ninguno: prueba emblema.png y emblema_1.png, y termina.
    assert.deepEqual(buscarEmblemas([]).pedidos, ['emblema.png', 'emblema_01.png']);

    // emblema.png faltante no corta la busqueda.
    assert.deepEqual(buscarEmblemas(['emblema_01.png', 'emblema_02.png']).encontrados,
        ['emblema_01.png', 'emblema_02.png']);

    // Sin cero adelante NO vale: emblema_1.png no es emblema_01.png.
    assert.deepEqual(buscarEmblemas(['emblema_1.png']).encontrados, []);

    // Un hueco si corta: _4 queda afuera.
    assert.deepEqual(buscarEmblemas(['emblema.png', 'emblema_01.png', 'emblema_02.png', 'emblema_04.png']).encontrados,
        ['emblema.png', 'emblema_01.png', 'emblema_02.png']);

    // Tope: nunca pide mas alla de MAX_EMBLEMAS.
    const todos = Array.from({length: 120}, (_, k) => P.nombreEmblema(k));
    const r = buscarEmblemas(todos);
    assert.equal(P.MAX_EMBLEMAS, 99);
    assert.equal(r.encontrados.length, 100);
    assert.equal(r.pedidos[r.pedidos.length - 1], 'emblema_99.png');
});
