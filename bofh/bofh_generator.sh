#!/bin/bash
###############################################################################
# NAME : bofh_generator
# PURPOSE : generate excuses randomly from a list
# I/O : -> none
#       <- text
# CHANGELOG: 04-MAR-2019: v1.0 new version from B.O.
# COMMENTS: Created by Ben Okopnik on Mon Apr  1 04:12:39 EST 2002
#           cat << !
#           === The BOFH-style Excuse Server --- Feel The Power!
#           === By Jeff Ballard <ballard@cs.wisc.edu>
#           === See http://www.cs.wisc.edu/~ballard/bofh/ for more info.
#           !
# Dependances: none but excuses files
###############################################################################
 path="$HOME/librairies/bash/cfeller/bofh/excuses.lst"
 if [ ! -e "${path}" ]; then \
    echo -e "bofh file not found. Exiting.\n"; 
    exit 0; 
 fi;
 line=$(($RANDOM%`grep -c '$' ${path}`))
 cat -n ${path}|while read a b
 do
     [ "$a" = "$line" ] && \
     { echo -e "\nYour excuse for this session is:\n\t$b\n"; break; }
 done


#### --- old version --- ####
##NombreDeLignes=465 # wc -l bofh/bofh.txt | cut -c 1-3
##RandFunc=`date +%N| sed s/...$//`
##NombreAleatoire=`dc -e " ${RandFunc} ${NombreDeLignes} % d 1 + p"`
##
##echo -e "\t\t\t\t\t ERRORS OBTAINED WITH THIS BASH SESSION ARE RELATED TO.........\n"
##sed -n "${NombreAleatoire}p" /home/user-777/libraries/bash/BOFH/bofh.txt
##echo " "
#### --- old version --- ####