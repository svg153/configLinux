#!/bin/bash

rm b_N.txt; touch b_N.txt
rm b_2.txt
rm temp.txt; touch temp.txt
sort b.txt | uniq >> temp.txt # cuidado qeu puede haber duplciadas por culpa del [Accessed: 01-Nov-2016].
awk '{printf "%s%d%s - %s\n", "[R", NR, "]", $0}' < temp.txt >> b_N.txt
# cut -c 9- b_N.txt > b_2.txt # sale con caracteres mal

