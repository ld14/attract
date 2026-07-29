"""
attract mcp - servidor MCP que expone doctor y synopsis a clientes MCP.

ATTRACT es stdlib-only, con UNA excepcion acotada (ADR-0012): el SDK `mcp`
solo lo necesita este modulo, y solo si de verdad se corre `attract mcp`.
El import de `mcp` esta DENTRO de main(), nunca al tope del archivo - asi
`attract doctor` y `attract synopsis` siguen andando sin instalar nada,
aunque `mcp` no este presente. No importar `mcp` fuera de main() a
proposito: es la unica garantia real de que el resto del proyecto no
depende de esto.
"""

from __future__ import annotations

import sys
from pathlib import Path

from attract import doctor as doctor_mod
from attract import synopsis as synopsis_mod


def _run_doctor(ruta: str, target: str = "windows") -> dict:
    """Corre attract doctor sobre <ruta> y devuelve un dict serializable -
    la misma logica que ya usa attract.doctor.revisar(), sin duplicarla."""
    rep = doctor_mod.revisar(Path(ruta).resolve(), target)
    return {
        "ok": rep.ok,
        "archivos_vistos": rep.archivos_vistos,
        "chequeos_corridos": rep.chequeos_corridos,
        "errores": [
            {"chequeo": h.chequeo, "ruta": h.ruta, "detalle": h.detalle}
            for h in rep.errores
        ],
        "avisos": [
            {"chequeo": h.chequeo, "ruta": h.ruta, "detalle": h.detalle}
            for h in rep.avisos
        ],
    }


def _run_synopsis(set_id: str, ruta: str) -> dict:
    """Corre attract synopsis <set_id> sobre <ruta> y devuelve un dict
    serializable - misma logica que attract.synopsis.main(), sin duplicarla."""
    raiz = Path(ruta)
    metadata_path = raiz / "metadata.pegasus.txt"
    if not metadata_path.exists():
        return {"ok": False, "error": f"no existe {metadata_path}"}

    try:
        texto = synopsis_mod.leer_fuente(raiz, set_id)
        synopsis_mod.aplicar(metadata_path, set_id, texto)
    except synopsis_mod.SynopsisError as e:
        return {"ok": False, "error": str(e)}

    return {"ok": True, "set": set_id, "summary": texto}


def _construir_app():
    """Import perezoso de mcp + registro de tools. Separado de main() para
    poder testearlo sin levantar el loop de stdio."""
    from mcp.server.mcpserver import MCPServer

    app = MCPServer(
        "attract",
        instructions=(
            "Valida y enriquece una libreria de ATTRACT (fixtures/ o "
            "library/). attract_doctor chequea encoding/NFC/CRLF/nombres "
            "Windows/JSON de revistas. attract_synopsis escribe el campo "
            "summary: de un juego desde su fuente _synopsis/<set>.json "
            "(ADR-0011) - nunca genera el texto, solo lo aplica."
        ),
    )

    @app.tool()
    def attract_doctor(ruta: str = "fixtures", target: str = "windows") -> dict:
        """Valida una carpeta de libreria ATTRACT: encoding UTF-8, sin
        CRLF, nombres legales en Windows, NFC, JSON de data.json/
        magazine.json valido y conforme al contrato. Devuelve errores
        (bloquean) y avisos (no bloquean) por separado."""
        return _run_doctor(ruta, target)

    @app.tool()
    def attract_synopsis(set_id: str, ruta: str) -> dict:
        """Escribe el campo summary: del juego <set_id> en
        metadata.pegasus.txt, leyendo el texto desde
        <ruta>/_synopsis/<set_id>.json. No genera texto - si no existe la
        fuente, devuelve ok=False con el motivo, no inventa nada."""
        return _run_synopsis(set_id, ruta)

    return app


def main(argv: list[str] | None = None) -> int:
    try:
        app = _construir_app()
    except ImportError:
        print(
            "error: falta el paquete 'mcp'. Instalalo con: pip install mcp\n"
            "(doctor y synopsis no lo necesitan - esto es solo para attract mcp)",
            file=sys.stderr,
        )
        return 2

    app.run()  # bloquea, sirve por stdio
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
