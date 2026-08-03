# Fuentes del theme

**Están en el repo, y es a propósito.** El gabinete es offline: no se pueden
pedir en runtime, así que el theme tiene que llevarlas puestas. Las tres son
de Google Fonts con licencia **OFL 1.1**, que permite redistribuirlas
incluidas en un proyecto siempre que se acompañe la licencia — de ahí los tres
`OFL-*.txt` de esta carpeta. No se borran.

| Archivo | Familia | Peso |
|---|---|---|
| `ChakraPetch-Bold.ttf` | Chakra Petch — títulos y botones | 700 |
| `Sora-Variable.ttf` | Sora — cuerpo de texto | variable |
| `JetBrainsMono-Regular.ttf` | JetBrains Mono — etiquetas, chips, HUD | 400 |

## Por qué Sora es "Variable" y no "Regular"

**Google Fonts solo la publica como fuente variable**; no existe un estático
oficial. Se probaron los repos upstream y no hay. Qt la carga en su instancia
por defecto, que para Sora es `wght 400` — justo el Regular que hace falta
para el cuerpo de texto, así que en la práctica no cambia nada.

El nombre del archivo dice lo que el archivo es. Llamarla `Sora-Regular.ttf`
habría sido mentir sobre su contenido.

## Si faltaran

El theme **carga igual**. `FontLoader` deja `name` vacío, `Tokens.qml` cae a
las fuentes del sistema (Helvetica y Courier) y se ve peor, pero nunca se
queda sin fuente — mismo criterio que el resto del theme con los datos que
faltan (`docs/CONVENCION.md` §2.3).

## Pesos que faltan

El diseño usa Chakra Petch en 500/600/700, Sora en 300–800 y JetBrains Mono en
400/500/700. Acá va **un peso por familia**: los demás los sintetiza Qt con
`font.bold` / `font.weight`, y Sora al ser variable cubre su rango entero.

Si al comparar contra el prototipo se nota la diferencia en algún peso
puntual, se baja ese `.ttf` y se agrega su `FontLoader` en `Tokens.qml` — no
antes.

## De dónde salieron

```bash
base=https://raw.githubusercontent.com/google/fonts/main/ofl
curl -L -o ChakraPetch-Bold.ttf "$base/chakrapetch/ChakraPetch-Bold.ttf"
curl -L -o Sora-Variable.ttf    "$base/sora/Sora%5Bwght%5D.ttf"
curl -L -o OFL-ChakraPetch.txt  "$base/chakrapetch/OFL.txt"
curl -L -o OFL-Sora.txt         "$base/sora/OFL.txt"
curl -L -o OFL-JetBrainsMono.txt "$base/jetbrainsmono/OFL.txt"

# JetBrains Mono: el estatico sale del repo original, no de Google Fonts
# (ahi tambien es variable)
curl -L -o JetBrainsMono-Regular.ttf \
  https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/fonts/ttf/JetBrainsMono-Regular.ttf
```
