// Proyeccion visual: no ordena ni modifica los estantes originales.
function columns(width) {
    return Math.max(1, Math.floor(Math.max(0, width) / 164));
}

function project(shelves, count) {
    var rows = [];
    shelves = shelves || [];
    for (var s = 0; s < shelves.length; s++) {
        var shelf = shelves[s];
        var games = shelf.juegos || [];
        var step = shelf.tipo === "catalogo" ? Math.max(1, count) : Math.max(1, games.length);
        for (var start = 0; start < Math.max(1, games.length); start += step) {
            rows.push({tipo: shelf.tipo, etiqueta: shelf.etiqueta,
                conteo: shelf.conteo, juegos: games.slice(start, start + step),
                origen: s, inicio: start, continuacion: start > 0});
        }
    }
    return rows;
}

function firstRow(rows, origin) {
    for (var i = 0; i < rows.length; i++)
        if (rows[i].origen === origin) return i;
    return 0;
}

function locate(rows, origin, game) {
    for (var r = 0; r < rows.length; r++) {
        if (rows[r].origen !== origin) continue;
        var column = rows[r].juegos.indexOf(game);
        if (column >= 0) return {row: r, column: column};
    }
    return {row: firstRow(rows, origin), column: 0};
}
