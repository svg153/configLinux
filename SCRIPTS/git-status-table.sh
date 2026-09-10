#!/bin/bash

# Script para mostrar el estado de múltiples repositorios Git en una tabla
# Dependencias: gum (https://github.com/charmbracelet/gum)

# Colores
RED=196
GREEN=46
YELLOW=226
BLUE=39
GRAY=240
ORANGE=208

# Función para verificar si gum está instalado
check_gum() {
    if ! command -v gum &> /dev/null; then
        echo "❌ Error: gum no está instalado."
        echo "Instálalo con:"
        echo "  - macOS: brew install gum"
        echo "  - Linux: sudo mkdir -p /etc/apt/keyrings"
        echo "           curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg"
        echo "           echo \"deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *\" | sudo tee /etc/apt/sources.list.d/charm.list"
        echo "           sudo apt update && sudo apt install gum"
        echo "  - O descarga desde: https://github.com/charmbracelet/gum/releases"
        exit 1
    fi
}

# Función para obtener el estado de un repositorio
get_repo_status() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    # Cambiar al directorio del repo
    cd "$repo_path" || return
    
    # Verificar si es un repositorio Git
    if [ ! -d ".git" ]; then
        echo "$repo_name,❌ No Git,,,,"
        return
    fi
    
    # Obtener la rama actual
    local branch=$(git branch --show-current 2>/dev/null || echo "N/A")
    
    # Contar cambios
    local untracked=$(git ls-files --others --exclude-standard | wc -l)
    local modified=$(git diff --name-only | wc -l)
    local staged=$(git diff --cached --name-only | wc -l)
    
    # Estado del tracking remoto
    local ahead=0
    local behind=0
    local remote_status="✓"
    
    if git rev-parse --abbrev-ref @{upstream} &>/dev/null; then
        ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
        behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
        
        if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
            remote_status="↕ $ahead↑ $behind↓"
        elif [ "$ahead" -gt 0 ]; then
            remote_status="↑ $ahead"
        elif [ "$behind" -gt 0 ]; then
            remote_status="↓ $behind"
        else
            remote_status="✓ Sync"
        fi
    else
        remote_status="⚠ No remote"
    fi
    
    # Estado general
    local status="✓ Clean"
    if [ "$modified" -gt 0 ] || [ "$staged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        status="⚠ Changes"
    fi
    
    # Último commit (primera línea del mensaje)
    local last_commit=$(git log -1 --pretty=format:"%s" 2>/dev/null | cut -c1-40)
    [ -z "$last_commit" ] && last_commit="No commits"
    
    # Salida en formato CSV
    echo "$repo_name,$branch,$status,M:$modified S:$staged U:$untracked,$remote_status,$last_commit"
}

# Función principal
main() {
    local scan_dir="${1:-.}"
    
    check_gum
    
    # Banner
    gum style \
        --foreground "$BLUE" \
        --border double \
        --border-foreground "$BLUE" \
        --align center \
        --width 80 \
        --margin "1 0" \
        --padding "1 2" \
        "🔍 Git Repository Status Scanner" \
        "Scanning: $scan_dir"
    
    # Crear archivo temporal para datos
    local temp_file=$(mktemp)
    
    # Encabezados
    echo "Repository,Branch,Status,Changes,Remote,Last Commit" > "$temp_file"
    
    # Buscar todos los directorios con .git (sin entrar en repos ya encontrados)
    # Crear script temporal para evitar problemas con declare -f en subshells
    local temp_script=$(mktemp)
    cat > "$temp_script" << 'EOFSCRIPT'
get_repo_status() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    cd "$repo_path" || return
    
    if [ ! -d ".git" ]; then
        echo "$repo_name,❌ No Git,,,,"
        return
    fi
    
    local branch=$(git branch --show-current 2>/dev/null || echo "N/A")
    local untracked=$(git ls-files --others --exclude-standard | wc -l)
    local modified=$(git diff --name-only | wc -l)
    local staged=$(git diff --cached --name-only | wc -l)
    
    local ahead=0
    local behind=0
    local remote_status="✓"
    
    if git rev-parse --abbrev-ref @{upstream} &>/dev/null; then
        ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
        behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
        
        if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
            remote_status="↕ $ahead↑ $behind↓"
        elif [ "$ahead" -gt 0 ]; then
            remote_status="↑ $ahead"
        elif [ "$behind" -gt 0 ]; then
            remote_status="↓ $behind"
        else
            remote_status="✓ Sync"
        fi
    else
        remote_status="⚠ No remote"
    fi
    
    local status="✓ Clean"
    if [ "$modified" -gt 0 ] || [ "$staged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        status="⚠ Changes"
    fi
    
    local last_commit=$(git log -1 --pretty=format:"%s" 2>/dev/null | cut -c1-40)
    [ -z "$last_commit" ] && last_commit="No commits"
    
    echo "$repo_name,$branch,$status,M:$modified S:$staged U:$untracked,$remote_status,$last_commit"
}

scan_dir="$(cd "$1" && pwd)"
cd "$scan_dir" || exit 1
find . -type d -name '.git' -prune 2>/dev/null | while read -r git_dir; do
    repo_dir=$(dirname "$git_dir")
    abs_path="$scan_dir/$repo_dir"
    abs_path="${abs_path//\/.\//\/}"  # Limpiar ./
    get_repo_status "$abs_path" >> "$2"
done
EOFSCRIPT
    
    # Ejecutar el script (con spinner)
    if command -v gum &> /dev/null; then
        gum spin --spinner dot --title "Scanning repositories..." -- bash "$temp_script" "$scan_dir" "$temp_file"
    else
        bash "$temp_script" "$scan_dir" "$temp_file"
    fi
    rm "$temp_script"
    
    # Contar repositorios encontrados
    local repo_count=$(($(wc -l < "$temp_file") - 1))
    
    if [ "$repo_count" -eq 0 ]; then
        gum style \
            --foreground "$YELLOW" \
            --bold \
            "⚠️  No se encontraron repositorios Git en: $scan_dir"
        rm "$temp_file"
        exit 0
    fi
    
    # Mostrar estadísticas
    gum style \
        --foreground "$GREEN" \
        --bold \
        --margin "1 0 0 0" \
        "📊 Found $repo_count repositories"
    
    # Mostrar tabla con gum
    echo ""
    gum table \
        --border rounded \
        --border.foreground "$BLUE" \
        --columns "Repository,Branch,Status,Changes,Remote,Last Commit" \
        --widths 25,15,12,18,15,45 \
        --print < "$temp_file"
    
    # Resumen de estados
    echo ""
    local clean_count=$(grep -c "Clean" "$temp_file")
    local dirty_count=$(grep -c "Changes" "$temp_file")
    local no_remote=$(grep -c "No remote" "$temp_file")
    
    SUMMARY=$(gum style --foreground "$GREEN" "✓ Clean: $clean_count")
    SUMMARY="$SUMMARY  "
    SUMMARY="$SUMMARY$(gum style --foreground "$ORANGE" "⚠ With changes: $dirty_count")"
    SUMMARY="$SUMMARY  "
    SUMMARY="$SUMMARY$(gum style --foreground "$YELLOW" "⚠ No remote: $no_remote")"
    
    echo "$SUMMARY"
    echo ""
    
    # Limpiar
    rm "$temp_file"
}

# Ejecutar
main "$@"
