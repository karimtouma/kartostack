---
description: "Compress current session memory to markdown file"
argument-hint: "[--output FILE]"
allowed-tools: ["Write", "Read"]
---

# Memory Compression

When context is getting large (approaching 70k tokens), compress the current knowledge into a memory file.

## Instructions

Create a compressed summary of our conversation in the following format:

```markdown
# Session Memory - [DATE]

## Context
[Brief description of what we're working on]

## Key Decisions Made
- [Decision 1]
- [Decision 2]

## Files Created/Modified
| File | Purpose |
|------|---------|
| file1.py | Description |

## Current State
[What's working, what's not]

## Next Steps
- [ ] Step 1
- [ ] Step 2

## Important Code Snippets
[Only include critical code that would be needed to continue]

## Notes
[Any other important context]
```

Save this to: `$ARGUMENTS` or `.claude/memory.md` if no argument provided.

After saving, inform the user they can:
1. Start a new session
2. The memory will be loaded via CLAUDE.md
3. Continue working with fresh context

IMPORTANT: Be concise. The goal is to preserve essential knowledge in <2000 tokens.
