#!/usr/bin/env bash

function install_azurecli()
{
    if [[ -x "$(command -v az)" ]]; then
        az --version
        return 0
    fi

    local os_distribution=$(get_os_distribution)
    if [ "$os_distribution" == "Debian" ] || [ "$os_distribution" == "Ubuntu" ]; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    else
        curl -L https://aka.ms/InstallAzureCli | bash
    fi
}

function install_azurecli_extentions()
{
    local -r extensions=(
        "azure-devops"
    )

    if [[ -x "$(command -v az)" ]]; then
        for ext in "${extensions[@]}"; do
            az extension add --name ${ext}
        done
    else
        log warn "install_azurecli_extentions: az is not installed"
    fi
}

function install_tfenv()
{
    if [[ -x "$(command -v tfenv)" ]]; then
        tfenv -v
    else
        git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
        mkdir -p ~/.local/bin/
        ln -s ~/.tfenv/bin/* ~/.local/bin
        which tfenv
        tfenv -v
    fi
}

function install_terraform_with_tfenv()
{
    if [[ -x "$(command -v terraform)" ]]; then
        terraform -version
        return 0
    else
        install_tfenv
    fi

    tfenv install latest

    if [[ ! -x "$(command -v terraform)" ]]; then
        tfenv use latest
    fi
}

function install_terraform()
{
    if [[ -x "$(command -v terraform)" ]]; then
        terraform -version
        return 0
    fi

    sudo apt-get update \
    && sudo apt-get install -y gnupg software-properties-common

    [[ -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]] && sudo rm /usr/share/keyrings/hashicorp-archive-keyring.gpg
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && gpg --no-default-keyring \
        --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        --fingerprint

    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update \
    && sudo apt-get install terraform \
    && terraform -help \
    && terraform -help plan \

    stdout=$(terraform -install-autocomplete | grep "already installed" | wc -l)
    ret=$?
    if [[ ${ret} -ne 0 ]] && [[ ${stdout} -gt 0 ]]; then
        echo "Terraform autocomplete is already installed"
    fi
}

function install_terraform_tools()
{
    if [[ -x "$(command -v tflint)" ]]; then
        tflint -v
    else
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    fi

    if [[ -x "$(command -v tfswitch)" ]]; then
        tfswitch -v
    else
        curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh | bash
    fi

    if [[ -x "$(command -v tfsec)" ]]; then
        tfsec -v
    else
        go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
    fi

    if [[ -x "$(command -v checkov)" ]]; then
        checkov -v
    else
        pipx install checkov
    fi

    if [[ -x "$(command -v tfautomv)" ]]; then
        tfautomv -v
    else
        curl -sSfL https://raw.githubusercontent.com/busser/tfautomv/main/install.sh | sudo sh
    fi
}

function install_cloud_tooling_bundle()
{
    install_azurecli
    install_azurecli_extentions
}

function install_iac_tooling_bundle()
{
    install_tfenv
    install_terraform_with_tfenv
    install_terraform_tools
}