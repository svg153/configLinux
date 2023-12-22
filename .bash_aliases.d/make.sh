# Make
__make() {
    if [ -f "Makefile" ]; then
        make $@
    elif [ -f "Taskfile" ] || [ -f "Taskfile.yml" ] || [ -f "Taskfile.yaml" ]; then
        task $@
    else
        make $@
    fi
}

# Make
alias m="__make"
alias mb="m build"
alias mr="m run"
alias mrl="m release"
alias mc="m clean"

# earthly
# https://github.com/earthly/earthly
alias e="earthly"
alias eb="earthly +build"
alias ed="earthly +docker"
