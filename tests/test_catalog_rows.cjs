// Ejecutar: node tests/test_catalog_rows.cjs (sin dependencias).
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const rows = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname,
    '../themes/attract/core/CatalogRows.js'), 'utf8'), rows);

test('el ancho limita las tarjetas incluso con el crecimiento del foco', () => {
    for (const width of [164, 327, 328, 1168, 1184, 1600, 2400]) {
        const columns = rows.columns(width);
        const cell = width / columns;
        assert.ok(cell >= 164);
        assert.ok((columns - 1) * cell + 148 + 148 * .025 <= width);
    }
    assert.equal(rows.columns(327), 1);
    assert.equal(rows.columns(328), 2);
});

test('1200 juegos conservan orden e identidad sin duplicados y sin mutar el modelo', () => {
    const games = Array.from({length: 1200}, (_, id) => Object.freeze({id}));
    const source = Object.freeze([{tipo: 'catalogo', juegos: Object.freeze(games)}]);
    for (const columns of [1, 7, 8, 13]) {
        const projected = rows.project(source, columns);
        assert.equal(projected.length, Math.ceil(1200 / columns));
        const flattened = Array.from(projected).flatMap(row => Array.from(row.juegos));
        assert.deepEqual(flattened, games);
        assert.equal(projected.filter(row => !row.continuacion).length, 1);
        assert.ok(projected.every(row => row.juegos.length <= columns));
    }
});

test('catalogo vacio conserva encabezado y no elimina otros estantes', () => {
    const projected = rows.project([{tipo: 'continuar', juegos: [1, 2, 3]},
        {tipo: 'catalogo', juegos: []}], 2);
    assert.equal(projected.length, 2);
    assert.equal(projected[0].juegos.length, 3);
    assert.equal(projected[1].juegos.length, 0);
    assert.equal(rows.firstRow(projected, 1), 1);
    assert.equal(rows.project([], 7).length, 0);
    assert.equal(rows.project(undefined, 7).length, 0);
});

test('redimensionar mantiene el juego aunque cambien fila y columna', () => {
    const games = Array.from({length: 16}, (_, id) => ({id}));
    const source = [{tipo: 'genero', juegos: games}, {tipo: 'catalogo', juegos: games}];
    const before = rows.project(source, 7);
    const after = rows.project(source, 8);
    const a = rows.locate(before, 1, games[14]);
    const b = rows.locate(after, 1, games[14]);
    assert.equal(a.row, 3);
    assert.equal(a.column, 0);
    assert.equal(b.row, 2);
    assert.equal(b.column, 6);
    assert.equal(after[b.row].juegos[b.column], games[14]);
    assert.equal(rows.locate(after, 1, {}).row, 1);
});
