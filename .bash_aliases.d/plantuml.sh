export PLANTUML_BIN="${HOME}/bin/plantuml/plantuml.jar"

# https://github.com/oversizedhat/plantuml-watcher
alias plantuml-watcher='docker run --rm -ti -v ${PWD}:/ws -w /ws oscarberg/plantuml-watcher --draw-on-add --recursive'
