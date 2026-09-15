const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function catalog(games) {
    const search = vm.createContext({});
    vm.runInContext(fs.readFileSync(path.join(__dirname,
        '../themes/attract/core/Search.js'), 'utf8'), search);
    const source = fs.readFileSync(path.join(__dirname,
        '../themes/attract/core/Catalog.qml'), 'utf8');
    const methods = source.match(/^    function [\s\S]*?^    }/gm).join('\n');
    const context = vm.createContext({Search: search,
        api: {allGames: {toVarArray: () => games}},
        _juegos: [], _claves: [], _generacion: 0,
        pestana: 1, modo: 1, criterio: 1, direccion: -1,
        filtro: {campo: 'anio', valor: 1992}});
    vm.runInContext(methods, context);
    context.cargar();
    return context;
}

test('marcar desde detalle actualiza el contador y pool sin reiniciar', () => {
    const game = {title: 'Street Fighter II', releaseYear: 1992, favorite: false};
    const cat = catalog([game]);
    assert.equal(cat.conteoDe(1), 0);
    const generation = cat._generacion;
    cat.alternarFavorito(game);
    assert.equal(game.favorite, true);
    assert.equal(cat.conteoDe(1), 1);
    assert.equal(cat._juegosDe(cat._pool(1, null))[0], game);
    assert.ok(cat._generacion > generation);
});

test('quitar el ultimo favorito vacia favoritos y conserva todos y filtros', () => {
    const game = {title: 'Ejemplo', favorite: true, releaseYear: 1992};
    const cat = catalog([game]);
    const filter = cat.filtro;
    cat.alternarFavorito(game);
    assert.equal(game.favorite, false);
    assert.equal(cat.conteoDe(1), 0);
    assert.equal(cat.conteoDe(0), 1);
    assert.equal(cat.filtro, filter);
    assert.equal(cat.pestana, 1);
    assert.equal(cat.modo, 1);
    assert.equal(cat.criterio, 1);
    assert.equal(cat.direccion, -1);
    assert.equal(cat.buscar('ejemplo')[0], game);
});

test('alternar afecta solo al juego elegido y acepta ausencia de juego', () => {
    const a = {title: 'A', favorite: true};
    const b = {title: 'B', favorite: false};
    const cat = catalog([a, b]);
    cat.alternarFavorito(b);
    assert.equal(cat.conteoDe(1), 2);
    cat.alternarFavorito(b);
    cat.alternarFavorito(null);
    assert.equal(cat.conteoDe(1), 1);
    assert.equal(a.favorite, true);
});
