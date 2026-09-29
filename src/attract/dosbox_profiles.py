"""Perfiles conocidos: datos y evidencia, sin ROMs ni drivers (ADR-0032).

Que un perfil entre acá NO requiere que alguien lo haya jugado en esta
maquina - alcanza con investigacion citable (VOGONS, PCGamingWiki, el
compat-list de DOSBox, notas de eXoDOS) para esa version puntual del juego.
Ver docs/decisiones/2026-09-16.md #2: el import nunca espera confirmacion de
nadie: si la config investigada no anda del todo bien, el dosbox.conf ya esta
generado y el usuario lo ajusta el mismo. Lo que SI es innegociable es la
identidad exacta por hash (`files`) - eso es lo unico que evita aplicarle a
una edicion la config de otra.

`evidence` es informativo, no un schema fijo. Un perfil de investigacion pura
anota de donde salio cada dato (`sources`) y con que alcance (`scope`); un
perfil ademas confirmado jugando puede sumar esa nota. Ninguno de los dos
campos es obligatorio para el resolvedor - preparar() copia lo que haya."""

PERFILES = (
    {
        "id": "prehistorik-local-1991-v1",
        "executable": "HISTORIK.EXE",
        "files": {
            "HISTORIK.EXE": "5cea262f9610657af8b55c10b277ec30ffe99df35294d5f8c9f520a30e029c96",
            "CT-VOICE.DRV": "3c8497742c60cdba0cac256655e4b7cdce1c601c597395f7f5da3dfc9937079e",
            "FILESA.CUR": "eeb2e85ab2440ef91d54c808bd93fa6e6962b48d422beed1c06e32d684b962ec",
            "FILESA.VGA": "ec0b7a025ff1ef2391afc3675d3a4079f93b9df780d2bdf9715a1d2d5987b0fa",
            "FILESB.CUR": "088806e36c4f836862989c5679a68c98b922cdac31c923d4e189cce37dcff098",
            "FILESB.VGA": "6bfebd59c28e01878ce7575652a5e2a1f9fc0a9b6d3cf68039b4070ecb463d1a",
        },
        "settings": {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": True},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-15",
            "automated": "selector de idioma observado en copia aislada",
            "user": "usuario confirma 'quedo perfecto' al aplicar el piloto",
            "scope": "esta copia; no certifica otras ediciones ni hardware",
        },
        "sources": [
            "https://www.dosbox.com/comp_list.php?showID=1943",
            "https://www.dosbox-staging.org/0.83/manual/system/cpu/",
        ],
    },
    # ------------------------------------------------------------------
    # Los que siguen (2026-09-17) son la libreria real ya instalada del
    # autor, identificados por hash de su copia real (no jugados en esta
    # sesion). Donde la investigacion no dio una cifra especifica citable,
    # se deja la base generica (3000/sbpro2) en vez de inventar un numero -
    # el valor real de la entrada es la identidad + el ejecutable correcto,
    # no una optimizacion. Ver docs/decisiones/2026-09-17.md.
    # ------------------------------------------------------------------
    {
        "id": "monkey-island-1990-dos-v1",
        "executable": "MONKEY.EXE",
        "files": {
            "MONKEY.EXE": "a9ad60186b01f72374a744b5536f56c6eff88b937a9fd461352e055dc425e02d",
            "MONKEY.000": "d9b9345a55260dcd97ee67725103216773823deaefd7e9c906f0946b12d180c4",
            "MONKEY.001": "b7ab0d02311d68490809d667ae03b4c15e6bb5d21ff5cac3b2b4072dc2f4e1d7",
        },
        "settings": {"cpu_cycles": 6000, "sbtype": "sb1", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "cifra especifica para este titulo (SCUMM v3-4, 1990) "
                     "segun la doc oficial de DOSBox-staging por era",
        },
        "sources": ["https://www.dosbox-staging.org/0.83/manual/introduction/dos-eras/"],
    },
    {
        "id": "monkey-island-2-1991-dos-v1",
        "executable": "MONKEY2.EXE",
        "files": {
            "MONKEY2.EXE": "274b3568b171c82ae2f3bbda5db5b550bef2f4d2a21914799ef4805fa410899e",
            "MONKEY2.000": "bdca6e56c3bb9a829cdf68bff5f87d177fa5d3595b0ea860bfa660c475188ac5",
            "MONKEY2.001": "abf83c740fada0787c7ad9f148f07cdbbba4a937907380db424a33113198fefc",
        },
        "settings": {"cpu_cycles": 6000, "sbtype": "sb1", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "sin cifra especifica para MI2; se extrapola de MI1 "
                     "(mismo motor SCUMM v5, un año de diferencia) - MENOR "
                     "confianza que una fuente puntual para este titulo",
        },
        "sources": ["https://www.dosbox-staging.org/0.83/manual/introduction/dos-eras/"],
    },
    {
        "id": "indiana-jones-atlantis-1992-dos-v1",
        "executable": "ATLANTIS.EXE",
        "files": {
            "ATLANTIS.EXE": "718c732a1fbb1430ec9fd84aa19c9cc56219deaba9d45268e8e3f14fc6822340",
            "ATLANTIS.000": "72913003d61fffaa614795f12b33d9f2ef3bdcebb155cc5a53fc93b88e57c3bb",
        },
        "settings": {"cpu_cycles": 6000, "sbtype": "sb1", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "sin cifra especifica para este titulo; se extrapola de "
                     "la doc oficial de era (SCUMM v5, 1992) - MENOR confianza "
                     "que una fuente puntual. VOGONS avisa problemas de audio "
                     "propios de este juego, ajustar si hace falta",
        },
        "sources": [
            "https://www.dosbox-staging.org/0.83/manual/introduction/dos-eras/",
            "https://www.vogons.org/viewtopic.php?t=53668",
        ],
    },
    {
        "id": "leisure-suit-larry-5-sci-v1",
        "executable": "SCIDHUV.EXE",
        "files": {
            "SCIDHUV.EXE": "678d30cff8b3154a3ef7abbc18eeec77feaad15eb144e6f41543c893d54786bf",
            "RESOURCE.MAP": "73f575a2a4dac7d39ddbc701ef9f8d53690b00b9991606398929602e9f5102cd",
        },
        "settings": {"cpu_cycles": 6000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "motor Sierra SCI confirmado por RESOURCE.MAP/RESOURCE.0xx "
                     "(mismo criterio que dosbox_motores.py, pero identidad "
                     "fijada por hash de esta copia puntual)",
        },
        "sources": [
            "https://www.gog.com/forum/kings_quest_series/a_tip_for_the_sci_agi_games_in_this_and_other_sierra_packs",
        ],
    },
    {
        "id": "space-quest-1-sci-v1",
        "executable": "SCIDHUV.EXE",
        "files": {
            "SCIDHUV.EXE": "3e85e5a23dce88cd457dddce7b85f42ecb16346e966fa4345fe635990af8ff9a",
            "RESOURCE.MAP": "7d4e0be1f7a4baf5eec73c8855851009d1e16f40a45258153e59ae8b1cb1af19",
        },
        "settings": {"cpu_cycles": 6000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "motor Sierra SCI confirmado por RESOURCE.MAP/RESOURCE.0xx; "
                     "esta copia es el relanzamiento SCI, no la version AGI "
                     "original de 1986 pese al nombre de la carpeta",
        },
        "sources": [
            "https://www.gog.com/forum/kings_quest_series/a_tip_for_the_sci_agi_games_in_this_and_other_sierra_packs",
        ],
    },
    {
        "id": "oh-no-more-lemmings-1992-dos-v1",
        "executable": "Lemmings.bat",
        "files": {
            "Lemmings.bat": "f0c62c5fd417aa65f912f6f4c3944c5e51d45055bd4280186842d8805eecf8c6",
            "VGALEMM2.EXE": "ce3f3e0a1fa0cf48c630762a6338fa538a4eec50bb9351adc5ab3a376ff8055d",
        },
        "settings": {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "cifra especifica: ~3000 ciclos para que Adlib/SB se "
                     "detecte; VOGONS documenta que ejecutar VGALEMM2.EXE "
                     "directo (no via el .bat) es sensible a un bug de "
                     "deteccion de audio en CPUs rapidas - por eso el "
                     "ejecutable elegido es el .bat, no el .exe",
        },
        "sources": ["https://www.vogons.org/viewtopic.php?t=9413"],
    },
    {
        "id": "civilization-1991-dos-v1",
        "executable": "CIV.EXE",
        "files": {
            "CIV.EXE": "31e35b01f4d00df81685dfcb81e6de196a3876bd2afff6e39cbbfd964f5852ad",
        },
        "settings": {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "sin cifra especifica encontrada citable; solo identidad "
                     "confirmada y ejecutable correcto (CIV.EXE, no los "
                     "helpers EGRAPHIC/MGRAPHIC/TGRAPHIC/MISC) - settings es "
                     "la base generica sin ajuste",
        },
        "sources": [],
    },
    {
        "id": "elvira-arcade-1991-dos-v1",
        "executable": "ELVMCGA.EXE",
        "files": {
            "ELVMCGA.EXE": "fd62279d9bd029b512425092116184b360eede9488880735cb12fdb190110822",
        },
        "settings": {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "sin cifra especifica citable (solo aviso generico de "
                     "'probablemente haya que bajar los ciclos'); se elige "
                     "ELVMCGA.EXE directo en vez de ELVIRA.BAT porque el .bat "
                     "corre SETUP.EXE sin condicion en cada arranque",
        },
        "sources": ["https://www.vogons.org/viewtopic.php?t=1733"],
    },
    {
        "id": "hare-raising-havoc-1991-dos-v1",
        "executable": "ROGER2.EXE",
        "files": {
            "ROGER2.EXE": "210df573a3595b847a2c188f2c422d204e95cc3f6712b35d62f56773f1f1eba4",
        },
        "settings": {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "sin cifra especifica citable - la velocidad del juego "
                     "esta atada al reloj emulado por diseño (afecta animacion "
                     "Y dificultad por igual), asi que no hay un numero "
                     "'correcto' universal; solo identidad confirmada",
        },
        "sources": [],
    },
    {
        "id": "guy-spy-crystals-armageddon-1990-dos-v1",
        "executable": "GUYSPY.EXE",
        "files": {
            "GUYSPY.EXE": "4a68d723467ecaa132b6e85f57213fab7993db0a4e682d86e24de116ca86ccd5",
        },
        "settings": {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "titulo poco documentado, sin cifra especifica citable; "
                     "solo identidad confirmada y ejecutable correcto",
        },
        "sources": [],
    },
    {
        "id": "simant-1991-dos-v1",
        "executable": "SIMANT.EXE",
        "files": {
            "SIMANT.EXE": "aa0596c6766322a8229ee3c36e57048c92adc82d50fbe2ef37afb8b85fcf4f11",
        },
        "settings": {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "sin cifra especifica citable; solo identidad confirmada "
                     "y ejecutable correcto (SIMANT.EXE, no INFO.EXE ni "
                     "INSTALL.EXE)",
        },
        "sources": [],
    },
    {
        "id": "out-of-this-world-1991-dos-v1",
        "executable": "World.exe",
        "files": {
            "World.exe": "b0da56245b1f1f64b1d01318826c69531819c4cc9514759be20cbd28e851844f",
        },
        "settings": {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "VOGONS reporta resultados mixtos entre 3000 (funciona, "
                     "'auto' cae en 3000) y 10000 (mejor para joystick en "
                     "algunos casos) - sin consenso claro, se deja la base",
        },
        "sources": ["https://www.vogons.org/viewtopic.php?t=16726"],
    },
    {
        "id": "teenage-mutant-ninja-turtles-1989-dos-v1",
        "executable": "MNU.EXE",
        "files": {
            "MNU.EXE": "7758fe536ff2ccaf9ad55273612de412a436ef6eba9bd49b55838fd0d718769a",
            "TMNTEGA.EXE": "6c23d4dde0c31eef25213152ca5cced522b28867bb046539a87549b447ce8485",
        },
        "settings": {"cpu_cycles": 3000, "sbtype": "sbpro2", "sound_env": False},
        "emulator_version": "0.83.0",
        "evidence": {
            "date": "2026-09-17",
            "kind": "investigacion, no jugado en esta maquina",
            "scope": "sin cifra especifica citable; el valor real de esta "
                     "entrada es identificar la copia correcta: la carpeta "
                     "trae DOS instalaciones distintas con el mismo nombre de "
                     "archivo y hash distinto (dos/ vs "
                     "Teenage_Mutant_Ninja_Turtles_IMG/) - esta fija dos/MNU.EXE "
                     "(el menu que elige CGA/EGA/Tandy), no la otra copia",
        },
        "sources": [],
    },
)
