# ConfigLinux - Pre-configuración para ejecución

## 🔑 PASO 1: Rellenar tus emails reales

Antes de lanzar el script, DEBES crear estos archivos con tus datos reales:

### 1. Email PERSONAL (para repos personales)
```bash
# Crear /home/svg153/configLinux/.gitconfig.d/personal-mail.gitconfig

[user]
    name = Sergio Valverde
    email = sergio@gmail.com  ← CAMBIAR por tu email real
```

### 2. Email TRABAJO (para repos de empresa/organización)
```bash
# Crear /home/svg153/configLinux/.gitconfig.d/work/work.gitconfig

[include]
    path = ../alias.gitconfig
[include]
    path = ../gh.gitconfig
[include]
    path = ../diff.gitconfig

[user]
    name = Sergio
    email = sergio.valverde@empresa.com  ← CAMBIAR por tu email corporativo
[github]
    user = svg153
[includeIf]
    gitdir:~/REPOSITORIOS/1_WORK/
        path = work/work.gitconfig
```

---

## 📁 PASO 2: Rutas que se crearán automáticamente

El script creará esta estructura:

```
~/PROGRAMAS/              → Programas instalados
~/REPOSITORIOS/           → Repositorios clonados
  ├── 0_PERSONAL/         → Repos personales (email personal)
  └── 1_WORK/             → Repos trabajo (email trabajo)
~/.config/                → Configuración (symlink a configLinux/.config)
~/.aliases                → Alias de shell (symlink)
~/.bashrc                 → Shell (symlink)
~/.linux-prompt           → Prompt (symlink)
~/.bash_aliases           → Alias bash (symlink)
~/.bash_completion        → Auto-completes (symlink)
~/.rc                     → RC files (symlink)
~/.profile                → Profile (symlink)
~/SCRIPTS/                → Scripts (symlink)
~/.env.paths.env          → Variables de entorno (symlink)
~/.fonts/                 → Fuentes custom
~/.icons/                 → Iconos custom
```

---

## 🔗 ENLACES SIMBÓLICOS QUE CREA el script

```bash
configLinux/.include_d         → ~/.include_d
configLinux/.aliases           → ~/.aliases
configLinux/.bashrc            → ~/.bashrc
configLinux/.bash_prompt       → ~/.bash_prompt
configLinux/.bash_aliases      → ~/.bash_aliases
configLinux/.bash_aliases.d    → ~/.bash_aliases.d
configLinux/.bash_completion   → ~/.bash_completion
configLinux/.bash_completion.d → ~/.bash_completion.d
configLinux/.rc                → ~/.rc
configLinux/.rc.d              → ~/.rc.d
configLinux/.profile           → ~/.profile
configLinux/SCRIPTS/           → ~/SCRIPTS
configLinux/.env.paths.env     → ~/.env.paths.env
configLinux/.config            → ~/.config
```

---

## 📝 FICHEROS DE CONFIGURACIÓN GIT POR CARGO

El script carga por defecto en .gitconfig:
- `.gitconfig.d/default.gitconfig` → Incluye por defecto personal-mail.gitconfig
- `.gitconfig.d/alias.gitconfig` → Alias de git
- `.gitconfig.d/diff.gitconfig` → Diffs custom
- `.gitconfig.d/gh.gitconfig` → GitHub CLI integration
- `.gitconfig.d/work/work.gitconfig` → Config específica de trabajo (email corporativo)

**La lógica es:**
- Repos en `~/REPOSITORIOS/0_PERSONAL/**` → Usa email personal
- Repos en `~/REPOSITORIOS/1_WORK/**` → Usa email de empresa (automáticamente por includeIf)

---

## ✅ PRE-CHECKS ANTES DE EJECUTAR

Antes de `./run.sh`, verifica que:
- [ ] `personal-mail.gitconfig` existe con tu email personal
- [ ] `work/work.gitconfig` existe con tu email de trabajo (o créalo, solo es placeholder)
- [ ] Tu user tiene permisos sudo (ya lo tiene, ya te pide sudo)
- [ ] Git instalado (ya lo tiene)

Ejecuta:
```bash
ls .gitconfig.d/personal-mail.gitconfig  # Debe existir
cat .gitconfig.d/personal-mail.gitconfig # Ver email correcto
```

---

## 🚀 ORDEN DE EJECUCIÓN SUGERIDA

```bash
# 0. Pre-config (si quieres hacerlo manual)
#   Crear personal-mail.gitconfig y work/work.gitconfig primero

# 1. Solo Git + templates (rápido, sin tocar el sistema)
./run.sh shared-config-only

# 2. Base: crea carpetas, enlaza configs, instala git/vim/bash
./run.sh linux-base

# 3. Shells: zsh + oh-my-zsh
./run.sh linux-shells

# 4. Devtools: lenguajes, CLI tools, git, docker
./run.sh linux-devtools

# 5. Docker/Containers
./run.sh linux-containers
```

O ejecuta TODAS las etapas con el bootstrap completo (requiere confirmación explícita):
```bash
./run.sh desktop --yes
```