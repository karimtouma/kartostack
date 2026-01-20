#!/bin/bash
# =============================================================================
# Instalar Ollama RC (requerido para GLM-4.7-flash)
# =============================================================================
#
# GLM-4.7-flash requiere Ollama v0.14.3-rc3 o superior.
# Este script instala la versión RC desde GitHub releases.
#
# Uso:
#   ./install-ollama.sh              # Instala Ollama RC
#   ./install-ollama.sh --with-model # Instala Ollama RC + descarga modelo
#
# =============================================================================

set -e

# Configuración
OLLAMA_VERSION="${OLLAMA_VERSION:-v0.14.3-rc3}"
MODEL_NAME="glm-4.7-flash"
MODEL_82K_NAME="glm-4.7-flash-82k"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar sistema operativo
check_os() {
    case "$(uname -s)" in
        Darwin) OS="darwin" ;;
        Linux)  OS="linux" ;;
        *)      log_error "Sistema operativo no soportado: $(uname -s)"; exit 1 ;;
    esac

    case "$(uname -m)" in
        x86_64)  ARCH="amd64" ;;
        arm64)   ARCH="arm64" ;;
        aarch64) ARCH="arm64" ;;
        *)       log_error "Arquitectura no soportada: $(uname -m)"; exit 1 ;;
    esac

    log_info "Sistema detectado: ${OS}/${ARCH}"
}

# Verificar si Ollama ya está instalado
check_existing() {
    if command -v ollama &> /dev/null; then
        CURRENT_VERSION=$(ollama --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?' || echo "unknown")
        log_warn "Ollama ya instalado: v${CURRENT_VERSION}"

        # Verificar si es versión suficiente
        if [[ "$CURRENT_VERSION" == *"0.14.3"* ]] || [[ "$CURRENT_VERSION" > "0.14.3" ]]; then
            log_info "Versión compatible con GLM-4.7-flash"
            return 0
        else
            log_warn "Se requiere actualizar a ${OLLAMA_VERSION} para GLM-4.7-flash"
            return 1
        fi
    fi
    return 1
}

# Instalar Ollama en macOS
install_macos() {
    log_info "Instalando Ollama ${OLLAMA_VERSION} para macOS..."

    # Descargar desde GitHub releases
    DOWNLOAD_URL="https://github.com/ollama/ollama/releases/download/${OLLAMA_VERSION}/Ollama-darwin.zip"
    TEMP_DIR=$(mktemp -d)

    log_info "Descargando desde: ${DOWNLOAD_URL}"
    curl -L -o "${TEMP_DIR}/Ollama.zip" "$DOWNLOAD_URL"

    log_info "Extrayendo..."
    unzip -q "${TEMP_DIR}/Ollama.zip" -d "${TEMP_DIR}"

    # Mover a Applications
    if [ -d "/Applications/Ollama.app" ]; then
        log_warn "Eliminando versión anterior..."
        rm -rf "/Applications/Ollama.app"
    fi

    log_info "Instalando en /Applications..."
    mv "${TEMP_DIR}/Ollama.app" "/Applications/"

    # Limpiar
    rm -rf "${TEMP_DIR}"

    log_info "Ollama instalado correctamente"
    log_info "Iniciando Ollama..."
    open -a Ollama

    # Esperar a que inicie
    sleep 3
}

# Instalar Ollama en Linux
install_linux() {
    log_info "Instalando Ollama ${OLLAMA_VERSION} para Linux..."

    DOWNLOAD_URL="https://github.com/ollama/ollama/releases/download/${OLLAMA_VERSION}/ollama-linux-${ARCH}"

    log_info "Descargando desde: ${DOWNLOAD_URL}"
    sudo curl -L -o /usr/local/bin/ollama "$DOWNLOAD_URL"
    sudo chmod +x /usr/local/bin/ollama

    # Crear servicio systemd
    log_info "Configurando servicio systemd..."
    sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=$USER
Group=$USER
Restart=always
RestartSec=3
Environment="HOME=$HOME"

[Install]
WantedBy=default.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ollama
    sudo systemctl start ollama

    log_info "Ollama instalado y servicio iniciado"
}

# Descargar modelo
download_model() {
    log_info "Esperando a que Ollama esté listo..."
    for i in {1..30}; do
        if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    if ! curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
        log_error "Ollama no responde en localhost:11434"
        log_error "Inicia Ollama manualmente: open -a Ollama (macOS) o systemctl start ollama (Linux)"
        exit 1
    fi

    log_info "Descargando modelo ${MODEL_NAME}..."
    log_info "Esto puede tardar varios minutos dependiendo de tu conexión..."
    ollama pull "$MODEL_NAME"

    log_info "Creando variante con 82k de contexto..."
    create_82k_variant
}

# Crear variante con 82k contexto
create_82k_variant() {
    MODELFILE=$(mktemp)
    cat > "$MODELFILE" <<EOF
FROM ${MODEL_NAME}
PARAMETER num_ctx 82000
EOF

    ollama create "$MODEL_82K_NAME" -f "$MODELFILE"
    rm "$MODELFILE"

    log_info "Modelo ${MODEL_82K_NAME} creado con contexto de 82k tokens"
}

# Main
main() {
    echo "============================================="
    echo "  Instalador de Ollama RC para Kartostack"
    echo "============================================="
    echo ""

    check_os

    # Verificar instalación existente
    if check_existing; then
        if [[ "$1" == "--with-model" ]]; then
            download_model
        fi
        exit 0
    fi

    # Instalar según OS
    case "$OS" in
        darwin) install_macos ;;
        linux)  install_linux ;;
    esac

    # Descargar modelo si se solicitó
    if [[ "$1" == "--with-model" ]]; then
        download_model
    else
        echo ""
        log_info "Ollama instalado. Para descargar el modelo ejecuta:"
        echo "  ollama pull ${MODEL_NAME}"
        echo ""
        log_info "O ejecuta este script con --with-model:"
        echo "  ./install-ollama.sh --with-model"
    fi

    echo ""
    log_info "Instalación completada"
}

main "$@"
