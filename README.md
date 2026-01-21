# Kartostack

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ollama](https://img.shields.io/badge/Ollama-v0.14.3+-blue.svg)](https://ollama.com)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![GLM-4.7](https://img.shields.io/badge/Model-GLM--4.7--Flash-green.svg)](https://ollama.com/library/glm-4.7-flash)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-CLI-purple.svg)](https://claude.ai)

**Asistente de programación autónomo 24/7** containerizado con Claude Code y modelos locales via Ollama.

> **Guía completa**: Lee el artículo [Agente de Coding 24/7 prácticamente gratis](https://karim.touma.io/agente-de-ingenier%C3%ADa-de-software-24-7-pr%C3%A1cticamente-gratis-4cbd12e2bd92) para entender la arquitectura completa, casos de uso y filosofía detrás del proyecto.

---

## ¿Qué es Kartostack?

Kartostack es un entorno containerizado que combina:

- **Claude Code CLI** - El agente de programación de Anthropic
- **GLM-4.7-Flash** - Modelo de lenguaje local con 82k tokens de contexto
- **Ollama** - Servidor de inferencia local con aceleración GPU
- **MCP Servers** - Herramientas para búsqueda web, browser automation y filesystem
- **Ralph Wiggum** - Plugin para tareas de larga duración con loops iterativos

El resultado: un agente de programación que puede trabajar **horas sin supervisión**, con acceso a internet, automatización de browser y gestión inteligente de memoria.

---

## Stack Tecnológico

```
VS Code + Claude Code + GLM-4.7-Flash + Ollama + Serper MCP + Puppeteer MCP + Ralph-Wiggum
```

| Componente | Función | Ubicación |
|------------|---------|-----------|
| **Claude Code** | Agente CLI de programación | Container |
| **GLM-4.7-Flash** | LLM (82k contexto) | Host (Ollama) |
| **Ollama** | Servidor de inferencia | Host (nativo) |
| **Serper MCP** | Búsqueda web (Google) | Container |
| **Puppeteer MCP** | Browser automation | Container |
| **Filesystem MCP** | Acceso a archivos | Container |
| **Ralph Wiggum** | Loops iterativos | Container |

---

## Características Principales

### 🤖 LLM Local con Contexto Amplio
- Modelo GLM-4.7-Flash corriendo localmente via Ollama
- **82,000 tokens de contexto** (configurable hasta 198k)
- Aceleración GPU con Apple Metal (macOS) o CUDA (Linux)
- Sin límites de API ni costos por token

### 🌐 Búsqueda Web Integrada
- Búsqueda en Google via Serper API
- Búsqueda de noticias y imágenes
- Web scraping con extracción de texto limpio
- El agente puede investigar antes de implementar

### 🖥️ Browser Automation
- Chromium headless integrado
- Navegación, clicks, formularios
- Screenshots y evaluación de JavaScript
- Ideal para testing y scraping de SPAs

### 📁 Acceso Completo al Sistema de Archivos
- Lectura y escritura de archivos
- Navegación de directorios
- El agente puede modificar tu código directamente

### 🔄 Tareas de Larga Duración (Ralph Wiggum)
- Loops iterativos con condiciones de salida
- Compresión automática de memoria al 70% del contexto
- Preservación de trabajo en archivos y git
- Ideal para refactorings, migraciones, implementaciones complejas

### 📦 Containerizado y Portable
- Todo empaquetado en Docker
- Configuración persistente en volumen
- Fácil de replicar en cualquier máquina

---

## Requisitos del Sistema

### Hardware Recomendado

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| **RAM** | 32GB | 64GB+ |
| **VRAM/Unified** | 32GB | 64GB+ |
| **Disco** | 50GB libres | 100GB libres |
| **GPU** | Apple M1/M2 | Apple M3/M4 Max |

> **Nota sobre memoria**: GLM-4.7-Flash con 82k de contexto usa ~97GB de memoria (modelo q8_0 + KV cache). En Macs con memoria unificada, esto funciona bien con 128GB.

### Software Requerido

- **macOS** con Apple Silicon (M1/M2/M3/M4) para aceleración GPU
  - También funciona en Linux con CUDA
- **Docker Desktop** v4.0+
- **Ollama v0.14.3-rc3+** (requerido para GLM-4.7-flash)
  - ⚠️ La versión estable 0.14.2 NO soporta este modelo

### Opcional

- **Serper API Key** - Para búsquedas web ([serper.dev](https://serper.dev))
- **VS Code** - Para integración con Claude Code extension

---

## Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/karimtouma/kartostack.git
cd kartostack
```

### 2. Hacer Scripts Ejecutables

```bash
chmod +x scripts/*.sh
chmod +x entrypoint.sh
chmod +x plugins/ralph-wiggum/hooks/*.sh
chmod +x plugins/ralph-wiggum/scripts/*.sh
```

### 3. Instalar Ollama RC + Modelo

El script detecta tu sistema operativo y arquitectura automáticamente:

```bash
# Solo instalar Ollama RC
./scripts/install-ollama.sh

# Instalar Ollama RC + descargar modelo + crear variante 82k
./scripts/install-ollama.sh --with-model
```

**¿Qué hace el script?**
1. Detecta si es macOS o Linux
2. Descarga Ollama v0.14.3-rc3 desde GitHub releases
3. Instala en `/Applications` (macOS) o `/usr/local/bin` (Linux)
4. Opcionalmente descarga `glm-4.7-flash` (~19-32GB)
5. Crea la variante `glm-4.7-flash-82k` con contexto expandido

### 4. Configurar Entorno

```bash
cp .env.example .env
```

Edita `.env` con tu configuración:

```bash
# Modelo a usar
CLAUDE_MODEL=glm-4.7-flash-82k

# Tu directorio de proyectos
WORKSPACE=/Users/tu-usuario/Projects

# API key de Serper (opcional, para búsqueda web)
SERPER_API_KEY=tu_api_key_aqui
```

### 5. Construir Imagen Docker

```bash
docker build -t kartostack .
```

### 6. Ejecutar

```bash
./scripts/run.sh
```

---

## Uso

### Modo Interactivo (Default)

```bash
./scripts/run.sh
```

Esto abre una sesión interactiva donde puedes chatear con el agente.

### Modo No Interactivo

Ejecutar una tarea específica y obtener el resultado:

```bash
# Tarea simple
./scripts/run.sh --print -p "Crea un script hello world en Python"

# Tarea con contexto
./scripts/run.sh --print -p "Analiza el código en src/ y genera un reporte de arquitectura"
```

### Tareas de Larga Duración (Ralph Wiggum)

Para tareas complejas que requieren múltiples iteraciones:

```bash
./scripts/run.sh
```

Dentro del agente:

```
/ralph-loop "Implementa autenticación JWT en el proyecto" --max-iterations 30 --completion-promise "AUTH COMPLETE"
```

**Parámetros:**
- `--max-iterations N` - Máximo de iteraciones (default: 50)
- `--completion-promise "TEXT"` - Texto que señala completado

**Para señalar que terminaste:**
```
<promise>AUTH COMPLETE</promise>
```

### Ejemplos de Prompts Efectivos

#### Investigación + Implementación
```
Usa web_search para encontrar la documentación oficial de FastAPI sobre
dependency injection. Luego implementa un sistema de autenticación
basado en esos patrones en src/auth/. Criterio de completitud:
todos los tests en tests/auth/ deben pasar.
```

#### Refactoring con Tests
```
Refactoriza el módulo src/database/ para usar el patrón Repository.
Criterios:
- Mantener 100% de compatibilidad con la API existente
- Agregar tests unitarios para cada repository
- pnpm test debe pasar sin errores
- Genera REFACTOR_REPORT.md con los cambios realizados
```

#### Scraping con Browser
```
Usa puppeteer_navigate para ir a https://example.com/pricing.
Extrae la tabla de precios y guárdala como JSON en data/pricing.json.
Toma un screenshot y guárdalo en screenshots/pricing.png.
```

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DOCKER CONTAINER                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                      CLAUDE CODE CLI                          │  │
│   │                                                                │  │
│   │   • Agente de programación autónomo                          │  │
│   │   • Lee/escribe archivos, ejecuta comandos                   │  │
│   │   • Protocolo MCP para herramientas externas                 │  │
│   │   • Gestión de contexto y memoria                            │  │
│   │                                                                │  │
│   └──────────────────────────┬───────────────────────────────────┘  │
│                              │                                       │
│              ┌───────────────┼───────────────┐                      │
│              │               │               │                      │
│              ▼               ▼               ▼                      │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│   │  SERPER MCP  │  │FILESYSTEM MCP│  │PUPPETEER MCP │             │
│   │              │  │              │  │              │             │
│   │ • web_search │  │ • read_file  │  │ • navigate   │             │
│   │ • news_search│  │ • write_file │  │ • click      │             │
│   │ • scrape_url │  │ • list_dir   │  │ • fill       │             │
│   │ • fetch_url  │  │              │  │ • screenshot │             │
│   └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                    RALPH WIGGUM PLUGIN                        │  │
│   │                                                                │  │
│   │   • /ralph-loop - Iniciar loop iterativo                     │  │
│   │   • /cancel-ralph - Cancelar loop activo                     │  │
│   │   • Auto-compresión de memoria al 70% del contexto           │  │
│   │   • Preservación de estado en archivos                       │  │
│   │                                                                │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────┬──────────────────────────────────┘
                                   │
                                   │ HTTP (Anthropic API)
                                   │ localhost:11434
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         HOST (macOS/Linux)                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                         OLLAMA                                │  │
│   │                                                                │  │
│   │   • Servidor de inferencia local                             │  │
│   │   • API compatible con Anthropic Messages                    │  │
│   │   • Aceleración GPU (Metal/CUDA)                             │  │
│   │                                                                │  │
│   │   Modelo: GLM-4.7-Flash                                      │  │
│   │   Contexto: 82,000 tokens                                    │  │
│   │   Memoria: ~97GB (q8_0 + KV cache)                           │  │
│   │                                                                │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### ¿Por qué Ollama corre en el Host y no en Docker?

**Docker en macOS NO puede acceder a la GPU Metal**. Por lo tanto:
- Ollama debe correr **nativo** para usar aceleración GPU (5-6x más rápido)
- El container se conecta al host via `host.docker.internal:11434`
- Esto es transparente para el usuario

---

## Configuración Avanzada

### Variables de Entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `CLAUDE_MODEL` | `glm-4.7-flash-82k` | Modelo de Ollama a usar |
| `OLLAMA_HOST` | `localhost` | Host del servidor Ollama |
| `OLLAMA_PORT` | `11434` | Puerto del servidor Ollama |
| `WORKSPACE` | `$HOME/Projects` | Directorio montado como /workspace |
| `IMAGE_NAME` | `kartostack` | Nombre de la imagen Docker |
| `VOLUME_NAME` | `kartostack-data` | Nombre del volumen para persistencia |
| `SERPER_API_KEY` | - | API key de Serper para búsqueda web |

### Variantes del Modelo

El modelo base `glm-4.7-flash` tiene 198k de contexto máximo. Puedes crear variantes con diferentes tamaños:

```bash
# Variante rápida (32k contexto, menos memoria)
cat > /tmp/Modelfile.32k << 'EOF'
FROM glm-4.7-flash
PARAMETER num_ctx 32768
EOF
ollama create glm-4.7-flash-32k -f /tmp/Modelfile.32k

# Variante máxima (198k contexto, mucha memoria)
cat > /tmp/Modelfile.198k << 'EOF'
FROM glm-4.7-flash
PARAMETER num_ctx 198000
EOF
ollama create glm-4.7-flash-198k -f /tmp/Modelfile.198k
```

| Variante | Contexto | Memoria Aprox. | Uso |
|----------|----------|----------------|-----|
| 32k | 32,768 | ~40GB | Tareas rápidas |
| 82k | 82,000 | ~97GB | **Default** - Balance |
| 198k | 198,000 | ~200GB | Tareas con mucho contexto |

### Pre-carga Automática del Modelo (Anti Cold Start)

El script `run.sh` **pre-carga automáticamente** el modelo en memoria antes de iniciar el container, eliminando el "cold start":

```bash
./scripts/run.sh
```

**Si el modelo ya está en memoria:**
```
✓ Modelo glm-4.7-flash-82k ya está en memoria
```

**Si necesita cargarse (~1-2 minutos):**
```
🔥 Pre-cargando modelo glm-4.7-flash-82k en memoria...
   (Esto puede tardar 1-2 minutos la primera vez)
   Cargando........................ ✓
```

El agente está listo para responder **inmediatamente** cuando se inicia la sesión.

### Mantener Modelo en Memoria 24/7

Para que Ollama **nunca** descargue el modelo de memoria (ideal para uso continuo):

```bash
# Opción 1: Variable de entorno al iniciar Ollama
OLLAMA_KEEP_ALIVE=-1 ollama serve

# Opción 2: Configurar al cargar el modelo
ollama run glm-4.7-flash-82k --keepalive -1
```

O agregar permanentemente en el Modelfile:
```
FROM glm-4.7-flash
PARAMETER num_ctx 82000
PARAMETER keep_alive -1
```

> **Nota**: Con `keep_alive=-1`, el modelo permanece en memoria (~97GB) hasta que reinicies Ollama o tu máquina.

### Configuración de MCP Servers

Los servidores MCP están configurados en `mcp-config.json`:

```json
{
  "mcpServers": {
    "serper": {
      "command": "node",
      "args": ["/app/mcp-servers/serper/index.js"],
      "env": { "SERPER_API_KEY": "${SERPER_API_KEY}" }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    },
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"],
      "env": { "PUPPETEER_EXECUTABLE_PATH": "/usr/bin/chromium" }
    }
  }
}
```

---

## Herramientas MCP Disponibles

### Serper (Búsqueda Web)

| Herramienta | Descripción | Ejemplo |
|-------------|-------------|---------|
| `web_search` | Búsqueda en Google | `web_search("FastAPI authentication")` |
| `news_search` | Búsqueda de noticias | `news_search("OpenAI GPT-5")` |
| `image_search` | Búsqueda de imágenes | `image_search("React architecture diagram")` |
| `scrape_webpage` | Scraping completo | `scrape_webpage("https://docs.python.org")` |
| `fetch_url` | Extracción de texto limpio | `fetch_url("https://example.com/article")` |

### Puppeteer (Browser Automation)

| Herramienta | Descripción |
|-------------|-------------|
| `puppeteer_navigate` | Navegar a URL |
| `puppeteer_screenshot` | Capturar screenshot |
| `puppeteer_click` | Click en elemento |
| `puppeteer_fill` | Llenar input/textarea |
| `puppeteer_select` | Seleccionar en dropdown |
| `puppeteer_hover` | Hover sobre elemento |
| `puppeteer_evaluate` | Ejecutar JavaScript |

### Filesystem

| Herramienta | Descripción |
|-------------|-------------|
| `read_file` | Leer contenido de archivo |
| `write_file` | Escribir/crear archivo |
| `list_directory` | Listar contenido de directorio |

---

## Plugin Ralph Wiggum

Ralph Wiggum implementa la técnica de **loops iterativos con condiciones de salida** para tareas de larga duración.

### Comandos Disponibles

| Comando | Descripción |
|---------|-------------|
| `/ralph-loop` | Iniciar loop iterativo |
| `/cancel-ralph` | Cancelar loop activo |
| `/help` | Ayuda del plugin |

### Cómo Funciona

1. Defines una tarea con criterios de completitud
2. El agente trabaja iterativamente
3. En cada iteración, evalúa si cumplió los criterios
4. Si los cumple, imprime `<promise>CRITERIO</promise>`
5. El loop termina cuando se cumple o se alcanza max iterations

### Auto-Compresión de Memoria

Cuando el contexto alcanza ~70% del límite (70k tokens para modelo 82k):

1. El hook `stop-hook.sh` detecta el tamaño
2. Guarda contexto crítico en `.claude/memory.md`
3. Inicia nueva sesión con instrucciones de leer el archivo
4. El agente continúa donde quedó

Esto permite tareas que duran **horas** sin perder contexto.

---

## Solución de Problemas

### Ollama no responde

```bash
# Verificar si Ollama está corriendo
curl http://localhost:11434/api/tags

# Ver logs de Ollama
tail -f ~/.ollama/logs/server.log

# Reiniciar Ollama
pkill ollama
open -a Ollama  # macOS
# o: systemctl restart ollama  # Linux
```

### Modelo no cargado en memoria

```bash
# Ver modelos cargados actualmente
ollama ps

# Pre-cargar el modelo
ollama run glm-4.7-flash-82k ""

# Verificar uso de memoria
# macOS:
vm_stat | grep "Pages"
# Linux:
free -h
```

### Error de permisos en Docker

```bash
# Resetear volumen (pierde configuración persistida)
docker volume rm kartostack-data

# Reconstruir imagen
docker build --no-cache -t kartostack .
```

### Versión de Ollama incorrecta

```bash
# Verificar versión actual
ollama --version

# Si es menor a 0.14.3, reinstalar
./scripts/install-ollama.sh
```

### Serper MCP no funciona

```bash
# Verificar que la API key está configurada
echo $SERPER_API_KEY

# Probar la API directamente
curl -X POST 'https://google.serper.dev/search' \
  -H 'X-API-KEY: TU_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"q": "test"}'
```

### Puppeteer no puede iniciar Chromium

```bash
# Verificar que Chromium está instalado en el container
docker run --rm kartostack which chromium

# Si falla, reconstruir imagen
docker build --no-cache -t kartostack .
```

### El agente se queda "pensando" mucho tiempo

- GLM-4.7-Flash es más lento que modelos cloud
- En Apple Silicon M4 Max: ~60 tokens/segundo
- Prompts largos pueden tardar minutos
- Considera usar la variante 32k para tareas rápidas

---

## Estructura del Proyecto

```
kartostack/
├── .env.example              # Template de configuración
├── .gitignore                # Archivos ignorados por git
├── Dockerfile                # Imagen del container
├── entrypoint.sh             # Script de entrada del container
├── Modelfile.82k             # Definición del modelo con 82k contexto
├── README.md                 # Esta documentación
├── CLAUDE.md                 # Instrucciones para el modelo
├── claude.json               # Estado pre-configurado de Claude Code
├── mcp-config.json           # Configuración de servidores MCP
├── settings.json             # Configuración de Claude Code
│
├── mcp-servers/
│   └── serper/
│       ├── index.js          # Servidor MCP de Serper
│       └── package.json      # Dependencias
│
├── plugins/
│   └── ralph-wiggum/
│       ├── .claude-plugin/
│       │   └── plugin.json   # Metadata del plugin
│       ├── commands/
│       │   ├── ralph-loop.md # Comando principal
│       │   ├── cancel-ralph.md
│       │   ├── compress-memory.md
│       │   └── help.md
│       ├── hooks/
│       │   ├── hooks.json    # Configuración de hooks
│       │   └── stop-hook.sh  # Hook de compresión
│       ├── scripts/
│       │   ├── setup-ralph-loop.sh
│       │   └── compress-memory.sh
│       └── README.md
│
└── scripts/
    ├── install-ollama.sh     # Instalador de Ollama RC
    └── run.sh                # Script principal de ejecución
```

---

## Seguridad

### Consideraciones

- El agente tiene **acceso completo** al directorio montado como workspace
- Puede ejecutar comandos de sistema dentro del container
- Puede hacer requests HTTP a internet (si Serper está configurado)
- **No lo uses en directorios con información sensible**

### Recomendaciones

1. **Monta solo lo necesario** - No montes `/` o `$HOME` completo
2. **Revisa los cambios** - Usa git para trackear cambios del agente
3. **Limita las iteraciones** - Siempre usa `--max-iterations` con Ralph
4. **Revisa el output** - Especialmente en tareas de larga duración

---

## Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## Referencias

### Documentación Oficial
- [Claude Code Docs](https://code.claude.com/docs/en/overview)
- [Ollama Documentation](https://ollama.com/docs)
- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)

### Artículos y Guías
- [Agente de Coding 24/7 prácticamente gratis](https://karim.touma.io/agente-de-ingenier%C3%ADa-de-software-24-7-pr%C3%A1cticamente-gratis-4cbd12e2bd92) - Guía completa del autor
- [Ollama + Claude Code](https://ollama.com/blog/claude) - Blog oficial de Ollama
- [Historia de Ralph Wiggum](https://www.humanlayer.dev/blog/brief-history-of-ralph) - Origen de la técnica

### Recursos
- [GLM-4.7-Flash en Ollama](https://ollama.com/library/glm-4.7-flash)
- [Serper API](https://serper.dev)
- [Puppeteer MCP Server](https://github.com/anthropics/anthropic-quickstarts)

---

## Autor

**Karim Touma**

- [Blog](https://karim.touma.io)
- [LinkedIn](https://www.linkedin.com/in/katouma/)
- [Twitter/X](https://x.com/karim_op)

---

## Licencia

MIT License - ver [LICENSE](LICENSE) para detalles.

---

<p align="center">
  <i>Hecho con ❤️ y mucho café por <a href="https://karim.touma.io">Karim Touma</a></i>
</p>
