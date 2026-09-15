// Funciones puras; sin APIs posteriores a Qt 5.15.
function normalize(value) {
    var text = String(value || "").toLowerCase();
    var groups = [/[àáâãäå]/g, /[èéêë]/g, /[ìíîï]/g, /[òóôõö]/g, /[ùúûü]/g, /ñ/g, /ç/g];
    var letters = "aeiounc";
    for (var i = 0; i < groups.length; i++) text = text.replace(groups[i], letters[i]);
    return text.replace(/[\u0300-\u036f]/g, "").replace(/\s+/g, " ").trim();
}

function indexGame(game) {
    var fields = [game.title, game.genre, game.developer, game.publisher];
    if (game.releaseYear > 0) fields.push(String(game.releaseYear));
    var collections = game.collections;
    if (collections) {
        for (var i = 0; i < collections.count; i++) {
            var collection = collections.get(i);
            fields.push(collection.name);
            fields.push(collection.shortName);
        }
    }
    return fields.map(normalize).join("\n");
}

function matches(index, query) {
    var normalized = normalize(query);
    if (!normalized) return false;
    var words = normalized.split(" ");
    for (var i = 0; i < words.length; i++) {
        if (index.indexOf(words[i]) < 0) return false;
    }
    return true;
}
