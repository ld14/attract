# 025 — Configurar DOS al importar COINDOOR

## Problema
Instalar un paquete MS-DOS deja los archivos sin dosbox.conf. El piloto de
Prehistorik confirmó un arranque y el usuario confirmó que funciona al aplicar
el perfil; ese conocimiento debe reutilizarse en nuevas instalaciones.

## Contrato
- Para `system: msdos` y `tratamiento: descomprimir`, generar dosbox.conf y el
  launch del juego en la misma transacción del import.
- Reconocer perfiles por hashes de archivos, nunca solamente por título.
- Prehistorik es el primer perfil probado con Staging 0.83.0; guardar fuentes
  y distinguir confirmación del usuario de pruebas automatizadas.
- Si el paquete declara `dosbox`, validar sus opciones y ejecutable relativo.
- Sin perfil ni declaración, si el árbol tiene la firma de archivos de un
  motor catalogado (Sierra AGI, Sierra SCI - `ADR-0033`) y un único ejecutable
  sin ambigüedad, aplica la config investigada para ese motor.
- Sin lo anterior, un único ejecutable DOS con nombre 8.3 permite una base
  provisional. Varios candidatos, instaladores o imágenes requieren revisión
  explícita.
- Cada instalación deja un informe en media/<set>/_dosbox.json y un mensaje CLI.
- Las configuraciones existentes se conservan al reimportar; no perder ajustes.
- Rutas sin unidad fija, emulador bajo emulators/dosbox-staging y cwd explícito.
- Sin consultas web, dependencias ni ejecución de programas durante el import.
- Assets solos, paquetes arcade y tratamiento copiar mantienen su comportamiento.

## Aceptación
1. Una copia reconocida de Prehistorik recibe SOUND=C:\ y arranque correcto.
2. Otra copia con el mismo nombre no recibe la etiqueta de perfil probado.
3. Rutas inseguras, opciones inválidas y ejecutables declarados ausentes fallan
   sin instalación parcial; probar rollback después de escribir el perfil.
4. Config y metadata son UTF-8/LF; mover la raíz no exige regenerarlos.
5. Reimportar no pisa un dosbox.conf local ni cambia su launch.

## Fuera de alcance
Enumerar el contenido de una imagen de disco sin declaración explícita
(`ADR-0034` - declarar `dosbox.imagenes`/`tipo_imagen`/`executable` sí está
en alcance), encontrar ROMs/drivers, probar jugabilidad sin usuario,
modificar COINDOOR (otro repositorio) o declarar optimizados todos los juegos.
