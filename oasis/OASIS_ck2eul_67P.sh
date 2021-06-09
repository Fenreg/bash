#!/bin/bash
#d Script written by cfeller (cfeller<at>obspm.fr)
#d
#d PURPOSE:
#d By progressively (reading the OASIS_eph.dat file AND executing the program 
#d ck2eul_67P.exe), this code produces a serie of ephemerids.
#d
#d Changelog:
#d    2015 Nov 04 v1.0 First light
#d    2016 Jul 29 v1.1 Spring cleaning, script clarification
#d    2017 Feb 13 v1.2 debugging, portability changes
#d
#d Dependances:
#d    OASIS - ck2eul_67P.exe (ck2eul.exe + modifications)
#d            -> parameters NAIF ID, time step and angular step hardcoded.

#c Checking if the ephemerids particulars and the program can be found.
  OasisFolder="/home/user-777/These/OASIS/ROS"; #/volumes/planeto/osiris/OASIS
  Ephemerids="Calendar.eph"
  ProgramPath="/home/user-777/ADDED/OASIS";
  OasisScript="ck2eul_67P_debug.exe"; 
  Path2Kernel="/home/user-777/These/Tycho/SPICE";
  SpiceFurnsh="ck2eul.txt";
  Path2Output="/home/user-777/test";

#c Checking everything is in place for the script.
#c Check access to ephemerids file
  if [ ! -e "${OasisFolder}/${Ephemerids}" ]; then 
     echo "Ephemerids parameter file ${OasisFolder}/${Ephemerids}"\
      " can't found. Please check file path.";
     exit 1;
  fi;
#c Check access to meta kernel containing paths to kernels
  if [ ! -e "${Path2Kernel}/${SpiceFurnsh}" ]; then 
     echo "Meta-Kernel ${Path2Kernel}/${SpiceFurnsh} can't be found."\
      " Please check file path.";
     exit 1;
  fi;
#c Check access to Oasis script
  if [ ! -e "${ProgramPath}/${OasisScript}" ]; then 
     echo "Script ${ProgramPath}/${OasisScript} can't be found."\
      "Please check script path.";
     exit 1;
  fi;
#c Checking if the program is executable:
  if [ ! -x "${ProgramPath}/${OasisScript}" ]; then 
     chmod +x "${ProgramPath}/${OasisScript}";
  fi;
  if [[ "$?" == 1 ]]; then 
     echo " You're not allowed to change the permissions of "\
      "${ProgramPath}/${OasisScript}. Exiting.";
     exit 1;
  fi;
#c __MAIN__
  OldPwd=${PWD};
#c Moving to the folder containing the metakernel
  cd "${Path2Kernel}"
#c Creating output temporary file
  TmpFile="/tmp/OSIRIS_ck2eul.tmp";
  touch "${TmpFile}";
#c Naming variable that shall be printed in temp file
  NomDates="";
#c Creating output filename from ephemerids index
  Prefix="eul_P01000012_";
  Suffix=".dat";
#c Creating outputfile containing rotation parameters
  RotFile="${Prefix}ROT${Suffix}";
  touch "${RotFile}";
  echo "#feul tint(1) tint(2) E1 E2 E3 RA DEC EAR ERD" > "${RotFile}";
#c Executing OasiScript for all lines but comments.
  while read line; do 
     if [[ "${line:0:1}" != "#" ]]; then 
        NomDates=${Prefix}${line:0:3}${Suffix}${line:3:24} ;
        echo "${NomDates}" > "${TmpFile}"; 
        ${ProgramPath}"/"${OasisScript};
        ParRot=$(awk -F" " '{ORS=" "} {print $3}' ck2eul.2.dat);
        echo ${NomDates}" "${ParRot} >> "${RotFile}";
        NomDates="";
        ParRot="";
     fi;
  done < "${OasisFolder}/${Ephemerids}";
#c Moving results to output folder
  mv "${PWD}/${Prefix}"*dat "${Path2Output}";
#c Cleaning
  rm "${TmpFile}" ck2eul.2.dat;
#c Setting back to previous folder
  cd "${OldPwd}";
#c Exiting
  echo "End of script reached.";
exit 0
