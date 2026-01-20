#!/bin/bash

# Memory Compression Script
# Compresses conversation transcript when approaching token limits
# Outputs a compressed markdown summary for context continuity

set -euo pipefail

# Configuration
MAX_CHARS=${MAX_CONTEXT_CHARS:-280000}  # ~70k tokens (4 chars per token)
MEMORY_FILE=".claude/memory.md"
TRANSCRIPT_PATH="${1:-}"

if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "Usage: compress-memory.sh <transcript_path>" >&2
  exit 1
fi

# Calculate current transcript size
TRANSCRIPT_SIZE=$(wc -c < "$TRANSCRIPT_PATH")

# Check if compression needed
if [[ $TRANSCRIPT_SIZE -lt $MAX_CHARS ]]; then
  echo '{"needs_compression": false}'
  exit 0
fi

# Extract key information from transcript
mkdir -p .claude

# Build compressed memory
cat > "$MEMORY_FILE" << 'HEADER'
# Session Memory (Auto-compressed)

This file contains compressed context from a previous session that exceeded token limits.
The agent should read this to restore working context.

---

HEADER

# Extract file modifications
echo "## Files Modified" >> "$MEMORY_FILE"
grep -o '"path":"[^"]*"' "$TRANSCRIPT_PATH" 2>/dev/null | \
  sed 's/"path":"//g; s/"//g' | \
  sort -u | \
  head -50 | \
  while read -r file; do
    echo "- \`$file\`" >> "$MEMORY_FILE"
  done
echo "" >> "$MEMORY_FILE"

# Extract bash commands executed
echo "## Commands Executed" >> "$MEMORY_FILE"
grep -o '"command":"[^"]*"' "$TRANSCRIPT_PATH" 2>/dev/null | \
  sed 's/"command":"//g; s/"//g' | \
  tail -30 | \
  while read -r cmd; do
    # Truncate long commands
    if [[ ${#cmd} -gt 100 ]]; then
      cmd="${cmd:0:100}..."
    fi
    echo "- \`$cmd\`" >> "$MEMORY_FILE"
  done
echo "" >> "$MEMORY_FILE"

# Extract recent assistant outputs (last 5 meaningful ones)
echo "## Recent Progress" >> "$MEMORY_FILE"
grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | \
  tail -5 | \
  while read -r line; do
    # Extract first 500 chars of text content
    TEXT=$(echo "$line" | jq -r '.message.content[] | select(.type=="text") | .text' 2>/dev/null | head -c 500)
    if [[ -n "$TEXT" ]]; then
      echo "$TEXT" | head -5 >> "$MEMORY_FILE"
      echo "..." >> "$MEMORY_FILE"
      echo "" >> "$MEMORY_FILE"
    fi
  done

# Extract any todos or task lists
echo "## Active Tasks" >> "$MEMORY_FILE"
if [[ -f ".claude/todos/todos.json" ]]; then
  jq -r '.[] | "- [\(.status)] \(.content)"' .claude/todos/todos.json 2>/dev/null >> "$MEMORY_FILE" || true
fi
echo "" >> "$MEMORY_FILE"

# Add timestamp
echo "---" >> "$MEMORY_FILE"
echo "_Compressed at: $(date -u +%Y-%m-%dT%H:%M:%SZ)_" >> "$MEMORY_FILE"
echo "_Original size: $TRANSCRIPT_SIZE chars (~$((TRANSCRIPT_SIZE / 4)) tokens)_" >> "$MEMORY_FILE"

# Output result
MEMORY_SIZE=$(wc -c < "$MEMORY_FILE")
jq -n \
  --arg memory_file "$MEMORY_FILE" \
  --argjson original_size "$TRANSCRIPT_SIZE" \
  --argjson compressed_size "$MEMORY_SIZE" \
  '{
    "needs_compression": true,
    "memory_file": $memory_file,
    "original_tokens": ($original_size / 4 | floor),
    "compressed_tokens": ($compressed_size / 4 | floor),
    "compression_ratio": (($original_size - $compressed_size) / $original_size * 100 | floor)
  }'
