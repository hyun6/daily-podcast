#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend"

echo "Using Project Root: $PROJECT_ROOT"
echo "Starting Backend in: $BACKEND_DIR"

cd "$BACKEND_DIR"

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "Error: 'uv' is not installed. Please install it first."
    echo "You can install it via: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# Check for .env file
if [ ! -f ".env" ]; then
    echo "Warning: .env file not found in $BACKEND_DIR"
    echo "Please copy .env.example to .env and configure your environment variables."
fi

# Sync dependencies to ensure environment is up-to-date
echo "Syncing dependencies..."
uv sync

# Enable MPS fallback for PyTorch (Required for some ops like aten::angle on Mac)
export PYTORCH_ENABLE_MPS_FALLBACK=1

echo "Running FastAPI server..."
uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
