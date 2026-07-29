"""attract - CLI.

`doctor` y `synopsis` existen. Los demas comandos llegan con los modulos:
  M4     attract skill
  M5     attract mcp
  M7     attract ingest
"""
import sys

from attract import doctor, synopsis

COMANDOS = {"doctor": doctor.main, "synopsis": synopsis.main}


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("uso: attract <comando> [args]")
        print()
        print("comandos:")
        print("  doctor [ruta] [--target windows]   validador preflight")
        print("  synopsis <set> [ruta]              escribe summary: desde _synopsis/<set>.json")
        return 0

    cmd = sys.argv[1]
    if cmd not in COMANDOS:
        print(f"comando desconocido: {cmd}", file=sys.stderr)
        return 2
    return COMANDOS[cmd](sys.argv[2:])


if __name__ == "__main__":
    raise SystemExit(main())
