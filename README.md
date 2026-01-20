# Kartostack

Asistente de programación containerizado con Claude Code y modelos locales via Ollama.

> **Guía completa**: Lee el artículo [Agente de Coding 24/7 prácticamente gratis](https://karim.touma.io/agente-de-ingenier%C3%ADa-de-software-24-7-pr%C3%A1cticamente-gratis-4cbd12e2bd92) para entender la arquitectura completa y casos de uso.

**Stack**: VS Code + Claude Code + GLM-4.7-Flash + Ollama + WebSearch-MCP (Serper) + Ralph-Wiggum Plugin

## Características

- **LLM Local**: Funciona con Ollama usando GLM-4.7-flash (82k tokens de contexto)
- **Automatización de Browser**: Puppeteer MCP para web scraping y automatización
- **Búsqueda Web**: Serper MCP para búsquedas en Google, noticias e imágenes
- **Acceso a Archivos**: Lectura/escritura completa a tus proyectos
- **Tareas Largas**: Plugin Ralph Wiggum para loops iterativos de desarrollo
- **Compresión Automática**: Comprime contexto automáticamente al acercarse al límite

## Requisitos

- macOS con Apple Silicon (para aceleración GPU)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Ollama v0.14.3-rc3+](https://github.com/ollama/ollama/releases) (requerido para GLM-4.7-flash)

## Instalación Rápida

```bash
# Clonar el repo
git clone https://github.com/yourusername/kartostack.git
cd kartostack

# Hacer scripts ejecutables
chmod +x scripts/*.sh

# Instalar Ollama RC + modelo (requerido)
./scripts/install-ollama.sh --with-model

# Configurar entorno
cp .env.example .env
# Editar .env con tu configuración

# Ejecutar el agente
./scripts/run.sh
```

## Configuración

### Variables de Entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `CLAUDE_MODEL` | `glm-4.7-flash-82k` | Modelo de Ollama a usar |
| `OLLAMA_HOST` | `localhost` | Host del servidor Ollama |
| `OLLAMA_PORT` | `11434` | Puerto del servidor Ollama |
| `WORKSPACE` | `$HOME/Projects` | Directorio montado como /workspace |
| `SERPER_API_KEY` | - | Opcional: API key para búsqueda web |

### Variantes del Modelo

El instalador crea automáticamente `glm-4.7-flash-82k` con 82k tokens de contexto.

Para crear variantes manualmente:

```bash
# Variante con 32k de contexto (más rápida)
cat > /tmp/Modelfile << 'EOF'
FROM glm-4.7-flash
PARAMETER num_ctx 32768
EOF
ollama create glm-4.7-flash-32k -f /tmp/Modelfile
```

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    Contenedor Docker                         │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  Claude Code CLI                      │   │
│  │  • Asistente de código con Ollama                    │   │
│  │  • Protocolo MCP para herramientas                   │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────┼───────────────────────────────┐   │
│  │               Servidores MCP                          │   │
│  │  ┌─────────┐  ┌──────────┐  ┌─────────────────────┐  │   │
│  │  │ Serper  │  │Filesystem│  │     Puppeteer       │  │   │
│  │  │(búsqueda)│ │ (archivos)│ │ (automatización web)│  │   │
│  │  └─────────┘  └──────────┘  └─────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────┼───────────────────────────────┐   │
│  │            Plugin Ralph Wiggum                        │   │
│  │  • Loops para tareas largas                          │   │
│  │  • Compresión automática de memoria                  │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Ollama (Nativo)                          │
│                    Aceleración GPU                          │
│                    localhost:11434                          │
└─────────────────────────────────────────────────────────────┘
```

## Herramientas MCP

### Búsqueda Web (Serper)
- `web_search` - Búsqueda en Google
- `news_search` - Artículos de noticias
- `image_search` - Búsqueda de imágenes
- `scrape_webpage` - Scraping completo de página
- `fetch_url` - Extracción de texto limpio

### Browser (Puppeteer)
- `puppeteer_navigate` - Ir a URL
- `puppeteer_screenshot` - Capturar página
- `puppeteer_click` - Click en elementos
- `puppeteer_fill` - Llenar formularios
- `puppeteer_select` - Seleccionar dropdowns
- `puppeteer_evaluate` - Ejecutar JavaScript

### Sistema de Archivos
- `read_file` - Leer archivos
- `write_file` - Escribir archivos
- `list_directory` - Listar contenido

## Tareas de Larga Duración

Para tareas complejas multi-paso, usa el loop Ralph Wiggum:

```
/ralph-loop "Descripción de tu tarea" --max-iterations 50 --completion-promise "TAREA COMPLETA"
```

El loop:
- Repite el mismo prompt en cada iteración
- Preserva trabajo en archivos y git
- Continúa hasta max iterations o cumplir la promesa

Para señalar completado: `<promise>TAREA COMPLETA</promise>`

## Modo No Interactivo

Ejecutar tareas sin interacción:

```bash
./scripts/run.sh --print -p "Crea un script hello world en Python"
```

## Solución de Problemas

### Ollama no responde
```bash
# Verificar si Ollama está corriendo
curl http://localhost:11434/api/tags

# Reiniciar Ollama
pkill ollama && open -a Ollama
```

### Modelo no cargado
```bash
# Ver modelos cargados
ollama ps

# Pre-cargar el modelo
ollama run glm-4.7-flash-82k ""
```

### Problemas de permisos
```bash
# Resetear volumen Docker
docker volume rm kartostack-data
```

### Versión de Ollama incorrecta
```bash
# Verificar versión
ollama --version

# Si es menor a 0.14.3, reinstalar
./scripts/install-ollama.sh
```

## Referencias

- [Artículo completo: Agente de Coding 24/7 prácticamente gratis](https://karim.touma.io/agente-de-ingenier%C3%ADa-de-software-24-7-pr%C3%A1cticamente-gratis-4cbd12e2bd92)
- [Claude Code Docs](https://code.claude.com/docs/en/overview)
- [Ollama + Anthropic API](https://ollama.com/blog/claude)
- [GLM-4.7-Flash en Ollama](https://ollama.com/library/glm-4.7-flash)
- [Serper MCP Server](https://pypi.org/project/serper-mcp-server/)
- [Historia de Ralph Wiggum](https://www.humanlayer.dev/blog/brief-history-of-ralph)

## Autor

**Karim Touma**
- [LinkedIn](https://www.linkedin.com/in/katouma/)
- [Twitter/X](https://x.com/karim_op)
- [Blog](https://karim.touma.io)

## Licencia

MIT
