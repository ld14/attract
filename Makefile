# ATTRACT
.PHONY: help doctor doctor-lib test theme setup check-git check-py venv clean

# Si existe .venv lo usa; si no, cae al python3 del sistema.
# El doctor no tiene dependencias externas: corre con cualquiera de los dos.
VENV := .venv
PY := $(shell [ -x $(VENV)/bin/python ] && echo $(VENV)/bin/python || echo python3)

export PYTHONPATH := src

# Directorio de themes de Pegasus segun plataforma.
# Esto ES la ADR-003 en 3 lineas: nada es portable, todo es un target.
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
  PEGASUS_THEMES := $(HOME)/Library/Preferences/pegasus-frontend/themes
else ifeq ($(UNAME),Linux)
  PEGASUS_THEMES := $(HOME)/.config/pegasus-frontend/themes
else
  PEGASUS_THEMES := $(LOCALAPPDATA)/pegasus-frontend/themes
endif

help:
	@echo "ATTRACT"
	@echo ""
	@echo "  make setup       config de git + venv + verificacion"
	@echo "  make venv        crea .venv e instala pytest"
	@echo "  make check-git   verifica precomposeUnicode y autocrlf"
	@echo "  make doctor      valida fixtures/"
	@echo "  make doctor-lib  valida library/  (tu libreria real)"
	@echo "  make theme       instala el theme de debug ($(UNAME))"
	@echo "  make test        corre los tests"
	@echo "  make clean       borra .venv y caches"
	@echo ""
	@echo "  python  -> $(PY)"
	@echo "  themes  -> $(PEGASUS_THEMES)"

setup: venv check-git
	@git config core.precomposeUnicode true 2>/dev/null || echo "(no es un repo git todavia: corre 'git init')"
	@echo ""
	@$(MAKE) --no-print-directory check-py
	@echo ""
	@echo "Listo. Probá: make doctor && make test"

check-py:
	@V=$$(python3 -c 'import sys; print("%d.%d"%sys.version_info[:2])'); \
	MAJ=$${V%%.*}; MIN=$${V##*.}; \
	echo "python3   : $$V   ($$(which python3))"; \
	if [ "$$MAJ" -lt 3 ] || { [ "$$MAJ" -eq 3 ] && [ "$$MIN" -lt 10 ]; }; then \
	  echo "  ATENCION: 3.9 es el python del sistema de macOS y esta EOL."; \
	  echo "            brew install python@3.12"; \
	else \
	  echo "  OK"; \
	fi

venv:
	@if [ ! -x $(VENV)/bin/python ]; then \
	  echo "creando $(VENV)..."; \
	  python3 -m venv $(VENV); \
	  $(VENV)/bin/pip install -q --upgrade pip; \
	  $(VENV)/bin/pip install -q pytest; \
	  echo "OK  ($$($(VENV)/bin/python --version))"; \
	else \
	  echo "$(VENV) ya existe  ($$($(VENV)/bin/python --version))"; \
	fi

clean:
	@rm -rf $(VENV) .pytest_cache src/attract/__pycache__ tests/__pycache__
	@echo "limpio"

check-git:
	@echo "core.precomposeUnicode : $$(git config core.precomposeUnicode || echo 'NO SETEADO  <-- arreglalo: make setup')"
	@echo "core.autocrlf          : $$(git config core.autocrlf || echo '(sin setear - ok, manda .gitattributes)')"
	@echo ""
	@echo "precomposeUnicode arregla los NOMBRES de archivo."
	@echo "El contenido del metadata lo tenes que normalizar vos. Ver doctor."

doctor:
	@$(PY) -m attract.doctor fixtures --target windows

doctor-lib:
	@$(PY) -m attract.doctor library --target windows

theme:
	@mkdir -p "$(PEGASUS_THEMES)"
	@cp -R themes/attract-debug "$(PEGASUS_THEMES)/"
	@echo "Instalado en $(PEGASUS_THEMES)/attract-debug"
	@echo "Abri Pegasus > Settings > Theme > ATTRACT Debug"

test:
	@$(PY) -m pytest tests/ -q

fixtures:
	@echo "Los fixtures ya estan en fixtures/. Son ROMs falsas de 0 bytes."
	@echo "Para validar que el generador emite bien NO necesitas un CHD de 132MB."
