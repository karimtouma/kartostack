# Claude Agent - Long Run Optimization

This agent runs on GLM-4.7-flash-82k via Ollama with an 82k token context window.

## Memory Management

The stop hook automatically compresses memory when approaching the 70k token limit.
When compression occurs:
1. Session context is saved to `.claude/memory.md`
2. A new session starts with a prompt to read that file
3. Continue work with restored context

If you see a message about memory compression:
- Read `.claude/memory.md` immediately
- Review: files modified, commands run, recent progress, active tasks
- Continue where the previous session left off

## Long Running Tasks

For complex multi-step tasks, use the Ralph Wiggum loop:

```
/ralph-loop "Your task description" --max-iterations 50 --completion-promise "TASK COMPLETE"
```

This creates a self-referential loop that:
- Feeds the same prompt back on each iteration
- Preserves work in files and git
- Continues until max iterations or promise is fulfilled

To signal completion: `<promise>TASK COMPLETE</promise>`

## Efficient Context Usage

1. **Write to files early** - Don't keep large content in conversation
2. **Use TodoWrite** - Track progress in the todo list, not in memory
3. **Commit often** - Git commits preserve context across sessions
4. **Read files on demand** - Don't load files until needed

## Available Tools

### MCP Serper (Web)
- `web_search` - Google search
- `news_search` - News search
- `image_search` - Image search
- `scrape_webpage` - Full page scrape
- `fetch_url` - Clean text extraction (optimized for LLM context)

### MCP Filesystem
- `read_file`, `write_file`, `list_directory`

### MCP Puppeteer (Browser Automation)
- `puppeteer_navigate` - Go to a URL
- `puppeteer_screenshot` - Take screenshot of page
- `puppeteer_click` - Click on elements
- `puppeteer_fill` - Fill form inputs
- `puppeteer_select` - Select dropdown options
- `puppeteer_hover` - Hover over elements
- `puppeteer_evaluate` - Execute JavaScript in page

Use the browser for:
- Web scraping dynamic content (JS-rendered pages)
- Form submissions and logins
- Testing web applications
- Automating web tasks

### Ralph Wiggum
- `/ralph-loop` - Start iterative development loop
- `/cancel-ralph` - Cancel active loop
- `/help` - Plugin help

## Session Continuity

If starting a new session and `.claude/memory.md` exists:
1. Read it first to understand previous context
2. Check `.claude/todos/todos.json` for pending tasks
3. Review recent git commits if available
4. Continue the work

## Model Optimizations

This agent uses GLM-4.7-flash-82k which:
- Has 82k context window (but compress at 70k for safety margin)
- Runs at ~60 tokens/sec on Apple Silicon
- Supports function calling and tool use
- Is optimized for coding tasks
