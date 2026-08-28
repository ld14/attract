"""attract - CLI.

Siete subcomandos: doctor, synopsis, mcp, ingest, import, rasterize y
mags. Uno nuevo se agrega a COMANDOS y a la ayuda de main(), nada mas.

Hay DOS dependencias externas, las dos opcionales y las dos con import
perezoso: `mcp` en mcp_server (ADR-0012) y `pymupdf` en rasterize
(ADR-0022). Los dos modulos estan importados aca arriba, pero ninguno
toca su paquete de PyPI hasta que se corre el comando de verdad - el
import vive adentro de la funcion. doctor, synopsis e ingest siguen sin
instalar nada (ingest usa xml.etree.ElementTree, stdlib).

Dos excepciones acotadas son una politica; una tercera significaria que
el limite stdlib-only ya no describe el proyecto y hay que reescribirlo,
no parchearlo otra vez (ADR-0022 §Que habria que revisar).
"""
import sys

from attract import doctor, ingest, instalar, magazines, mcp_server, rasterize, synopsis

COMANDOS = {
    "doctor": doctor.main,
    "synopsis": synopsis.main,
    "mcp": mcp_server.main,
    "ingest": ingest.main,
    "import": instalar.main,
    "rasterize": rasterize.main,
    "mags": magazines.main,
}


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("uso: attract <comando> [args]")
        print()
        print("comandos:")
        print("  doctor [ruta] [--target windows]   validador preflight")
        print("  synopsis <set> [ruta]              escribe summary: desde _synopsis/<set>.json")
        print("  mcp                                servidor MCP (requiere: pip install mcp)")
        print("  ingest <rom.zip> [ruta]            crea un game: nuevo via mame -listxml")
        print("  import <paquete.zip> [ruta]        instala un paquete COINDOOR (ADR-0027)")
        print("  rasterize <set> [ruta]             PDF del manual -> paginas (requiere: pip install pymupdf)")
        print("  mags [ruta] [--apply]              linkea las revistas con los juegos instalados")
        return 0

    cmd = sys.argv[1]
    if cmd not in COMANDOS:
        print(f"comando desconocido: {cmd}", file=sys.stderr)
        return 2
    return COMANDOS[cmd](sys.argv[2:])


if __name__ == "__main__":
    raise SystemExit(main())
