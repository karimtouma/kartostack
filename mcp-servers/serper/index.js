#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const SERPER_API_KEY = process.env.SERPER_API_KEY;

if (!SERPER_API_KEY) {
  console.error("Error: SERPER_API_KEY environment variable is required");
  process.exit(1);
}

// Serper API functions
async function webSearch(query, options = {}) {
  const response = await fetch("https://google.serper.dev/search", {
    method: "POST",
    headers: {
      "X-API-KEY": SERPER_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      q: query,
      num: options.num || 10,
      gl: options.country || "us",
      hl: options.language || "en",
    }),
  });

  if (!response.ok) {
    throw new Error(`Serper API error: ${response.status}`);
  }

  return await response.json();
}

async function imageSearch(query, options = {}) {
  const response = await fetch("https://google.serper.dev/images", {
    method: "POST",
    headers: {
      "X-API-KEY": SERPER_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      q: query,
      num: options.num || 10,
    }),
  });

  if (!response.ok) {
    throw new Error(`Serper API error: ${response.status}`);
  }

  return await response.json();
}

async function newsSearch(query, options = {}) {
  const response = await fetch("https://google.serper.dev/news", {
    method: "POST",
    headers: {
      "X-API-KEY": SERPER_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      q: query,
      num: options.num || 10,
    }),
  });

  if (!response.ok) {
    throw new Error(`Serper API error: ${response.status}`);
  }

  return await response.json();
}

async function scrapeWebpage(url) {
  const response = await fetch("https://scrape.serper.dev", {
    method: "POST",
    headers: {
      "X-API-KEY": SERPER_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ url }),
  });

  if (!response.ok) {
    throw new Error(`Serper Scrape API error: ${response.status}`);
  }

  return await response.json();
}

// Clean HTML to readable text
function cleanHtmlToText(html) {
  if (!html) return "";

  let text = html
    // Remove scripts and styles
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
    .replace(/<noscript[^>]*>[\s\S]*?<\/noscript>/gi, "")
    // Remove HTML comments
    .replace(/<!--[\s\S]*?-->/g, "")
    // Convert headers to markdown
    .replace(/<h1[^>]*>(.*?)<\/h1>/gi, "\n# $1\n")
    .replace(/<h2[^>]*>(.*?)<\/h2>/gi, "\n## $1\n")
    .replace(/<h3[^>]*>(.*?)<\/h3>/gi, "\n### $1\n")
    .replace(/<h4[^>]*>(.*?)<\/h4>/gi, "\n#### $1\n")
    // Convert lists
    .replace(/<li[^>]*>(.*?)<\/li>/gi, "• $1\n")
    // Convert paragraphs and breaks
    .replace(/<\/p>/gi, "\n\n")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/div>/gi, "\n")
    // Convert links - keep text only
    .replace(/<a[^>]*>(.*?)<\/a>/gi, "$1")
    // Remove remaining HTML tags
    .replace(/<[^>]+>/g, "")
    // Decode HTML entities
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&mdash;/g, "—")
    .replace(/&ndash;/g, "–")
    // Clean up whitespace
    .replace(/\t/g, " ")
    .replace(/ +/g, " ")
    .replace(/\n\s*\n\s*\n/g, "\n\n")
    .trim();

  return text;
}

// Fetch URL with clean text extraction
async function fetchUrl(url, maxLength = 6000) {
  try {
    // First try with Serper scraper (better for JS-heavy sites)
    const serperResult = await scrapeWebpage(url);

    if (serperResult.text) {
      let text = serperResult.text;
      // Clean and truncate
      text = text.replace(/\s+/g, " ").trim();
      if (text.length > maxLength) {
        text = text.substring(0, maxLength) + "\n\n[...truncated]";
      }
      return {
        title: serperResult.title || "",
        text: text,
        url: url
      };
    }

    return { title: "", text: "No content extracted", url };
  } catch (error) {
    // Fallback: direct fetch
    try {
      const response = await fetch(url, {
        headers: {
          "User-Agent": "Mozilla/5.0 (compatible; ClaudeBot/1.0)"
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const html = await response.text();
      const text = cleanHtmlToText(html);

      // Extract title
      const titleMatch = html.match(/<title[^>]*>([^<]+)<\/title>/i);
      const title = titleMatch ? titleMatch[1].trim() : "";

      // Truncate
      const truncated = text.length > maxLength
        ? text.substring(0, maxLength) + "\n\n[...truncated]"
        : text;

      return { title, text: truncated, url };
    } catch (fallbackError) {
      return {
        title: "",
        text: `Error fetching URL: ${error.message}`,
        url
      };
    }
  }
}

// Create MCP Server
const server = new Server(
  {
    name: "mcp-serper",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "web_search",
        description: "Search the web using Google via Serper API. Returns organic results, snippets, and links.",
        inputSchema: {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "The search query",
            },
            num_results: {
              type: "number",
              description: "Number of results to return (default: 10, max: 100)",
            },
            country: {
              type: "string",
              description: "Country code for localized results (e.g., 'us', 'mx', 'es')",
            },
            language: {
              type: "string",
              description: "Language code (e.g., 'en', 'es')",
            },
          },
          required: ["query"],
        },
      },
      {
        name: "news_search",
        description: "Search for recent news articles using Google News via Serper API.",
        inputSchema: {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "The news search query",
            },
            num_results: {
              type: "number",
              description: "Number of results (default: 10)",
            },
          },
          required: ["query"],
        },
      },
      {
        name: "image_search",
        description: "Search for images using Google Images via Serper API.",
        inputSchema: {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "The image search query",
            },
            num_results: {
              type: "number",
              description: "Number of results (default: 10)",
            },
          },
          required: ["query"],
        },
      },
      {
        name: "scrape_webpage",
        description: "Scrape and extract content from a webpage URL. Returns the page text, title, and metadata.",
        inputSchema: {
          type: "object",
          properties: {
            url: {
              type: "string",
              description: "The URL to scrape",
            },
          },
          required: ["url"],
        },
      },
      {
        name: "fetch_url",
        description: "Fetch a URL and extract clean, readable text. Optimized for LLM context - removes HTML, scripts, ads. Use this to read article content from search results.",
        inputSchema: {
          type: "object",
          properties: {
            url: {
              type: "string",
              description: "The URL to fetch",
            },
            max_length: {
              type: "number",
              description: "Maximum text length to return (default: 6000 chars)",
            },
          },
          required: ["url"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "web_search": {
        const results = await webSearch(args.query, {
          num: args.num_results,
          country: args.country,
          language: args.language,
        });

        // Format results for better readability
        let formatted = `## Web Search Results for: "${args.query}"\n\n`;

        if (results.answerBox) {
          formatted += `### Answer Box\n${results.answerBox.answer || results.answerBox.snippet || ""}\n\n`;
        }

        if (results.organic) {
          formatted += `### Organic Results\n`;
          results.organic.forEach((r, i) => {
            formatted += `${i + 1}. **${r.title}**\n`;
            formatted += `   URL: ${r.link}\n`;
            formatted += `   ${r.snippet || ""}\n\n`;
          });
        }

        if (results.relatedSearches) {
          formatted += `### Related Searches\n`;
          results.relatedSearches.forEach((r) => {
            formatted += `- ${r.query}\n`;
          });
        }

        return {
          content: [{ type: "text", text: formatted }],
        };
      }

      case "news_search": {
        const results = await newsSearch(args.query, {
          num: args.num_results,
        });

        let formatted = `## News Results for: "${args.query}"\n\n`;

        if (results.news) {
          results.news.forEach((r, i) => {
            formatted += `${i + 1}. **${r.title}**\n`;
            formatted += `   Source: ${r.source} | ${r.date}\n`;
            formatted += `   URL: ${r.link}\n`;
            formatted += `   ${r.snippet || ""}\n\n`;
          });
        }

        return {
          content: [{ type: "text", text: formatted }],
        };
      }

      case "image_search": {
        const results = await imageSearch(args.query, {
          num: args.num_results,
        });

        let formatted = `## Image Results for: "${args.query}"\n\n`;

        if (results.images) {
          results.images.forEach((r, i) => {
            formatted += `${i + 1}. **${r.title}**\n`;
            formatted += `   Image URL: ${r.imageUrl}\n`;
            formatted += `   Source: ${r.link}\n\n`;
          });
        }

        return {
          content: [{ type: "text", text: formatted }],
        };
      }

      case "scrape_webpage": {
        const result = await scrapeWebpage(args.url);

        let formatted = `## Scraped Content from: ${args.url}\n\n`;

        if (result.title) {
          formatted += `### Title\n${result.title}\n\n`;
        }

        if (result.text) {
          // Truncate if too long
          const text = result.text.length > 10000
            ? result.text.substring(0, 10000) + "\n\n[Content truncated...]"
            : result.text;
          formatted += `### Content\n${text}\n`;
        }

        return {
          content: [{ type: "text", text: formatted }],
        };
      }

      case "fetch_url": {
        const maxLen = args.max_length || 6000;
        const result = await fetchUrl(args.url, maxLen);

        let formatted = "";
        if (result.title) {
          formatted += `# ${result.title}\n\n`;
        }
        formatted += `Source: ${result.url}\n\n---\n\n`;
        formatted += result.text;

        return {
          content: [{ type: "text", text: formatted }],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [{ type: "text", text: `Error: ${error.message}` }],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MCP Serper Server running on stdio");
}

main().catch(console.error);
