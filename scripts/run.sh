#!/bin/bash
# =============================================================================
# Kartostack - Run Claude Code Agent
# Connects to local Ollama with GLM-4.7-flash
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

# Configuration
CLAUDE_MODEL="${CLAUDE_MODEL:-glm-4.7-flash-82k}"
OLLAMA_HOST="${OLLAMA_HOST:-localhost}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
WORKSPACE="${WORKSPACE:-$HOME/Projects}"
IMAGE_NAME="${IMAGE_NAME:-kartostack}"
VOLUME_NAME="${VOLUME_NAME:-kartostack-data}"

# Check Ollama is running
if ! curl -sf "http://${OLLAMA_HOST}:${OLLAMA_PORT}/" > /dev/null 2>&1; then
  echo "Error: Ollama no está corriendo en ${OLLAMA_HOST}:${OLLAMA_PORT}"
  echo "Inicia Ollama primero: open -a Ollama"
  exit 1
fi

# Build image if needed
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
  echo "Building $IMAGE_NAME image..."
  docker build -t "$IMAGE_NAME" "$PROJECT_DIR"
fi

# Run Claude Code in Docker
docker run -it --rm \
  --add-host=host.docker.internal:host-gateway \
  -e CLAUDE_MODEL="$CLAUDE_MODEL" \
  -e SERPER_API_KEY="${SERPER_API_KEY:-}" \
  -e CLAUDE_CODE_SKIP_INITIAL_PROMPTS=1 \
  -v "${VOLUME_NAME}:/home/claude/.claude" \
  -v "${WORKSPACE}:/workspace:rw" \
  -w /workspace \
  "$IMAGE_NAME" "$@"
