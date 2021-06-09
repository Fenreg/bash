#!/bin/bash
 echo "OASIS_Schedule_Creator V.1 - C.Feller (LESIA: cfeller@obspm.fr)."
# CHANGELOG
#  2015-08-25: v0.9      Conformation with OASIS' CCD reference convention/OutputFileName default setting modification
#  2015-08-26: v1        Conformation with OASIS' TIME ":" writing convention, FILTER uppercase convention
#  2015-09-02: v1.01     1/ Creation of operations log; 2/ Defaulting image parameters when pre-pixels or post-pixels flags are raised.
#  2015-09-08: v1.02     1/ Substitution of reference to line variable in Scheduler fonction by first input variable of Scheduler fonction;
#                        2/ Adding quotes for that variable in case filepath reference (ie ${line}) contains whitespaces; 3/ Modification of 
#                        Notifier fonction: adding second input variable (ie ${line}); 4/ Adding existence check to OutputFilename 
#  2015-09-11: v1.03     1/ Debug with the X/Ysize not being outputted->moving them in the pre/postpixel paragraph.
#  2015-10-16: v1.04	1/ Simplification du programme, utilisation de l'expansion de variables
#  2015-10-20: v1.04.1	1/ Debugging consistencies name variables
#  2015-10-23: v1.05	1/ conversion of UTC (from start_time) into TDB 
#######################################
# Remarks regarding the passage from Coordinated Universal Time (UTC) to Barycentric Dynamic Time (TDB)
#  Since January 1, 1977, the "real" time is given by atomic clocks (for more information, look up optical fountain or cesium 137 transition).
#  The concerted value of the atomic time is the International Atomic Time or TAI. Or as the earth is slowing down, the passage of the sun at 
#  its zenith (aka noon) does not occur at the same time. The UTC is defined in regard to the TAI as for noon to always occur at the same UTC 
#  time. The UTC differs from the TAI by the number of leap seconds inserted to match the passage of the sun at its zenith over the years.
#  	TAI = UTC + leaps seconds
#  The epoch of reference for the TAI is 01/01/1972 00:00:00.000 . Since the 1st July 2015, 36 leap seconds have been inserted.
#  Until 1984, the ephemeris time (ET) was used to compute planetary motions. It was then replaced by the Terrestrial Dynamic Time (TDT),
#  which is tied to the TAI, though with an offset of 32.187 seconds. The purpose of the offset being to maintain continuity being ET and TDT.
#  	TDT = TAI + 32.187
#  However, in order to account for relativistic corrections due to the earth motion in the gravitational potential of the solar system, yet
#  another time is defined: the Barycentric Dynamic Time (TDB). The dominant terms of this correction have annual and semi-annual periods.
#       TDB = TT + 0.001658 sin( g ) + 0.000014 sin( 2g )  seconds
#where
#	g = 357.53 + 0.9856003 ( JD - 2451545.0 )	   degrees
# with the observation date in Julian Date or JD.
# For more details, the reader is refered to the following article:
#  Seidelmann, P.K., Guinot, B., Dogget, L.E., 1992, "Time", Chapter 2, p. 39, Explanatory Supplement to the Astronomical Almanac
#
# THUS, to convert the UTC in ephemeris time -proper- aka TDB, we use hereafter the formula
#	TDB = UTC + leap seconds + 32.187 + 0.001658 sin( g ) + 0.000014 sin( 2g )
#
# NB:
# The Unix reference time obtained by the native POSIX function date is 1/1/1970 00:00:00 and the J2000 reference time (1/1/2000 11:58:55.816).
# Note that Unix doesn't take into account leap seconds, and the date -u/--utc/--universal only gives out the UT1 in GMT.
#
########################################
 HelpDisplay () { echo -e " ----  Quick help ---- \n"\
  "Script -- OASIS_schedule_maker: Creates a scd file for the OASIS program from a list of PDS images.\n" \
  "Syntax -- OASIS_schedule_Maker.sh ListOfPDSImages.txt Schedule.dat\n" \
  "Syntax -- ListOfPDSImages.txt: A list of filenames for the PDS formatted images for which a schedule should be created, eg.:\n" \
  "Syntax -- /path/to/file1 (local or absolute path)\n"\
  "Syntax -- /path/to/file2 (local or absolute path)\n"\
  "Syntax -- ...\n"\
  "Syntax -- Schedule.dat: The name of the would-be created schedule.";
		}
########################################
# Main #
 if [ "$1" == "" ]; then echo "Exiting: No arguments given."; HelpDisplay ; exit 2; fi;
 if [ "$2" == "" ]; then
        Time=$(date +%FT%T); Time=${Time//\:/\.};
        OutputFilename="scd_OASIS_"${Time}".dat";
        touch "${OutputFilename}";
        echo "No output filename given. The results will be printed in ./"${OutputFilename};
        else OutputFilename="$2"; if [ ! -e ${OutputFilename} ]; then touch "${OutputFilename}" 
				else echo "Deleting file ""${OutputFilename}""."; rm "${OutputFilename}"; touch "${OutputFilename}"; fi;
 fi;
#######################################
 LogFilename=/tmp/OASIS_Schedule_Maker.log
 echo -e "\nA log of the operation will be created at "${LogFilename}
 if [ ! -e ${LogFilename} ]; then touch ${LogFilename}; else echo -e "#--- OASIS_Schedule_Maker log ---\n#Time of run: "${Time}"\n"  > ${LogFilename}; fi;
#######################################
 Notifier () { #Writing to /tmp/OASIS_Schedule_maker.log any particulars of this run. 
   if [ "${1}" -eq 0 ]; then echo $(basename "$2")" : Nothing to report." >> ${LogFilename}; fi;
   if [ "${1}" -eq 1 ]; then echo $(basename "$2")" : Use of pre/post-pixels noted. X/YSTART defaulted to 1. Original (XSTART,YSTART): ("${XSTRT}","${YSTRT}"). X/YEND defaulted to 2048. "$(($XSZE-2048))" X-axis pixels cut, "$(($XSZE-2048))" Y-axis pixels cut." >> ${LogFilename}; fi;
   if [ "${1}" -eq 2 ]; then echo $(basename "$2")" : File not found." >> ${LogFilename}; fi; }

 # The function GetValue extracts the value from a line.
 GetValue () { value="${1##*= }";	#taking right hand side of line
               value="${value// </<}";	#removing whitespace between values and units
               value="${value//"  "}";	#removing double whitespace (required to remove trailing whitespace)
               value="${value//[[:space:]]$'\r'}"; #removing trailing whitespace and Carriage return character
               value="${value/$'\r'/}";	#removing carriage return character
               echo "${value}"; }


 Scheduler () { if [[ ! -f "${1}" || ! -r "${1}" ]]; then Notifier 2 "${1}"; return 1; fi;
# If we reach this point, "${1}" refers to a readable regular file. Proceed. 
# The function Scheduler reads a PDS image and the sought-after values to create a new line of the schedule
# We want to catch the  following keywords:
# INSTRUMENT_ID, START_TIME, FILTER_NAME, EXPOSURE_DURATION, 
# ROSETTA:PREPIXEL_FLAG, ROSETTA:POSTPIXEL_FLAG, ROSETTA:X_START, ROSETTA:X_END,
# ROSETTA:Y_START, ROSETTA:Y_END, ROSETTA:HARDWARE_BINNING_ID, FILE_NAME
		
  while read line; do
# Extracting keyword
     keyword="${line//[[:space:]]/}"; keyword="${keyword%%=*}";

     case "${keyword}" in
        "FILE_NAME" ) Filename='OBSERVED_FRAME='$(GetValue "${line}"); ;;
        "INSTRUMENT_ID" ) Camera='CAMERA='$(GetValue "${line}");       ;;
        "START_TIME" ) Type=$(GetValue "${line}");
# It is assumed that the SPACECRAFT_CLOCK_START_COUNT and the START_TIME are equal.
# You may need to check this time and time again.
           Type='TYPE='$(if [[ ${Type} == *"-"* ]]; then echo '"ABSOLUTE"'; else echo '"RELATIVE"'; fi;);
           timestrg=$(GetValue "${line}");
# Correction for the passage of UTC to TDB (OASIS uses ephemeris time!)
           YR=${timestrg:0:4}; MO=${timestrg:5:2}; DA=${timestrg:8:2};
           HH=${timestrg:11:2}; MM=${timestrg:14:2}; SS=${timestrg:17:6};
# BC code to compute the proper UTC-TDB correction
# Number of leap seconds to insert between 1/1/1999 and the date of observations
#              jd=367*"${YR}"-int(7*("${YR}"+int(("${MO}"+9)/12))/4)-int(3*(int(("${YR}"+("${MO}"-9)/7)/100)+1)/4)+int(275*"${MO}"/9)+"${DA}"+1721028.5+("${HH}"+("${MM}"+"${SS}"/60)/60)/24;
#               if (jd < 2451179.5) {lpscd=31; print 'Start Time too early; leapseconds defaulted to 31.\n'}
           BC_script="scale=10; deg2ra=a(1)/45.0; 
              define int(x) {old_scale=scale; scale=0; ret=x/1; scale=old_scale; return ret};
              define sgn(x) {if (x > 0) {return 1}; if (x < 0) {return -1}} ;
              jd=367*"${YR}"-int(7*("${YR}"+int(("${MO}"+9)/12))/4)+int(275*"${MO}"/9)+"${DA}"+1721013.5+("${HH}"+("${MM}"+"${SS}"/60)/60)/24-0.5*sgn(100*"${YR}"+"${MO}"-190002.5)+0.5;
              if ((jd > 2451179.5) && (jd < 2453736.5)) {lpscd=32}
              if ((jd > 2453736.5) && (jd < 2454832.5)) {lpscd=33}
              if ((jd > 2454832.5) && (jd < 2456109.5)) {lpscd=34}
              if ((jd > 2456109.5) && (jd < 2457204.5)) {lpscd=35}
              if ((jd > 2457204.5) && (jq < 2457754.5)) {lpscd=36}
              if (jd > 2457754.5) {lpscd=37}
              g=((jd-2451545.0)*0.9856003+357.53)*deg2ra; 32.184+lpscd+0.001658*s(g)+0.000014*s(2*g)"
# Executing script (CALL OUTSIDE KERNEL)
           correction=$(bc -l <<< "${BC_script}");
# Adding correction to time of observation (CALL OUTSIDE KERNEL)
	   timestrg=$( date -d "${timestrg%T*} ${timestrg#*T} ${correction} seconds" +%FT%T.%N | cut -c 1-23)
# From here on end, we expect to provide a TDB time string
           if [[ "${timestrg}" != *"Z" ]]; then timestrg+="Z"; fi; # adding trailing Z
           if [[ "${timestrg}" == *":"* ]]; then timestrg="${timestrg//\:/\.}"; fi;
           Time='TIME="'${timestrg}'"';                                ;;
        "ROSETTA:PREPIXEL_FLAG" )  PREPIXEL=$(GetValue "${line}");     ;;
        "ROSETTA:POSTPIXEL_FLAG" ) POSTPIXEL=$(GetValue "${line}");    ;;
        "FILTER_NAME" ) Filter=$(GetValue "${line}");
# OASIS filter NAME convention (slashs for underscores) and uppercases names
           Filter=${Filter/_/\/}; Filter=${Filter^^};
           Filter='FILTER='${Filter};                                  ;;
        "EXPOSURE_DURATION" ) EXPOSURE_DURATION=$(GetValue "${line}");
           Exptime='EXPTIME='"${EXPOSURE_DURATION%<*}";
# Extracting temporal unit 
           Expunit=${EXPOSURE_DURATION#*<}; 
           Expunit='EXPUNIT="'${Expunit%>}'"';                         ;;
        "ROSETTA:HARDWARE_BINNING_ID" ) BINNING=$(GetValue "${line}")  ;;
        "ROSETTA:X_START" ) XSTRT=$(GetValue "${line}");               ;;
        "ROSETTA:X_END" ) XEND=$(GetValue "${line}");                  ;;
        "ROSETTA:Y_START" ) YSTRT=$(GetValue "${line}");               ;;
        "ROSETTA:Y_END" ) YEND=$(GetValue "${line}");                  ;;
     esac;
     if [[ "${line}" == *"END_OBJECT"*"HISTORY"* ]]; then break; fi;
  done < "$1";

  Xstart='XSTART='$(($XSTRT+1)); # OASIS convention first pixel (1,1)
  Ystart='YSTART='$(($YSTRT+1)); # OASIS convention first pixel (1,1)
  Xbinning='XBINNING='${BINNING:1:1}; #Assumption: format of variable is '?x?' (OSIRIS supports three bin types: 2x2,4x4 and 8x8)
  Ybinning='YBINNING='${BINNING:3:1}; # "1x1" corresponds in sequence to the x-axis binning "times" the y-axis binning.
# If the pre-pixels or post-pixels bands are used, we default the image parameters
  if [[ "${PREPIXEL}" == "TRUE" || "${POSTPIXEL}" == "TRUE" ]]; then Notifier 1 "${1}"; Xstart='XSTART=1'; Ystart='YSTART=1'; XSZE=2048; YSZE=2048; fi;
  if [[ "${PREPIXEL}" == "FALSE" && "${POSTPIXEL}" == "FALSE" ]]; then Notifier 0 "${1}"; XSZE=$((${XEND}-${XSTRT})); YSZE=$((${YEND}-${YSTRT})); fi;
  Xsize='XSIZE='${XSZE};
  Ysize='YSIZE='${YSZE};
# Assembling result
  echo "IMAGE "${Camera}","${Type}","${Time}","${Filter}","${Exptime}","${Expunit}","${Xstart}","${Ystart}","${Xsize}","${Ysize}","${Xbinning}","${Ybinning}","${Filename}",DELTAXCCD=0,DELTAYCCD=0,DELTAROLL=0";
        }

#######################################
 NLINES=$(wc -l < "${1}" | awk '{print $1}')
 NLine=0
 while read line; do
  Scheduler "${line}" >> "$OutputFilename";
# Progression bar
  NLine=$[$NLine +1]; index=$((100 * ${NLine} / ${NLINES}));
  echo -ne "Progression: "${index}"%"\\r;
 done < "${1}"
#######################################
echo
echo -e "\nOASIS_Schedule_Creator is done with this task.\n"\
	"Please check the created schedule: ./"${OutputFilename}\
	" !\n Please check the created log: "${LogFilename}" !"

#######################################
#Old Versions
#######################################
#!/bin/bash
# echo "OASIS_Schedule_Creator V.1 - C.Feller (LESIA: cfeller@obspm.fr)."
#	# Changelog
#	# 2015-08-25: v0.9	Conformation with OASIS' CCD reference convention/OutputFileName default setting modification
#	# 2015-08-26: v1	Conformation with OASIS' TIME ":" writing convention, FILTER uppercase convention
#	# 2015-09-02: v1.01	1/ Creation of operations log; 2/ Defaulting image parameters when pre-pixels or post-pixels flags are raised.
#	# 2015-09-08: v1.02	1/ Substitution of reference to line variable in Sheduler fonction by first input variable of Sheduler fonction;
#	#			2/Adding quotes for that variable in case filepath reference (ie ${line}) contains whitespaces; 3/ Modification of 
#	#			Notifier fonction: adding second input variable (ie ${line}); 4/ Adding existence check to OutputFilename 
#	# 2015-09-11: v1.03	1/Debug with the X/Ysize not being outputted->moving them in the pre/postpixel paragraph.
########################################
# if [ "$1" == "" ]; then
#	echo "Syntax -- OASIS_schedule_maker: Creates a scd file for the OASIS program from a list of PDS images. ";
#	echo "Syntax -- OASIS_schedule_Maker.sh ListOfPDSImages.txt Schedule.dat";
#	echo -e "Syntax -- ListOfPDSImages.txt: A file containing a list of filenames of PDS formatted images for which a schedule should be created, eg.:\nSyntax -- /path/to/file1\nSyntax -- ./path/to/file2\nSyntax -- ...\nSyntax -- Schedule.dat: The name of the would-be created schedule.";
# 	exit 2;
# fi;
# if [ "$2" == "" ]; then
#	Time=$(date +%FT%T | sed 's/\:/./g') 
#	OutputFileName="scd_OASIS_"${Time}".dat"; 
#	touch "${OutputFileName}"; 
#	echo "No output filename given. The results will be printed in ./"${OutputFileName};
#	else OutputFilename="$2"; if [ ! -e ${OutputFilename} ]; then touch ${OutputFilename}; fi;
# fi;
########################################
# LogFilename=/tmp/OASIS_Schedule_Maker.log
# echo -e "\nA log of the operation will be created at "${LogFilename}
# if [ ! -e ${LogFilename} ]; then touch ${LogFilename}; else echo -e "#--- OASIS_Schedule_Maker log ---\n#Time of run: "${Time}"\n"  > ${LogFilename}; fi;
########################################
# RemoveCR () { sed 's/\r//g'; } # Pipeline produces windows CR character at end of lines
# Notifier () { #Writing to /tmp/OASIS_Schedule_maker.log any particulars of this run. 
#		if [ "$1" -eq 0 ]; then echo $(basename "$2")" : Nothing to report." >> ${LogFilename}; fi;
#		if [ "$1" -eq 1 ]; then echo $(basename "$2")" : Use of pre/post-pixels noted. X/YSTART defaulted to 1. Original (XSTART,YSTART): ("${XSTRT}","${YSTRT}"). X/YEND defaulted to 2048. "$(($XSZE-2048))" X-axis pixels cut, "$(($XSZE-2048))" Y-axis pixels cut." >> ${LogFilename}; fi;}
# GetValue () { awk -v parm=$2 '{if ($1~parm){print $3; exit}}' "$1"; }	#ALTERNATIVE: grep -aw -m 1 "$1" | awk '{print $3}';
# GetUnit () {  awk -v parm=$2 '{if ($1~parm){print $4; exit}}' "$1" | sed 's/\(<\|>\)/"/g'; }
# CheckTime () { if [[ ${1:4:1} == "-" ]]; then echo '"ABSOLUTE"'; else echo '"RELATIVE"'; fi; } # Test designed according to OASIS manual Table 3.3 "Time".Description
# TimeConformation () { timestrg=""
#		       if [[ ${1:(-2):1} != "Z" ]]; then timestrg=${1:0:-1}"Z"; else timestrg=${1}; fi; # adding eventual missing trailing Z
#		       if [[ ${timestrg} == *":"* ]]; then echo ${timestrg/\:/\.}; fi;} #substitution of ":" by "."
# OasisFilterNameConv () { sed 's/_/\//g' | tr '[:lower:]' '[:upper:]'; } # substitution of underscore with slash and putting result in uppercase
# Scheduler () { Camera='CAMERA='$(GetValue "$1" "INSTRUMENT_ID");
#		  START_TIME=$(GetValue "$1" "START_TIME" );
#		Type='TYPE='$(CheckTime ${START_TIME});
#		Time='TIME="'$(TimeConformation ${START_TIME})'"';
#		Filter='FILTER='$(GetValue "$1" "FILTER_NAME" | OasisFilterNameConv);
#		  EXPOSURE_DURATION=$(awk '{ if ($1~"EXPOSURE_DURATION"){print $3,$4; exit} }' "${line}" | sed 's/\(<\|>\)/"/g' );
#		Exptime='EXPTIME='$(echo ${EXPOSURE_DURATION} | cut -d" " -f1);# try removing guillements and variable expansion before and after
#	 	Expunit='EXPUNIT='$(echo ${EXPOSURE_DURATION=} | cut -d" " -f2);# whitespace
#		  PREPIXEL=$(GetValue "$1" "ROSETTA:PREPIXEL_FLAG" | RemoveCR)
#		  POSTPIXEL=$(GetValue "$1" "ROSETTA:POSTPIXEL_FLAG" | RemoveCR)		  
#		  XSTRT=$(GetValue "$1" "ROSETTA:X_START" | RemoveCR);
#		  XEND=$(GetValue "$1" "ROSETTA:X_END" | RemoveCR);
#		Xstart='XSTART='$(($XSTRT+1)); # OASIS convention first pixel (1,1)
#		  YSTRT=$(GetValue "$1" "ROSETTA:Y_START" | RemoveCR);
#		  YEND=$(GetValue "$1" "ROSETTA:Y_END" | RemoveCR);
#		Ystart='YSTART='$(($YSTRT+1)); # OASIS convention first pixel (1,1)
#		  BINNING=$(GetValue "$1" "ROSETTA:HARDWARE_BINNING_ID");
#		Xbinning='XBINNING='${BINNING:1:1}; #Assumption: format of variable is '?x?' (OSIRIS supports three bin types: 2x2,4x4 and 8x8)
#		Ybinning='YBINNING='${BINNING:3:1}; # "1x1" corresponds in sequence to the x-axis binning "times" the y-axis binning.
#		Filename='OBSERVED_FRAME='$(GetValue "$1" "FILE_NAME");
#	# If the pre-pixels or post-pixels bands are used, we default the image parameters
#		if [[ "${PREPIXEL}" == "TRUE" || "${POSTPIXEL}" == "TRUE" ]]; then Notifier 1 "$1"; Xstart='XSTART=1'; Ystart='YSTART=1'; XSZE=2048; YSZE=2048; fi;
#		if [[ "${PREPIXEL}" == "FALSE" && "${POSTPIXEL}" == "FALSE" ]]; then Notifier 0 "$1"; XSZE=$(($XEND-$XSTRT)); YSZE=$(($YEND-$YSTRT)); fi;
#		Xsize='XSIZE='${XSZE};
#		Ysize='YSIZE='${YSZE};
#	# Assembling result and removal of eventual remaining CR character.
#	  echo "IMAGE "${Camera}","${Type}","${Time}","${Filter}","${Exptime}","${Expunit}","${Xstart}","${Ystart}","${Xsize}","${Ysize}","${Xbinning}","${Ybinning}","${Filename} | RemoveCR;
#	}
#
########################################
#NLINES=$(wc -l < $1 | awk '{print $1}')
#NLine=0
#while read line; do
#	Scheduler "${line}" >> "$OutputFileName";
#	# Progression bar
#	NLine=$[$NLine +1]; index=$((100 * ${NLine} / ${NLINES}));
#	echo -ne "Progression: "${index}"%"\\r;
#done < $1
########################################
#echo
#echo -e "\nOASIS_Schedule_Creator is done with this task.\n Please check the created schedule: ./"${OutputFileName}" !\n Please check the created log: "${LogFilename}" !"
