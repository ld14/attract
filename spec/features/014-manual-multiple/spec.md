# 014 · Más de un manual por juego

**Estado:** implementada (ADR-0023, `manual` como lista en `core/DocModel.qml`).

## Qué hace

Permite que un juego declare **varios** manuales (uno de uso, uno de servicio,
distintos idiomas, distintas revisiones — sin un conjunto fijo de categorías) y
que se elijan entre sí **adentro del visor**, con pestañas.

`manual` en `data.json` pasa de objeto a **lista de documentos**, cada uno con
la forma de hoy más un `label`:

```json
{
  "manual": [
    { "label": "Manual de uso",      "pages": ["p001.png"], "file": "uso.pdf" },
    { "label": "Manual de servicio", "file": "servicio.pdf" }
  ]
}
```

Con **un solo elemento**, `label` es opcional y no cambia nada de lo que se ve
hoy: es la migración que no hace falta hacer.

Reusa el mecanismo de pestañas que `DocumentViewer` ya tiene para varias
revistas (feature 006) — generalizado de `revistas`/`cambiarRevista` a
`pestanas`/`cambiarPestana`. No hay tarjeta nueva ni pantalla nueva: la fila de
CONTENIDO EXTRA sigue teniendo un elemento fijo para "Manual digitalizado".

## Por qué

Confirmado como caso real: un juego puede tener más de un manual. El contrato
de [`ADR-0014`](../../decisions/0014-manual-digitalizado.md) es singular y no
tiene dónde poner un segundo documento. El diseño y las alternativas
descartadas están en [`ADR-0023`](../../decisions/0023-manual-multiple-con-pestanas.md).

## Criterios de aceptación

- [ ] Dado un `manual` de **un** elemento sin `label`, la tarjeta y el visor se
      ven **exactamente igual que antes de esta feature** (`sf2ce`, `goldnaxe`
      sin tocar sus `data.json`).
- [ ] Dado un `manual` de **dos o más** elementos, todos con `label`, la tarjeta
      dice `"N manuales"` y el visor muestra pestañas con esos labels.
- [ ] Cambiar de pestaña adentro del visor no lo cierra ni pierde el zoom en 1×.
- [ ] Cada documento se comporta de forma independiente: uno puede tener
      `pages`, otro solo `file`, y el botón/tecla `X ABRIR PDF` (feature 012)
      aparece o no según el documento **activo**, no según el juego entero.
- [ ] Dado un `manual` de dos o más elementos con **alguno sin `label`**,
      `attract doctor` lo reporta como error.
- [ ] Dado un `manual` que es un objeto suelto (la forma vieja, pre-014),
      `attract doctor` lo reporta como error explícito, no lo interpreta mal en
      silencio.
- [ ] `attract rasterize <set>` sigue funcionando sin segundo argumento cuando
      hay un solo documento. Con más de uno, exige `attract rasterize <set>
      <label>` y rasteriza solo ese.
- [ ] El PDF de un documento se abre afuera (feature 012) sin afectar a los
      demás documentos del mismo juego.
- [ ] `make test` sigue en verde; los fixtures existentes (`sf2ce`) no cambian
      de forma.

## Fuera de alcance

- **El manual como entidad compartida entre juegos** (tipo `_magazines/`). Esta
  feature es "varios documentos de un juego", no "un documento de varios
  juegos" — eso sigue descartado por ADR-0014 y solo se reabre si empieza a
  doler la duplicación.
- **Convención automática de `label` por nombre de archivo.** Se escribe a
  mano; ver ADR-0023 §Alternativa A.
- **Scroll horizontal en la fila de pestañas.** Si un juego tiene tantos
  manuales que no entran en 1280px, es la señal de ADR-0023 §Qué habría que
  revisar, no algo que esta feature resuelve preventivamente.
- **Rasterizar todos los documentos con un solo comando.** `rasterize` sigue
  siendo por documento; un `--all` es una comodidad posterior, no parte de esto.
