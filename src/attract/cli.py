"""attract - CLI.

doctor, synopsis, mcp e ingest. Los proximos modulos del bootcamp se
agregan aca cuando existan.

`mcp_server` es la unica dependencia externa del proyecto (ADR-0012), y
esta importada arriba solo como modulo - no importa el paquete `mcp` de
PyPI hasta que se corre `attract mcp` de verdad (import perezoso adentro
de mcp_server.main()). doctor, synopsis e ingest siguen sin instalar nada
(ingest usa xml.etree.ElementTree, stdlib).
"""
import sys

from attract import doctor, ingest, mcp_server, synopsis

COMANDOS = {
    "doctor": doctor.main,
    "synopsis": synopsis.main,
    "mcp": mcp_server.main,
    "ingest": ingest.main,
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
        return 0

    cmd = sys.argv[1]
    if cmd not in COMANDOS:
        print(f"comando desconocido: {cmd}", file=sys.stderr)
        return 2
    return COMANDOS[cmd](sys.argv[2:])


if __name__ == "__main__":
    raise SystemExit(main())
