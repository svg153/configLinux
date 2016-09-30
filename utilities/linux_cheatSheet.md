linux_cheatSheet.md
===================

The current path
```shell
here="$(dirname "$(readlink -f "$0")")"
```

Cat all files in a directory but not for subfolders
```shell
find | xargs cat > find.txt
```

Cat all files in a directory but not for subfolders
```shell
find | xargs cat > find.txt
```

Redirect standard output to a file and to stdout at the same time
```shell
<command> | tee  ps.txt
```

Scripts options
```shell
TEMP=$(getopt -o o:h --long option:,help -- "$@")
if [ $? != 0 ] ; then
    return
fi
eval set -- "$TEMP"
while true ; do
    case $1 in
        -o|--option) print_usage ; exit 0 ;;
        -h|--help ) print_usage ; exit 0 ;;
        --) shift ;  break ;;
        *) print_usage;  exit 1 ;;
    esac
done
```

Create temporal file
```shell
create_tmp_file() {
    pathtempfile=$(mktemp)
    trap "rm $pathtempfile" EXIT
    cat > "$pathtempfile" <<- EOF
	Hello World!
	EOF
}
```

# Special commands
```shell
# https://github.com/kperusko/cheatsheet/blob/master/linux.txt
$? (reads the exit status of the last command executed. After a function returns, $? gives the exit status of the last command executed in the function)
$$ (current process PID)
$! (PID of the last backgrounded process)
$1 (1st command line argument)
$n (n-th command line argument)
$0 (name by which the script has been invoked)
$# (number of arguments supplied, without $0)
$* (all arguments at once, but without $0)
!! (repeat last command - useful combo - sudo !!)
!$ (last argument of the previous command)
!:n (n-th argument of the previous command)
!n (execute n-th line in history)
!-5 (execute current -5 line in history)
!foo (execute the last foo command in history)
```

Bash colors output
```shell
#!/bin/bash

msg(){
    # http://misc.flogisoft.com/bash/tip_colors_and_formatting
    error_color="\e[31m"
    info_color="\033[0;36m"
    warn_color="\e[33m"
    reset_color="\e[0m"

    color=$reset_color
    case $1 in
        e|error) color=$error_color ;;
        w|warn) color=$warn_color ;;
        i|info) color=$info_color ;;
        *) color=$reset_color ;;
    esac
    echo -e "${color}""$2""${reset_color}"
}

msg "e" "Hello"
msg "w" "Hello"
msg "i" "Hello"
msg "Hello"
```

Mount points and space
```shell
df -h
```

Diff between dir1 and dir2 printing only files names
```shell
diff -qr $dir1 $dir2
```

32 or 64 bits
```shell
# x86_64 -> 64 bit
# i686 -> 32 bit
uname -m

# for more info
# uname -a
```

Find all symlinks in a directory tree and subfolders
```shell
ls -lR ~/ | grep ^l
```




# Script bash base
```shell
#!/bin/bash

VERSION=
HERE="$(dirname "$(readlink -f "$0")")"
NAME=$0


# ---> VARS to change
# ...
# <--- VARS to change

# ---> VARS
# ...
# <--- VARS

#
# ---> AUX FUNCTIONS
#

die() {
    echo >&2 "$@"
    exit 1
}

print_usage() {
    echo "Usage: $NAME [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo " -o, --option='<msgToPrint>'                     Echo msgToPrint"
    echo " -h, --help                                         print this message and exit"
    echo
    echo "EXAMPLE:"
    echo "  -o, --option"
    echo "    $ $NAME -o'hello"
    echo "    $ $NAME --option='hello'"
}

msg(){
    # http://misc.flogisoft.com/bash/tip_colors_and_formatting
    error_color="\e[31m"
    info_color="\033[0;36m"
    warn_color="\e[33m"
    reset_color="\e[0m"

    color=$reset_color
    case $1 in
        e|error) color=$error_color ;;
        w|warn) color=$warn_color ;;
        i|info) color=$info_color ;;
        *) color=$reset_color ;;
    esac
    echo -e "${color}""$2""${reset_color}"
}


#
# <--- AUX FUNCTIONS
#


# main function
main() {
    TEMP=$(getopt -o o:h --long option:,help -- "$@")
    if [ $? != 0 ] ; then
        return
    fi
    eval set -- "$TEMP"
    while true ; do
        case $1 in
            -o|--option) echo $2 ; shift 2 ; exit 0 ;;
            -h|--help ) print_usage ; exit 0 ;;
            --) shift ;  break ;;
            *) print_usage;  exit 1 ;;
        esac
    done
}


#
# -> MAIN
#

main "$@"

#
# <- MAIN
#

```
