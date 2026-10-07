# Evaluación Actualizada - Herramientas configLinux (WSL Ubuntu)

## ESTATUS DEL SISTEMA
| Herramienta | Estado |
|-------------|--------|
| git | ✅ INSTALADA |
| curl | ✅ INSTALADA |
| vim | ✅ INSTALADA |
| python3 | ✅ INSTALADA |
| gh | ✅ INSTALADA |
| lshw | ✅ INSTALADA |

**Todo lo demás → NO INSTALADO** (~40 herramientas pendientes)

---

## 🏆 EVALUACIÓN POR PRIORIDAD (actualizada 2026-10-07)

### 🔴 PRIORIDAD 1: ESSENTIAL (instalar sí o sí, antes de todo)

| Herramienta | ¿Por qué | ¿Script lo instala? | Nota |
|-------------|----------|---------------------|------|
| **bash-completion** | Auto-complete de comandos | ✅ SÍ (linux-base) | |
| **zip/unzip** | Descomprimir archivos | ✅ SÍ (linux-base) | Básico pero necesario |
| **xclip** | Copiar/petar con pipe (`echo "x" \| xclip`) | ✅ SÍ (linux-base) | ESSENTIAL para agents! |
| **python3** | Runtime Python | ✅ YA INSTALADA | |
| **pip** | pipx (instala CLI tools) | ✅ (linux-devtools) | pipx NO está instalado |
| **pre-commit** | Git hooks para code quality | ✅ (linux-devtools) | ESSENTIAL |
| **black** | Formateador Python | ✅ (linux-devtools) | ESSENTIAL |
| **ansible-lint** | Linter Ansible | ✅ (linux-devtools) | Si usas Ansible |
| **jq** | Procesar JSON | ✅ (cli_tooling_bundle vía webi) | ESSENTIAL |
| **yq** | jq para YAML (el usuario LO QUIERE) | ✅ (cli_tooling_bundle vía webi) | **Usuario confirmó que la quiere** |
| **ripgrep (rg)** | Grep moderno 10x más rápido | ✅ (cli_tooling_bundle vía webi) | ESSENTIAL |
| **fd** | fd-find moderno | ✅ (cli_tooling_bundle vía webi) | ESSENTIAL |
| **bat** | Cat con highlight | ✅ (cli_tooling_bundle vía webi) | ESSENTIAL |
| **starship** | Prompt bonito | ✅ (cli_tooling_bundle) | ESSENTIAL |
| **fzf** | Fuzzy finder terminal | ✅ (cli_tooling_bundle) | ESSENTIAL |
| **task (gotask)** | Task runner moderno | ✅ (cli_tooling_bundle) | ESSENTIAL |
| **ShellCheck** | Linter bash scripts | ✅ (cli_tooling_bundle vía webi) | ESSENTIAL |
| **shfmt** | Formatter scripts bash | ✅ (cli_tooling_bundle vía webi) | ESSENTIAL |

### 🔴 PRIORIDAD 2: RUNTIMES (necesarios para las tools)

| Herramienta | Versión | ¿Script lo instala? | ⚠️ BUG/ACTUALIZACIÓN |
|-------------|---------|---------------------|---------------------|
| **Node.js** | 22.x (nodejs) | ✅ (linux-devtools vía nodesource 22.x) | **🐛 BUG: Node 22.x está EOL! Debería usar 24.x o 20.x** |
| **Go** | 1.23.4 | ✅ (linux-devtools) | Hardcoded a 1.23.4 - revisar si está actualizada |
| **pipx** | - | ✅ (linux-devtools) | Necesario antes que pre-commit/ansible-lint |

### 🟡 Node.js - ¿Qué versión usar?

El script usa Node 22.x (NodeSource `setup_22.x`). **Node 22.x está EOL desde Abril 2026**.

| Versión | Estado EOL | Soporte hasta |
|---------|-----------|---------------|
| v20.x | EOL (April 2026) | ~30 de Abril 2026 |
| v22.x | EOL (April 2027) | 30 de Abril 2027 |
| **v24.x** | **✅ EN LTS** | **Abril 2028** |
| v26.x | Current (no LTS) | - |

**La versión que debería usar el script es la 24.x LTS (hasta 2028).**

Recomiendo usar **nvm** para gestionar versiones:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install --lts   # Instala la última LTS automáticamente (actualmente 24.x)
nvm alias default 24
```

**Sin nvm**: Cambiar el script para que use `setup_24.x` en vez de `setup_22.x`

### 🟡 PRIORIDAD 3: HERRAMIENTAS OPCIONALES (no esenciales pero útiles)

| Herramienta | ¿Instalar? | ¿Por qué? | ¿Script lo instala? |
|-------------|-----------|-----------|---------------------|
| **w3m** | ⚠️ OPCIÓN del usuario | El usuario dice que SÍ para agentes. Es navegadores de terminal. Útil para verificar URLs o debug de web desde CLI. Algunos agentes antiguos lo usan. | ✅ (cli_tooling_bundle) |
| yq | ✅ EL USUARIO LA QUIERES | jq para YAML (ficheros docker-compose, k8s, terraform yaml, etc.) | ✅ (cli_tooling_bundle vía webi) |
| **d2lang** | ⚠️ Útil | Diagrams-as-code (diagramas desde texto) | ✅ (linux-devtools) |
| **terraform + tfenv** | ✅ SI USAS IaC | Herramienta de infraestructura como código | - |
| **gh-dash** | ✅ SI USAS GitHub PR | Dashboard de Pull Requests | ✅ (github tools) |
| **github-copilot-cli** | ✅ SÍ | Copilot CLI en terminal | ✅ (linux-github.sh) |
| **gh extensions** | ⚠️ VARÍAS | gh-copilot, gh-projects, gh-actions-status, gh-notify, etc. | ✅ (github tools) |
| **wslu** | ✅ SÍ (WSL) | Integración WSL ↔ Windows | ✅ (linux-desktop) |
| **gum** | ⚠️ Decorativo | UI toolkit para scripts. No es esencial pero es bonito | ✅ (cli_tooling_bundle) |
| **webi** | ⚠️ Útil para el futuro | Web install tool. Descarga tools actualizadas. Si usas webi para instalar jq/fd/rg/etc, no necesitas la versión hardcoded. | ✅ (cli_tooling_bundle) |
| **k9s** | ⚠️ SI USAS K8s | Kubernetes terminal UI | ✅ (cli_tooling_bundle vía webi) |
| **gitu** | ⚠️ OPCIONAL | Git TUI (interfaz Git en terminal) | ✅ (github tools) |
| **wtf** | ⚠️ OPCIONAL | DevOps dashboard | ✅ (github tools) |
| **jqp (noahgorstein/jqp)** | ✅ Útil | jq wrapper para scripts bash | ✅ (github tools) |
| **ijq** | ❌ NO NECESES | Alternativa ligera a jq. Con jq no lo necesitas | ✅ (cli_tooling_bundle) |

### ❌ PRIORIDAD 4: NO INSTALAR (inútiles en WSL o redundant)

| Herramienta | Por qué no |
|-------------|-----------|
| **taskfalcon** | Task runner alternativa. gotask es suficiente. No duplicar |
| **tfswitch** | Terraform version manager. tfenv ya lo gestiona |
| **git-gui/gitk/meld** | GUI tools X11/GTKque no funcionan en WSL |
| **telegram-desktop** | No es herramienta de desarrollo |
| **ffmpeg** | Solo si trabajas con audio/video |
| **bluetooth/pulseaudio** | No aplica en WSL ni para desarrollo |
| **termium** | Herramienta de Codeium. Mejor usar Copilot |
| **deployer/stitch-mcp** | MCP bootstrap (ya lo tienes configurado en mcp.json manualmente) |
| **iJq** | Alternativa ligera a jq. Con jq no lo necesitas |

### ❌ DEPRECADO EN SCRIPT: Herramientas obsoletas

| Herramienta | Problema | Versión alternativa |
|-------------|----------|-------------------|
| **Node.js 22.x (setup_22.x)** | EOL desde Abril 2027, cerca de terminarse | Cambiar a `setup_24.x` OR usar nvm |
| **Go 1.23.4** | Hardcoded. Revisar si hay versiones más nuevas | 1.24.x debería ser la última si existe |
| **ijq** | Función duplicada (ya tienes jq) | Eliminar del script |

---

## 📋 PLAN DE INSTALACIÓN PROPUESTO (orden lógico)

### 0. Verificar entorno actual
```bash
cd ~/configLinux
./run.sh doctor
```

### 1. Dotfiles y estructura de directorios
```bash
./run.sh dotfiles-links-only
```
- Crea directorios: ~/.local/bin, ~/.local/state, etc.
- Links de dotfiles (.bashrc, .vimrc, etc.)

### 2. Git config
```bash
./run.sh git-only
```
- Config de git con los archivos del repo configLinux
- Includes de alias, diff, etc.

### 3. Agent config (VS Code templates)
```bash
./run.sh agent-config-only
```
- Templates de VS Code Insiders
- Prompts para agents (code.instructions.md, etc.)

### 4. Base system
```bash
./run.sh linux-base
```

### 5. Shells (zsh + oh-my-zsh)
```bash
./run.sh linux-shells
```

### 6. Docker (CONTAINERS)
```bash
./run.sh linux-containers
```
- Instala Docker Engine en WSL2
- Configura daemon.json con socket compartido
- Verifica si Docker Desktop está en Windows primero

### 7. Devtools (Lenguajes, CLI tools, etc.) - **ESTE DEBE SE ARREGLADO PRIMERO**
```bash
./run.sh linux-devtools
```
**PROBLEMA ACTUAL DEL SCRIPT:**
- Instala Node.js 22.x via NodeSource (EOL) → **DEBERÍA usar 24.x o 20.x**
- Instala Go 1.23.4 (hardcoded) → **revisar versión actual**
- Instala todas las CLI tools (bat, rg, fd, jq, k9s, ShellCheck, etc.)
- gh extensions (gh-dash, gh-copilot, etc.)
- Terraform, tflint, tfsec, checkov
- Azure, pre-commit, ansible-lint, black

**CORRECCIÓN RECOMENDADA:**
```bash
# Arreglar Node.js en el script:
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash - \
&& sudo apt-get install -y nodejs

# o usar nvm para gestionar versiones:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash
nvm install --lts
nvm alias default 24
```

### 8. Desktop (VS Code, wslu, etc.)
```bash
./run.sh linux-desktop
```

---

## ✅ RESPUESTA A TUS PUNTOS

> **"bash-completion, zip, unzip, xclip, yq las quiero instalar"**

✅ Todas están en el script y las he añadido a Prioridad 1. Son esenciales para tu workflow.

> **"w3m no sería útil para agentes?"**

Tu pregunta es interesante. w3m es un navegador de terminal. En agentes:
- Algunos agent frameworks usan navegadores de terminal para verificar URLs
- w3m puede renderizar HTML básico en terminal
- Pero para agentes modernos, no es necesario → **es opcional, te lo dejaré**

> **"npx, docker etc también lo instalan?"**

- **docker**: 🔴 Sí, lo instala en modo `linux-containers`
- **npx**: ⚠️ npx es parte de Node.js. El script instala Node 22.x vía APT → entonces sí instala npx (pero es la versión equivocada ya que 22.x es EOL)
- **npm**: ⚠️ Lo mismo. Viene con Node.js → no es independiente

> **"Node 22 o una LTS superior... no se que la 22 o una LTS superior... cual es la LTS más antigua que sigue y hasta cuando?"**

- **v20.x**: EOL (próximo 30 Abril 2026, pero ya está en mantenimiento)
- **v22.x**: EOL (próximo 30 Abril 2027, pero ya está en mantenimiento)
- **v24.x**: **✅ LTS ACTIVA (codename Jod)** → Hasta Abril **2028**
- v26.x: Current (no LTS)

**Recomendación: Cambiar el script a Node 24.x (setup_24.x) o usar nvm para gestionar versiones automáticamente.**