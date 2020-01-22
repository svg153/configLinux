

# others
ic_docker() {
  opts=$@
  cd ~/REPOSITORIOS/imdea-controls-cli_gitlab/
  make OPTS="$opts"
  cd - > /dev/null
}
alias ic="ic_docker"