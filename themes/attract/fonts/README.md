# Fuentes del theme

Los `.ttf` **no están en el repo**: son de Google Fonts, con licencia OFL, y
versionarlos acá no aporta nada que no dé una descarga.

El gabinete es offline, así que tampoco se pueden pedir en runtime: tienen que
estar en esta carpeta antes de instalar el theme.

## Qué bajar

| Archivo esperado | Familia | De dónde |
|---|---|---|
| `ChakraPetch-Bold.ttf` | Chakra Petch 700 | <https://fonts.google.com/specimen/Chakra+Petch> |
| `Sora-Regular.ttf` | Sora 400 | <https://fonts.google.com/specimen/Sora> |
| `JetBrainsMono-Regular.ttf` | JetBrains Mono 400 | <https://fonts.google.com/specimen/JetBrains+Mono> |

Los nombres de archivo importan: son los que busca `Tokens.qml`. Si bajás el
zip de Google Fonts, los archivos vienen con esos nombres exactos dentro de
`static/`.

## Si faltan

El theme **carga igual**. `FontLoader` deja `name` vacío, `Tokens.qml` cae a
las fuentes del sistema (Helvetica y Courier) y el panel de diagnóstico lo
dice en pantalla: `fuentes: DEL SISTEMA - falta bajar los .ttf`.

Se ve peor, pero nunca se queda sin fuente — mismo criterio que el resto del
theme con los datos que faltan (`docs/CONVENCION.md` §2.3).

## Pesos que faltan

El diseño usa Chakra Petch en 500/600/700, Sora en 300–800 y JetBrains Mono en
400/500/700. Acá se carga **un peso por familia**: los demás los sintetiza Qt
con `font.bold` / `font.weight`, que alcanza para el esqueleto.

Si al comparar contra el prototipo se nota la diferencia en algún peso puntual,
se baja ese `.ttf` y se agrega su `FontLoader` en `Tokens.qml` — no antes.
