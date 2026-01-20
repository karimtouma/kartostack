#!/bin/bash
# Wrapper for Claude Code with GLM model, MCP servers, and plugins
# Handles permission fixing for mounted volumes

set -e

CLAUDE_HOME="/home/claude"
CLAUDE_DIR="$CLAUDE_HOME/.claude"
MODEL="${CLAUDE_MODEL:-glm-4.7-flash-82k}"
MCP_CONFIG="$CLAUDE_DIR/mcp-config.json"
PLUGIN_DIR="$CLAUDE_DIR/plugins/ralph-wiggum"

# If running as root, fix permissions and re-exec as claude
if [ "$(id -u)" = "0" ]; then
  # Fix ownership of .claude directory (mounted volume)
  chown -R claude:claude "$CLAUDE_DIR" 2>/dev/null || true
  chown -R claude:claude /workspace 2>/dev/null || true

  # Always refresh settings from defaults (stored outside volume in /app/defaults)
  # This ensures bypass mode and all tool permissions are up-to-date
  if [ -f "/app/defaults/settings.json" ]; then
    cp "/app/defaults/settings.json" "$CLAUDE_DIR/settings.json"
    chown claude:claude "$CLAUDE_DIR/settings.json"
  fi

  if [ -f "/app/defaults/mcp-config.json" ]; then
    cp "/app/defaults/mcp-config.json" "$MCP_CONFIG"
    chown claude:claude "$MCP_CONFIG"
  fi

  # State file (.claude.json) is baked into image - no copy needed

  # Ensure plugin directory exists with correct permissions and content
  mkdir -p "$PLUGIN_DIR"
  # Copy plugin from default location if plugin.json is missing (including hidden files)
  if [ ! -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ] && [ -d "$CLAUDE_DIR/plugins/ralph-wiggum.default" ]; then
    cp -a "$CLAUDE_DIR/plugins/ralph-wiggum.default/." "$PLUGIN_DIR/"
    chmod +x "$PLUGIN_DIR/hooks/"*.sh 2>/dev/null || true
    chmod +x "$PLUGIN_DIR/scripts/"*.sh 2>/dev/null || true
  fi
  chown -R claude:claude "$CLAUDE_DIR/plugins" 2>/dev/null || true

  # Re-execute this script as claude user
  exec gosu claude "$0" "$@"
fi

# Build args (now running as claude user)
ARGS=(--model "$MODEL")

# Add MCP config if exists
if [ -f "$MCP_CONFIG" ]; then
  ARGS+=(--mcp-config "$MCP_CONFIG")
fi

# Add ralph-wiggum plugin if exists
if [ -d "$PLUGIN_DIR" ]; then
  ARGS+=(--plugin-dir "$PLUGIN_DIR")
fi

exec claude "${ARGS[@]}" "$@"
