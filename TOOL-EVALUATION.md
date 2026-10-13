# Evaluación de Herramientas - configLinux

## ESTATUS DEL SISTEMA
| Herramienta | Estado |
|-------------|--------|
| git | ✅ INSTALADA |
| curl | ✅ INSTALADA |
| vim | ✅ INSTALADA |
| python3 | ✅ INSTALADA |
| gh | ✅ INSTALADA |
| lshw | ✅ INSTALADA |

**Todo lo demás → NO INSTALADO** (40+ herramientas pendientes)

---

## 🏆 EVALUACIÓN POR CATEGORÍA

### SYSTEM / BASICS
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| bash-completion | ✅ SÍ | Auto-complete de comandos. Esencial si usas mucho terminal |
| zip/unzip/xclip | ✅ SÍ | Utilidades básicas. xclip es clave para copiar/pedar con pipe (`echo "text" | xclip`) |

### LENGUAJES / RUNTIMES
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| python3/pip/pipx | ⚠️ VERIFICAR | python3 ya instalada. Faltan pip y pipx. pipx es esencial para instalar CLI tools python sin sudo |
| nodejs/node 22.x | ✅ SÍ | Necesario para npm, npx, Copilot CLI, muchas herramientas de dev |
| go/golang 1.23.4 | ⚠️ OPcional | Si no usas Go ni herramientas que requieren Go, probablemente no la necesites |
| d2lang (d2) | ✅ SÍ | Diagrams-as-code. Genera diagramas desde texto. Útil para documentación técnica |

### SHELL / UX
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| w3m | ❌ NO | Browser terminal. No lo usa nadie hoy en día. Mejor usa un browser real |
| gum | ⚠️ OPcional | UI toolkit de charm.sh para scripts. Útil si creas scripts interactivos pero no esencial |
| ijq | ❌ NO | Alternativa ligera a jq. Si instalas jq (que sí), no lo necesitas |
| starship | ✅ SÍ | Prompt moderno. Mucho más bonito que fzf. Recomendado |
| fzf | ✅ SÍ | Fuzzy finder. Esencial. Permite Ctrl+R para history search, etc. |
| gotask (task) | ✅ SÍ | Task runner. Mejor que Makefile. Estándar en muchos proyectos modernos |
| taskfalcon | ❌ NO | Task runner alternativa a gotask. Con gotask/Task no lo necesitas |
| webi | ⚠️ OPcional | Web Install tool. Descarga herramientas por línea. Buena si quieres mantener actualizadas las tools |

### CLI TOOLS (webi)
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| bat | ✅ SÍ | Cat con syntax highlighting. Súper útil para ver código/logs en terminal |
| rg (ripgrep) | ✅ SÍ | grep moderno. 10x más rápido que grep. ESSENTIAL si haces开发 |
| fd (fd-find) | ✅ SÍ | Find moderno. 10x más rápido. Alternativa a find con mejores defaults |
| jq | ✅ SÍ | Procesar JSON. ESSENTIAL para APIs, CLI tools, etc. |
| yq (yq-go) | ✅ SÍ | jq para YAML. ESSENTIAL. Usas Terraform, Docker yaml configs, etc. |
| k9s | ✅ SÍ | Terminal UI para Kubernetes. ESSENTIAL si trabajas con K8s. NO lo necesitas si no tocas K8s |
| ShellCheck | ✅ SÍ | Linter para bash scripts. ESSENTIAL si escribes scripts |
| shfmt | ✅ SÍ | Format de shell scripts. Complemento de ShellCheck |

### GITHUB / DEVOPS
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| gh (extensions) | ⚠️ VARÍAS | |
| gh-copilot | ✅ SÍ | Copilot en terminal para code review |
| gh-projects | ⚠️ OPCIONAL | GitHub Projects desde CLI |
| gh-dash | ✅ SÍ | Dashboard de PRs. ESSENTIAL si haces mucho PR review |
| gh-actions-status | ⚠️ OPCIONAL | Ver status de workflows de GitHub Actions |
| gh-notify | ⚠️ OPCIONAL | Notificaciones de GitHub en terminal |
| gh-poi | ❌ NO | Revisar si aún activo. Menos útil que gh-dash |
| gh-clone-org | ✅ SÍ | Clonar organizacion completa. Útil si haces migraciones/backup |

### CLASIFICACIÓN FINAL DE GH EXTENSIONS
| Extensión | Prioridad |
|-----------|-----------|
| gh-copilot | 🔴 ALTA |
| gh-dash | 🔴 ALTA |
| gh-projects | 🟡 MEDIA |
| gh-actions-status | 🟡 MEDIA |
| gh-notify | 🟢 BAJA |
| gh-poi | 🔴 NO (reemplazar por gh-dash) |
| gh-install | 🟡 MEDIA |
| gh-clone-org-matt | 🟡 MEDIA |

### CI/CD / TOOLING
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|----------|
| wtf (wtfutil) | ✅ SÍ | Dashboard de devops. Monitor de todo. Útil tenerlo |
| noahgorstein/jqp | ✅ SÍ | jq wrapper para scripts bash. Muy útil |
| altsem/gitu | ✅ SÍ | Git TUI. Interfaz tipo git-gui pero en terminal. ESSENTIAL si no usas git-gui |

### CLOUD / IaC
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| azure-cli | ✅ SÍ | Si trabajes con Azure. Si no → ❌ NO |
| azure-devops | ⚠️ OPCIONAL | Solo si usas Azure DevOps (no Azure Cloud) |
| tfenv | ✅ SÍ | Terraform version manager. ESSENTIAL para tf management |
| terraform | ✅ SÍ | ESSENTIAL para IaC |
| tflint | ✅ SÍ | Linter de Terraform. ESSENTIAL |
| tfswitch | ❌ NO | Terraform version manager alternativo. tfenv ya existe |
| tfsec | ✅ SÍ | Security scanner de Terraform. ESSENTIAL para IaC security |
| checkov | ✅ SÍ | Security scanner de IaC multi-tool. ESSENTIAL |
| tfautomv | ✅ SÍ | Auto-move de recursos Terraform. Útil para refactoring |

### PYTHON TOOLS
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| pre-commit | ✅ SÍ | Git hooks. ESSENTIAL para code quality |
| ansible-lint | ✅ SÍ | Linter de Ansible. Si usas Ansible → ESSENTIAL |
| black | ✅ SÍ | Formateador de Python. ESSENTIAL si trabajas con Python |

### DESKTOP / WSL
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| wslu | ✅ SÍ | Herramientas WSL. ESSENTIAL para WSL ↔ Windows integration |
| git-gui/gitk | ❌ NO | No aplica en WSL (es X11/GTK) |
| meld | ❌ NO | No aplica en WSL |
| openvpn | ❌ NO | Solo si necesitas VPN |
| telegram-desktop | ❌ NO | No es necesario para desarrollo |

### DEVTOOLS ESPECIALIZADOS
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| ffmpeg | ⚠️ OPCIONAL | Si trabajas con audio/video → SÍ. Si no → NO |
| bluetooth/pulseaudio | ❌ NO | No aplica en WSL ni es necesario para desarrollo |

### AI / AGENT STACK
| Herramienta | ¿Instalar? | Por qué |
|-------------|------------|---------|
| go-task/github-copilot-cli | ✅ SÍ | Copilot CLI en terminal. ESSENTIAL si usas Copilot |
| install_ai_skills | ✅ SÍ | Instala skills de Copilot. ESSENTIAL para agent workflow |
| install_stitch_mcp_bootstrap | ⚠️ OPCIONAL | MCP bootstrap. Útil si usas Model Context Protocol |
| termium | ❌ NO | Tool de Codeium. Mejor usar Copilot |

---

## 📊 RESUMEN FINAL

### 🔴 ESSENTIAL (instalar sí o sí)
1. python3/pip/pipx (pipx faltaría verificar)
2. nodejs/node 22.x
3. fzf
4. starship (prompt)
5. jq
6. ripgrep (rg)
7. fd-find
8. bat
9. task (gotask/taskf)
10. terraform + tfenv
11. gh-dash
12. gh-copilot
13. pre-commit
14. checkov
15. tflint
16. shfmt
17. ShellCheck
18. shellcheck
19. ansible-lint (si usas Ansible)
20. black (si usas Python)

### 🟡 RECOMENDADO (buena idea pero no obligatorio)
- yq (yq-go)
- k9s (si K8s)
- d2lang
- wtf
- gitu
- go-task
- azure-cli
- tfsec
- gh-projects
- jqp (noahgorstein/jqp)
- bash-completion
- zip/unzip/xclip
- webi
- gh-actions-status
- gh-notify
- go-task/github-copilot-cli
- install_ai_skills

### 🚫 NO RECOMENDADO (no lo instales)
- w3m
- ijq (ya tienes jq)
- taskfalcon (ya tienes gotask/taskf)
- tfswitch (ya tienes tfenv)
- git-gui/gitk/meld (no aplica WSL)
- telegram-desktop
- ffmpeg (salvo que trabajes con audio/video)
- bluetooth tools
- gum (opcional si quieres más polish)
- termium (mejor usar Copilot)