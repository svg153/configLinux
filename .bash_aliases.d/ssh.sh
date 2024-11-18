alias ssh-init="__ssh-init"

# ssh-init
function __ssh-init() {
  eval $(ssh-agent -s)
  
  # get all keys in .ssh folder to add to ssh-agent
  for key in $(ls ~/.ssh/*.pub); do
    ssh-add ${key%.*}
  done
}