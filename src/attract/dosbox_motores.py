"""Familias de motor DOS reconocibles por archivo, sin parsear binarios
(ADR-0033). Distinto de PERFILES (dosbox_profiles.py): esto NO identifica una
copia exacta por hash - identifica el MOTOR por la presencia de sus archivos
de datos característicos, y aplica una config investigada para esa familia.

Por eso `preparar()` nunca lo trata como "perfil-conocido": queda como
"motor-detectado", un escalón de confianza mas bajo que un perfil verificado
por copia, pero mas alto que la base generica `BASE` sin ningun fundamento.

Cada entrada:
  - `requeridos`: nombres de archivo (mayusculas) que TODOS tienen que estar
    en la misma carpeta que el ejecutable elegido.
  - `prefijos`: al menos un archivo de la carpeta tiene que empezar con
    alguno de estos prefijos (cubre series numeradas: VOL.0, VOL.1, ...).
  - `settings`: mismo esquema que un perfil de dosbox_profiles.py.
  - `sources`: de donde salio la config, para poder revisarla despues.

No se investigo un motor a menos que su firma de archivos sea inequivoca.
SCUMM (LucasArts) quedo afuera a propósito: ScummVM mismo necesita extraer
strings de version del binario para diferenciar variantes - una firma por
archivo sola tiene riesgo real de falso positivo, y aplicar mal una config
sin que nadie la revise es peor que dejarla `provisional`.
"""

MOTORES = (
    {
        "id": "sierra-agi",
        "nombre": "Sierra AGI",
        "requeridos": {"WORDS.TOK", "OBJECT"},
        "prefijos": ("VOL.",),
        "settings": {"cpu_cycles": 6000, "sbtype": "sbpro2", "sound_env": False},
        "evidence": {
            "date": "2026-09-16",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "vale para la familia AGI en general, no una copia puntual",
        },
        "sources": [
            "https://www.gog.com/forum/kings_quest_series/a_tip_for_the_sci_agi_games_in_this_and_other_sierra_packs",
        ],
    },
    {
        "id": "sierra-sci",
        "nombre": "Sierra SCI",
        "requeridos": {"RESOURCE.MAP"},
        "prefijos": ("RESOURCE.0",),
        "settings": {"cpu_cycles": 6000, "sbtype": "sbpro2", "sound_env": False},
        "evidence": {
            "date": "2026-09-16",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "vale para la familia SCI en general; titulos tardios "
                     "(KQ6/KQ7/SQ6) documentados con necesidades mayores de "
                     "memoria/ciclos - no cubierto por este esquema todavia",
        },
        "sources": [
            "https://www.gog.com/forum/kings_quest_series/a_tip_for_the_sci_agi_games_in_this_and_other_sierra_packs",
        ],
    },
)
