const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const search = vm.createContext({});
vm.runInContext(fs.readFileSync(require('node:path').join(__dirname,
    '../themes/attract/core/Search.js'), 'utf8'), search);
const game = {title: 'Street Fighter II', genre: 'Lucha', developer: 'Capcom',
    publisher: 'Distribuidora', releaseYear: 1992,
    collections: {count: 2, get: i => [{name: 'Arcade', shortName: 'mame'},
        {name: 'Clásicos', shortName: 'clasicos'}][i]}};

test('todos los campos y colecciones se buscan sin selector', () => {
    const index = search.indexGame(game);
    for (const query of ['fighter', 'lucha', 'capcom', 'distribuidora', 'arcade', 'mame', 'clasicos', '1992'])
        assert.equal(search.matches(index, query), true, query);
});
test('combina palabras entre campos, sin importar orden, mayusculas o tildes', () => {
    const index = search.indexGame(game);
    assert.equal(search.matches(index, '  CAPCOM   1992 clásICOS  '), true);
    assert.equal(search.matches(index, '1992 fighter'), true);
    assert.equal(search.matches(index, 'capcom 1993'), false);
    assert.equal(search.normalize('ACCIÓN acción accio\u0301n'), 'accion accion accion');
});
test('consulta vacia, datos ausentes y anio centinela no inventan resultados', () => {
    const index = search.indexGame({title: 'Ejemplo', releaseYear: 0});
    for (const query of ['', '   ', '0', 'undefined', 'null'])
        assert.equal(search.matches(index, query), false);
});
test('signos se interpretan literalmente, no como expresiones regulares', () => {
    const index = search.indexGame({title: 'A+B (1990)'});
    assert.equal(search.matches(index, 'a+b'), true);
    assert.equal(search.matches(index, '.*'), false);
});
