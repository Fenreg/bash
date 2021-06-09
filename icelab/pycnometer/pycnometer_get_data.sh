#==============================================================================
#d NAME: pycnometer_get_data.sh
#d AUTHOR: Clément Feller (cxlfeller--at--gmx<dot>com)
#d PURPOSE: (short descr)
#d CHANGELOG: 2020-05-26 v1.0 first light
#d I/O:
#d <- (input)
#d -> (output)
#d
#d USAGE: (example)
#d COMMENTS: (give it a blue thumb)
#d DEPENDANCIES: (compiler version, version of functions used)
#d NOTES: None
#d COPYRIGHT: CC-BY-NC-ND
#==============================================================================
nlines=$(wc -l "$1" | cut -d' ' -f1)
output="${1/\.txt/_cleaned\.dat}"

# get volume
echo "# Volume" > $output
awk -v var="$nlines" '{ORS="\t"; 
   {if (FNR == 5) print substr($5,1,length($5)-1),$2,$3,$4}; 
   {if (FNR == 10) print $2};
   {if (FNR >= 36 && FNR < var-1) print $2};
   ORS="\n";
   {if (FNR == var-1) print $2}; 
                      }' "$1" | sed 's///g' >> $output

# get density
echo "# Density" >> $output
awk -v var="$nlines" '{ORS="\t";
   {if (FNR == 5) print substr($5,1,length($5)-1),$2,$3,$4}; 
   {if (FNR == 10) print $2};
   {if (FNR >= 36 && FNR < var-1) print $3};
   ORS="\n";
   {if (FNR == var-1) print $3}; 
                      }' "$1" | sed 's///g' >> $output
   
