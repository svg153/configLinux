#!/bin/bash

WHOIAMI=$(whoami)

default_pathDir1="/home/svg153/REPOSITORIOS/android-emulator/tools/SwiftHand/src"
default_pathDir2="/home/svg153/REPOSITORIOS/android-emulator/tools/SwiftHand_OLD/src"
# @TODO: default_pathNamefileDiff by common paths of dirs --> https://www.rosettacode.org/wiki/Find_common_directory_path#UNIX_Shell
default_pathNamefileDiff="/home/svg153/REPOSITORIOS/android-emulator/tools/SwiftHand_diff.txt"
tempfile="/home/svg153/.temp.txt"

dir1=""
dir2=""
file=""


user_TOBE="svg153"
group_TOBE="svg153"
perm_TOBE=655


paterns_args=""


red_color="\e[31m"
info_color="\033[0;36m"
warn_color="\e[33m"
reset_color="\e[0m"


#
# -> FUNCTIONS
#

msg(){
    color=$reset_color
    case $1 in
        e|error) color=$error_color ;;
        w|warn) color=$warn_color ;;
        i|info) color=$info_color ;;
        *) color=$reset_color ;;
    esac
    echo -e "${color}""$2""${reset_color}"
}

print_usage() {
    echo "USAGE: $0 dir1 dir2 [fileToDiffStdout]"
    echo
    echo "OPTIONS:"
    echo " -h,--help                print this message and exit"
    echo
    echo "EXAMPLE:"
    echo "  · $ $0 /path/dir1 /path/dir2 /path/fileToDiffStdout"
    echo
    echo "TIPS:"
    echo "  · $ export diffDirsPathDir1=\"/path/dir1\""
    echo "  · $ export diffDirsPathDir2=\"/path/dir2\""
    echo "  · $ export diffDirsPathFile=\"/path/fileToDiffStdout\""
}

# Check if actual user is root
check_root_user() {

    TOBE="root"

    if [ "$WHOIAMI" != "$TOBE" ] ; then
        echo "You are '$WHOIAMI', but you should be '$TOBE'."
        echo "Please, switch to '$TOBE' user and relauch the script."
        exit 1
    fi
}


check_args() {

    if [ "$diffDirsPathDir1" = "" ] && [ $# -lt 1 ] ; then
        #read -r -p "dir1? " -s dir1
        printf "dir1? "
        read dir1
        echo
    else
        if [ "$diffDirsPathDir1" != "" ] ; then
            dir1=$diffDirsPathDir1
        else
            dir1=$1
        fi
    fi

    if [ "$diffDirsPathDir2" = "" ] && [ $# -lt 2 ] ; then
        printf "dir2? "
        read dir2
        echo
    else
        if [ "$diffDirsPathDir2" != "" ] ; then
            dir2=$diffDirsPathDir2
        else
            dir2=$2
        fi
    fi

    if [ "$diffDirsPathFile" = "" ] && [ $# -lt 3 ] ; then
        printf "file? "
        read file
        echo
    else
        if [ "$diffDirsPathFile" != "" ] ; then
            file=$diffDirsPathFile
        else
            file=$3
        fi
    fi

    # Check if dirs1 exist
    if [ ! -d "$dir1" ] ; then
        echo "dir1: $dir1 not exist. Please check it and relaunch."
        exit 1
    fi
    # Check if dirs2 exist
    if [ ! -d "$dir2" ] ; then
        echo "dir2: $dir2 not exist. Please check it and relaunch."
        exit 1
    fi

    # Check if file exist
    if [ -f "$file" ] ; then
        mv $file "${file}_OLD"
    fi
    touch $file

}


# Change perms.
change_perms() {

#    user_file="${ls -ld $file | awk '{print $3}'}" # NOT WORK
    user_file="$(stat -c '%U' $file)"
    group_file="$(stat -c '%G' $file)"
    perm_file="$(stat -c '%a' $file)"

     # Check if file exist
    if [ "$user_TOBE" != "$user_file" ] ; then
        chown $user_TOBE $file
    fi

    if [ "$group_TOBE" != "$group_file" ] ; then
        chgrp $group_TOBE $file
    fi

    if [ "$perm_TOBE" -ne "$perm_file" ] ; then
        chmod $perm_TOBE $file
    fi

}

make_export() {

    if [[ $# -eq 0 ]] ; then
        export diffDirsPathDir1="$default_pathDir1"
        export diffDirsPathDir2="$default_pathDir2"
        export diffDirsPathFile="$default_pathNamefileDiff"
    else
        export diffDirsPathDir1="$1"
        export diffDirsPathDir2="$2"
        export diffDirsPathFile="$3"
    fi

}

make_diff() {

    # TODO: check if WHOIAMI have perms in dir1 and dir2, owner or in group. And if not have perms, request root pass
    check_root_user

    check_args "$@"

    diff -qr $dir1 $dir2 > $file

    #change_perms
    msg "i" "See '$file' to check the diffs between '$dir1' and '$dir2'.": echo; echo

    touch $tempfile
    chmod 777 $tempfile

}



concat_parterns() {

    for i in $@ ; do
        paterns_args="$paterns_args $i"
    done
}

# filter diff
filter_diff_output() {


    concat_parterns "~" ".git" ".svn" ".tgz" ".tar.gz" ".rpm"
    concat_parterns ".o" ".bin" ".class" ".jar" ".pyc"

    paterns=($paterns_args)

    for i in "${paterns[@]}" ; do
        grep -v "$i" $file > $tempfile && mv $tempfile $file
    done
}

make_diff_file() {

    # for para cada linea que mache con File al comienzo coger la columna 2 y 4 y hacer el diff
    while read line ; do
        # print the title of file to diff
        printf "%s\n%s\n" "$line" $(printf "%s\n" "$line" | sed "s/./>/g") >> $tempfile

        # Check if there ara diff or is only in one of them
        if [[ $line == *"File"* ]] ; then
            # sacar las columnas
            mine="$(echo $line | awk '{print $2}')"
    #        mine="$(echo "uno dos tres cuatro" | awk '{print $2}')" && repo="$(echo "uno dos tres cuatro" | awk '{print $4}')" && echo "$mine" && echo "$repo"
            repo="$(echo $line | awk '{print $4}')"

            # escribir las diffs
            diff -y --suppress-common-lines $mine $repo >> $tempfile
        fi

        # add separator
        printf "%s\n\n\n" $(printf "%s\n" "$line" | sed "s/./</g") >> $tempfile

    done < $file


    # copiar todo el fichero temporal al fichero de salida
    mv $tempfile $file

}

main_normal() {
    make_export $2 $3 $4
    make_diff
    exit 0
}

main() {

    if [[ $# -gt 2 ]] ; then
        print_usage
        exit 1
    fi

    TEMP=$(getopt -o hen --long help,export,normal -- "$@")
    if [[ $? -ne 0 ]] ; then
        exit 2
    fi
    eval set -- "$TEMP"
    while true ; do
        echo $1
        case $1 in
            -e|--export)
                make_export
                make_diff
                filter_diff_output
                make_diff_file
                cat $file
                msg "i" "See '$file' to check the diffs between '$dir1' and '$dir2'."
                change_perms
                break ;;
            -n|--normal ) main_normal $2 $3 $4; exit 0 ;;
            -h|--help ) print_usage; exit 0 ;;
            --) main_normal $2 $3 $4; exit 0 ;;
            *) print_usage;  exit 1 ;;

        esac
    done

}




#
# <- FUNCTIONS
#

main "$@"
