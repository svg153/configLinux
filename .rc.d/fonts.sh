# fonts
# https://github.com/gabrielelana/awesome-terminal-fonts
if [ -d ~/.fonts ] && [ -n "$(ls -A ~/.fonts)" ] && [ $(ls -1A ~/.fonts/ | grep -E '\.sh$' | wc -l) -gt 0 ]; then
    source ~/.fonts/*.sh
fi