#!/bin/bash
################################################################################
# PURPOSE: 
# Script to rewrite shape models from obj format to ver standard.
# 
# AUTHOR:
#  clement<dot>feller<at>obspm<dot>fr
#
# CHANGELOG:
#     APR-2015: first light
#     Oct-2015: rewrite; now deals with shape models written in meters
#  23-Feb-2017: Cleaning, writing doc to new standard, adding remarks
#
# I/O:
# I: (as argument) the name of the obj file.
# O:  shape model file in ver format standard.
#
# NB: 1 reported cases of string from file name rewriting a number for shape4s
#     spg-v10 shape model. Check corresponding obj file for manual correction.
#     Haven't managed to replicate error. 23-Feb-2017 CF
#
# FYI: the vertices position in the given obj shape model file should be in km,
#      it is not a problem if french notation is used instead of US/UK notation
#      (i.e. "," instead of "."; cf gsub call in awk)
################################################################################

filename=$1;
Nlines=$(wc -l ${filename} | awk -F' ' '{print $1}');
counter=0;
comment=0;

# add existence test if same file exist rewrite y/n
Vertices=$(grep -a Vertices ${filename} | awk '{print $3}');
Faces=$(grep -a Faces ${filename} | awk '{print $3}');
echo "   ${Vertices}   ${Faces}" > ${filename%.obj}.ver;


awk '{ if ($1~"v"){gsub(",","."); 
       if ($2 >= 1000.0 || $3 >= 1000.0 || $4 >= 1000.0 || $2 <= -1000.0 || $3 <= -1000.0 || $4 <= -1000.0){
       printf("%.9f %.9f %.9f\n", $2/1000.0, $3/1000.0, $4/1000.0)
                           } 
       else {printf("%.9f %.9f %.9f\n", $2, $3, $4)}
                  };
       if ($1~"f"){gsub("f","3\n");print $0};
	}' < ${filename} >> ${filename%.obj}.ver;

# add statistics 
echo "Converting "${filename}" to "${filename%.obj}.ver" has been achieved.";
#END
