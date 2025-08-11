#!/usr/bin/env bash
set -euo pipefail

# Restore R packages from renv in setup/
if [ -f "/project/renv.lock" ]; then
  echo "Restoring R packages from setup/renv..."
  Rscript -e "renv::restore(project = '/project', prompt = FALSE)"
else
  echo "No renv.lock found, skipping R package restore."
fi

# Setup Python virtual environment
VENV_PATH="/root/.virtualenvs/venv"
REQ_FILE="/project/setup/requirements.txt"

if [ ! -d "$VENV_PATH" ]; then
  echo "Creating Python virtual environment at $VENV_PATH..."
  python3 -m venv "$VENV_PATH"
fi

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Install Python packages if requirements.txt exists and packages not installed
if [ -f "$REQ_FILE" ]; then
  echo "Installing/updating Python packages from $REQ_FILE..."
  pip install --upgrade pip
  pip install -r "$REQ_FILE"
else
  echo "No Python requirements.txt found at $REQ_FILE, skipping Python package install."
fi

# Execute the CMD
exec "$@"
