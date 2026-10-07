#!/bin/bash
# Configuración completa del sistema
# Crea rutas, enlaza configs, prepara el entorno
# y ejecuta la instalación de herramientas

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cargar rutas del entorno (pero forzar CONFIG_PATH al repo actual)
export SCRIPT_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/.env.paths.env"

# Forzar CONFIG_PATH al ubicación real del script
export CONFIG_PATH="$(pwd)"

echo "=================================================="
echo " ConfigLinux - Setup completo"
echo "=================================================="
echo ""
echo "📁 Rutas que se crearán:"
echo "  PROGRAMAS_PATH:        ${PROGRAMAS_PATH}"
echo "  REPOS_PATH:            ${REPOS_PATH}"
echo "  PERSONAL_REPOS_PATH:   ${PERSONAL_REPOS_PATH}"
echo "  WORK_REPOS_PATH:       ${WORK_REPOS_PATH}"
echo "  CONFIG_PATH:           ${CONFIG_PATH}"
echo ""

# --- Funciones ---

create_symlink() {
  local target="$1"
  local dest="$2"
  
  # Si el target no existe, skip
  if [[ ! -e "$target" ]]; then
    echo "   ⚠️  Skip: $dest → $target (no existe)"
    return 0
  fi
  
  # Si ya está bien enlazado, skip
  if [[ -L "$dest" ]]; then
    local current_target="$(readlink -f "$dest" 2>/dev/null || true)"
    if [[ "$current_target" == "$(readlink -f "$target" 2>/dev/null || true)" ]]; then
      echo "   ✅ Ya linked: $dest → $target"
      return 0
    fi
  fi
  
  # Si existe como dir/file real, moverlo a backup
  if [[ -e "$dest" ]] && ! [[ -L "$dest" ]]; then
    local backup="${dest}.bak-$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup" 2>/dev/null || true
    echo "   ⚠️  Respalded: $dest → $backup"
  fi
  
  # Crear el symlink
  ln -sfn "$target" "$dest"
  echo "   🔗 Created: $dest → $target"
}

# --- 1. Crear directorios base ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 1️⃣  Estructura de directorios..."
mkdir -p "$PROGRAMAS_PATH"
mkdir -p "$WORK_REPOS_PATH"
mkdir -p "$PERSONAL_REPOS_PATH"
mkdir -p ~/.fonts
mkdir -p ~/.icons
mkdir -p "${PERSONAL_REPOS_PATH}/1_WORK"
mkdir -p "${PERSONAL_REPOS_PATH}/0_PERSONAL"
echo "✅ Estructura creada"

# --- 2. Verificar pre-configuraciones git ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 2️⃣  Verificando pre-configs..."

if [[ ! -f "${CONFIG_PATH}/.gitconfig.d/personal-mail.gitconfig" ]]; then
  echo "❌ FALTA: .gitconfig.d/personal-mail.gitconfig"
  exit 1
fi

if [[ ! -f "${CONFIG_PATH}/.gitconfig.d/work/work.gitconfig" ]]; then
  echo "❌ FALTA: .gitconfig.d/work/work.gitconfig"
  exit 1
fi

echo "✅ personal-mail.gitconfig exists"
echo "✅ work/work.gitconfig exists"

# --- 3. Configurar Git user ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 3️⃣  Config Git user..."
if [[ -z "$(git config user.name 2>/dev/null)" ]]; then
  git config --global user.name "Sergio Valverde"
  echo "   user.name → Sergio Valverde (global)"
fi

if [[ -z "$(git config user.email 2>/dev/null)" ]]; then
  git config --global user.email "sergio@gmail.com"
  echo "   user.email → sergio@gmail.com (global)"
fi

echo "✅ Git user configured"

# --- 4. Crear enlaces simbólicos ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 4️⃣  Creating symlinks..."

create_symlink "${CONFIG_PATH}/.bashrc"         ~/.bashrc
create_symlink "${CONFIG_PATH}/.aliases"        ~/.aliases
create_symlink "${CONFIG_PATH}/.bash_aliases"   ~/.bash_aliases
create_symlink "${CONFIG_PATH}/.bash_completion" ~/.bash_completion
create_symlink "${CONFIG_PATH}/.bash_completion.d" ~/.bash_completion.d
create_symlink "${CONFIG_PATH}/.bash_aliases.d" ~/.bash_aliases.d
create_symlink "${CONFIG_PATH}/.bash_prompt"    ~/.bash_prompt
create_symlink "${CONFIG_PATH}/.env.paths.env"  ~/.env.paths.env
create_symlink "${CONFIG_PATH}/.profile"        ~/.profile
create_symlink "${CONFIG_PATH}/SCRIPTS"         ~/SCRIPTS
create_symlink "${CONFIG_PATH}/.gitconfig"      ~/.gitconfig

[[ -d "${CONFIG_PATH}/.config" ]]            && create_symlink "${CONFIG_PATH}/.config" ~/.config
[[ -d "${CONFIG_PATH}/.include_d" ]]          && create_symlink "${CONFIG_PATH}/.include_d" ~/.include_d
[[ -d "${CONFIG_PATH}/.rc" ]]                 && create_symlink "${CONFIG_PATH}/.rc" ~/.rc
[[ -d "${CONFIG_PATH}/.rc.d" ]]               && create_symlink "${CONFIG_PATH}/.rc.d" ~/.rc.d

echo "✅ Symlinks created"

# --- 5. Verificar archivos obligatorios ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 5️⃣  Mandatory files..."

mandatory_files=(
  "${CONFIG_PATH}/.bashrc"
  "${CONFIG_PATH}/.vimrc"
  "${CONFIG_PATH}/SCRIPTS/bootstrap/linux-core.sh"
)

for f in "${mandatory_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "❌ MISSING: $f"
    exit 1
  fi
done

echo "✅ Mandatory files found"

# --- 6. Resumen ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✅ FULL SETUP READY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next steps:"
echo "  • Run full bootstrap:  ./run.sh FULL"
echo "  • Or stages:"
echo "    ./SCRIPTS/bootstrap/linux-base.sh       # Base + git + vim"
echo "    ./SCRIPTS/bootstrap/linux-shells.sh     # zsh + oh-my-zsh"
echo "    ./SCRIPTS/bootstrap/linux-devtools.sh   # All dev tools"
echo "    ./SCRIPTS/bootstrap/linux-containers.sh # Docker"
