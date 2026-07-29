# Misión

## Qué construimos

Una fábrica de metadata y assets para un frontend Pegasus de máquina
recreativa: cae una ROM, ATTRACT arma la estructura de archivos, y la
pantalla se genera sola con lo que haya.

## Para quién

El autor, para su propio gabinete arcade (Windows en producción, macOS en
desarrollo) — y de paso, el proyecto guía del Módulo 0 de su bootcamp de
ingeniería con IA.

## Qué problema resuelve

Ingesta manual de metadata no escala: miles de juegos, la enorme mayoría sin
scans ni manual ni combos, para siempre. El dolor no es "curar bien un juego",
es "un juego pelado tiene que andar igual, y si seis meses después aparece un
scan, hay que poder sumarlo sin rehacer nada" — enriquecimiento progresivo,
no curación masiva de una sola pasada.

## Cómo sabemos que funciona

- Toda decisión se valida contra **Striker** (el completo) **y** contra
  **Maze of the Kings** (el desnudo, con todos los campos ricos en null). Si
  solo funciona con Striker, no funciona.
- `attract doctor` no reporta errores contra la librería real (`make doctor-lib`)
  antes de viajar al gabinete Windows.
- Lo que Windows rechazaría falla en el Mac, no en el gabinete.

## Qué NO somos

- No es curación masiva ni un scraper que completa todo de una vez.
- No depende de servicios pagos ni de IA en el camino crítico del `doctor`.
- El `doctor` no necesita Windows ni las ROMs reales para correr.
