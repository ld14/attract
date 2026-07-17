"""attract - CLI.

Hoy solo existe `doctor`. Los demas comandos llegan con los modulos:
  M1-M2  attract synopsis
  M4     attract skill
  M5     attract mcp
  M7     attract ingest
"""
import sys

from attract import doctor

COMANDOS = {"doctor": doctor.main}


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("uso: attract <comando> [args]")
        print()
        print("comandos:")
        print("  doctor [ruta] [--target windows]   validador preflight")
        return 0

    cmd = sys.argv[1]
    if cmd not in COMANDOS:
        print(f"comando desconocido: {cmd}", file=sys.stderr)
        return 2
    return COMANDOS[cmd](sys.argv[2:])


if __name__ == "__main__":
    raise SystemExit(main())
