#!/usr/bin/env bash

AGENT_SKILL_REPOSITORIES=(
    "vercel-labs/agent-skills"
    "anthropics/skills"
    "vercel-labs/agent-browser"
    "softaworks/agent-toolkit"
)

function install_termium()
{
    if [[ -x "$(command -v termium)" ]]; then
        termium --help
        return 0
    fi

    curl -L https://github.com/Exafunction/codeium/releases/download/termium-v0.2.0/install.sh | bash
    log warn "termium installed; run 'termium auth' manually when you want to connect your account."
}

function install_ai_skills()
{
    [[ -x "$(command -v npx)" ]] || install_node

    for skill in "${AGENT_SKILL_REPOSITORIES[@]}"; do
        npx skills https://github.com/${skill} --global --yes
    done
}

function install_stitch_mcp_bootstrap()
{
    [[ -x "$(command -v npx)" ]] || install_node

    local state_dir="${HOME}/.local/state/configLinux"
    local state_file="${state_dir}/stitch-mcp.init.done"
    mkdir -p "${state_dir}"

    if [[ -f "${state_file}" ]]; then
        log info "stitch-mcp bootstrap already marked as initialized"
        return 0
    fi

    if npx @_davideast/stitch-mcp init; then
        touch "${state_file}"
        log info "stitch-mcp init completed"
    else
        log warn "stitch-mcp init failed or requires manual follow-up"
        return 1
    fi
}

function install_vscode_agent_templates_linux()
{
    local vscode_user_path="${VSCODE_INSIDERS_USER_PATH:-${HOME}/.config/Code - Insiders/User}"
    local prompts_dir="${vscode_user_path}/prompts"
    local repo_templates="${CONFIG_PATH}/templates/vscode"

    mkdir -p "${prompts_dir}"
    copy_if_missing "${repo_templates}/mcp.jsonc" "${vscode_user_path}/mcp.json"
    copy_if_missing "${repo_templates}/prompts/code.instructions.md" "${prompts_dir}/code.instructions.md"
    copy_if_missing "${repo_templates}/prompts/pr-fix.prompt.md" "${prompts_dir}/pr-fix.prompt.md"
    copy_if_missing "${repo_templates}/prompts/test-agent.agent.md" "${prompts_dir}/test-agent.agent.md"
    copy_if_missing "${repo_templates}/prompts/to-pr.prompt.md" "${prompts_dir}/to-pr.prompt.md"
}

function bootstrap_agent_stack_linux()
{
    install_vscode_agent_templates_linux
    install_ai_skills
    install_stitch_mcp_bootstrap || true
}