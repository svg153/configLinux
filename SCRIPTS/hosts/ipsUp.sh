#!/bin/bash


FILENAME="hosts_up_now.txt"
rm $FILENAME
touch $FILENAME

# http://stackoverflow.com/questions/733418/how-can-i-write-a-linux-bash-script-that-tells-me-which-computers-are-on-in-my-l
for ip in 10.10.{16..31}.{0..255}; do  # for loop and the {} operator
    ping -c 1 -t 1 ${ip} > /dev/null 2> /dev/null  # ping and discard output
    if [ $? -eq 0 ]; then  # check the exit code
        name=$(dig +short -x ${ip})
        msg="${ip} - ${name} : up" # display the output
        #echo $msg

        # you could send this to a log file by using the >>pinglog.txt redirect
    else
        msg="${ip} : down" # display the output
        #echo $msg
    fi
    printf '%s\n' "${msg}" >> $FILENAME
done
