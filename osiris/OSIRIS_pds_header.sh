#!/bin/bash
#d Program written by C.Feller (cfeller<at>obspm.fr)
#d Aim: saving Header contents of all OSIRIS images available for investigation
#d
#d Method: reading list of the OSIRIS images available, parsing the ASCII part 
#d of the file until meeting the end of the Header (assumption: the Header is  
#d composed of two parts: the main description of the image and its level of   
#d treatment through the OSIRIS pipeline) then saving all the interesting      
#d Values in a array which is later printed to a file containing all the Header
#d Values for the OSIRIS images treated with the pipeline as of version 1.x.y.z
#d
#d Changelog:
#d  5th Oct 2015: v1.0    "first light"
#d  8th Oct 2015: v1.0.1  echoing arrays with particular format separator
#d 29th Nov 2015: v1.0.2  listing images according to A) Camera B) pipeline ID 
#d 30th Nov 2015: v1.0.3  Renaming variables; cleaning 
#d
#d   To-do list:
#d   -> implement self building of images available (if images can be found at one definite place)
#d   -> option: name of output file
#d   -> option: input file (for subset analysis)
#d   -> implement saving of names of files created (string)
#d   -> re-writing everything for sql

#c Saving value of the <List of Images' path> parameter
Listing="$1"
#c Saving Internal Field Separator
oldIFS=$IFS
#######################################
# Global variables
  IFS="|"
  OutputFile_pth="/tmp/";
  OutputFile_pre="OSIRIS_";
  OutputFile_ext=".dat";
# fonctions de base
  ReadTestSaveHeader () {
   if [ ! -e "$1" ]; then echo "File not found. Exiting..."; exit 1; fi;
   Header_Line=""; Keyword=""; Value=""; Header__Keywords=(); Header__Values=();
   SFTWR_ID_tmp=""; INSTR_ID_tmp="";
      
   Header_End=0
   until [[ ${Header_End} == 1 ]];
   do
     read Header_Line;
     Keyword="${Header_Line//[[:space:]]/}";
     Keyword="${Keyword%%=*}"; #taking left hand side of line
#c Testing Keyword value; jumping over empty line, titles lines and 
#c NOTE keyword whose value is spread over 4 lines.
     if [[ "${Keyword}" == "" || "${Keyword:0:1}" == "/" ||\
           "${Keyword}" == "NOTE" || "${Keyword:3:6}" == "Values" ||\
           "${Keyword:0:8}" == "Distance" ]]; then comment="yes" ;
#c Taking right hand side of line
     else Value="${Header_Line##*= }";
#c Removing whitespace between Values and units
          Value="${Value// </<}";
#c Rremoving double whitespace (required to remove trailing whitespace)
          Value="${Value//"  "}";
#c Removing trailing whitespace and Carriage return character
          Value="${Value//[[:space:]]$'\r'}";
#c Removing carriage return character
          Value="${Value/$'\r'/}";
#----debug----
#echo "${Keyword}:${Value};";
#----debug----
#saving Keyword/Value into array
          Header__Keywords+=("${Keyword}"); Header__Values+=("${Value}");
     fi;
#c Saving pipeline version ID
     if [[ "${Keyword}" == "SOFTWARE_VERSION_ID" ]]; then 
          SFTWR_ID_tmp="${Value//\"}";
     fi;
#c Saving camera type
     if [[ "${Keyword}" == "INSTRUMENT_ID" ]]; then 
          INSTR_ID_tmp="${Value//\"}";
     fi;
#c if reaching end of binary Header, we stop reading the file.
     if [[ "${Keyword}" == "END_OBJECT" && "${Value}" == *"HISTORY"* ]]; then
          Header_End=1;
     fi;
   done < "$1" ;
   #----debug----
   #echo ${Header__Keywords[@]};
   #echo ${Header__Values[@]};
   #echo "${SFTWR_ID_tmp}"_"${SFTWR_ID_ref}"
   #----debug----

#c Checking pipeline version ids between two images, if different switching output to other file
   if   [[ "${INSTR_ID_tmp}" == "${INSTR_ID_ref}" && "${SFTWR_ID_tmp}" == "${SFTWR_ID_ref}" ]]; then
      OutputFile="${OutputFile_pth}${OutputFile_pre}${INSTR_ID_ref}"_v"${SFTWR_ID_ref}${OutputFile_ext}"
   elif [[ "${INSTR_ID_tmp}" != "${INSTR_ID_ref}" && "${SFTWR_ID_tmp}" == "${SFTWR_ID_ref}" ]]; then
      OutputFile="${OutputFile_pth}${OutputFile_pre}${INSTR_ID_tmp}"_v"${SFTWR_ID_ref}${OutputFile_ext}"
   elif [[ "${INSTR_ID_tmp}" == "${INSTR_ID_ref}" && "${SFTWR_ID_tmp}" != "${SFTWR_ID_ref}" ]]; then
      OutputFile="${OutputFile_pth}${OutputFile_pre}${INSTR_ID_ref}"_v"${SFTWR_ID_tmp}${OutputFile_ext}"
   else
      OutputFile="${OutputFile_pth}${OutputFile_pre}${INSTR_ID_tmp}"_v"${SFTWR_ID_tmp}${OutputFile_ext}"
   fi;

#c Testing if OutputFile is regular file & writing output
   if [[ -e "${OutputFile}" && -w "${OutputFile}" ]]; then 
     echo "${Header__Values[*]}" >> ${OutputFile}; 
   else 
    echo -e "${Header__Keywords[*]}""\n""${Header__Values[*]}" >> ${OutputFile};
   fi;

#c Reset reference Values for the following test.
   SFTWR_ID_ref="${SFTWR_ID_tmp}";
   INSTR_ID_ref="${INSTR_ID_tmp}";
#c memory reset 
   Header_Line=""; Keyword=""; Value=""; Header__Keywords=(); Header__Values=();
   SFTWR_ID_tmp=""; INSTR_ID_tmp=""; OutputFile="";
   }
#######################################
#######################################
#__Main__
NLINES=$(wc -l < "${Listing}");
index=0;
while read line; do
   ReadTestSaveHeader "${line}";
   if [ "$?" -eq 1 ]; then echo "File "${line}" not found. Passing on to the next one."; fi;
#c Progression bar
   index=$[index+1];progression=$((100 * ${index} / ${NLINES}));
   echo -ne "Progression: "${progression}"%"\\r;
done < "${Listing}"

echo
echo -e "Saving OSIRIS image Headers is done.\n Please check the created schedule: "${OutputFile_pth}"OSIRIS_*.dat !"
IFS=${oldIFS}
exit 0;
