FROM node:22-slim

# Install system dependencies for plugins and Puppeteer/Chromium
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    perl \
    git \
    gosu \
    curl \
    # Chromium dependencies for Puppeteer
    chromium \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Tell Puppeteer to use system Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Create non-root user (use UID 1001 to avoid conflict with node user)
RUN useradd -m -s /bin/bash -u 1001 claude && \
    mkdir -p /home/claude/.claude/plugins /app/mcp-servers/serper /workspace && \
    chown -R claude:claude /home/claude /app /workspace

WORKDIR /app

# Install Claude Code and MCP servers globally
RUN npm install -g @anthropic-ai/claude-code \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-puppeteer

# Copy MCP Serper server (from build context)
COPY --chown=claude:claude mcp-servers/serper/package.json /app/mcp-servers/serper/
COPY --chown=claude:claude mcp-servers/serper/index.js /app/mcp-servers/serper/
RUN cd /app/mcp-servers/serper && npm install --omit=dev

# Copy Ralph Wiggum plugin (to default location for restore)
COPY --chown=claude:claude plugins/ralph-wiggum /home/claude/.claude/plugins/ralph-wiggum.default
RUN chmod +x /home/claude/.claude/plugins/ralph-wiggum.default/hooks/*.sh \
    /home/claude/.claude/plugins/ralph-wiggum.default/scripts/*.sh

# Copy Claude config defaults to /app (NOT in volume path)
COPY settings.json /app/defaults/settings.json
COPY mcp-config.json /app/defaults/mcp-config.json
# State file goes directly in home (not in volume) - pre-configured for no prompts
COPY --chown=claude:claude claude.json /home/claude/.claude.json
# CLAUDE.md provides system instructions for long runs and memory management
COPY --chown=claude:claude CLAUDE.md /workspace/CLAUDE.md
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && \
    mkdir -p /app/defaults && \
    chown -R claude:claude /app/defaults

# Environment - API key comes from apiKeyHelper in settings.json
ENV CLAUDE_MODEL=glm-4.7-flash-82k
ENV DISABLE_AUTOUPDATER=1
ENV HOME=/home/claude

# Working directory for projects
WORKDIR /workspace

# Start as root, entrypoint will fix permissions and drop to claude user
ENTRYPOINT ["/app/entrypoint.sh"]
