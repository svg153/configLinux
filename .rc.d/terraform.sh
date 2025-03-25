# tfenv
export PATH="$HOME/.tfenv/bin:$PATH"

complete -C $HOME/.tfenv/versions/1.11.2/terraform terraform
# TODO: check if change the tfversion if change the tfenv version, complete -C $HOME/.tfenv/versions/$(terraform version | cut -d'v' -f2 | head -n1)/terraform terraform