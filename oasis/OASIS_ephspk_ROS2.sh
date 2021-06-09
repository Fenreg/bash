#!/bin/bash
#c Script written by cfeller (cfeller<at>obspm.fr)
#c
#c Description:
#c By progressively (reading the Calendar.eph file AND executing the program 
#c ephspk_ROS.exe), this code produces a serie of ephemerids.
#c
#c Changelog:
#c    2015 Nov 04 v1.0 First light
#c    2O16 Aug 16 v1.1 Spring cleaning, script clarification
#c                     !!NB!!: Until further notice do NOT operate simulatenously 
#c                             ephspk_67P and ephspk_ROS, or the scripts will make
#c                             use of the same temp file /tmp/OSIRIS_ephspk.tmp
#c                             Further modification to fortran code is required to 
#c                             circumvent this.
#c
#c Dependances:
#c    OASIS - ephspk_ROS.exe (ephspk_ROS.exe + modifications)
#c            -> parameters NAIF ID, time step and angular step hardcoded.
#c Program location:
#c    /volumes/planeto/osiris/bin @ LESIA08

#c Checking if the ephemerids particulars and the program can be found.
  OasisFolder="/home/user-777/These/OASIS"; #/volumes/planeto/osiris/OASIS
  ProgramPath="/home/user-777/ADDED/OASIS";
  Path2Kernel="/home/user-777/These/Tycho/SPICE";
  OasisScript="ephspk_ROS.exe";
  Path2Output="/home/user-777/test";
  SpiceFurnsh="ephspk.txt";
  Ephemerids="Calendar2.eph"

#c Checking everything is in place for the script
#c Check access to ephemerids file
  if [ ! -e "${OasisFolder}/ROS/${Ephemerids}" ]; then
     echo "Ephemerids parameter file ${OasisFolder}/ROS/${Ephemerids}"\
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
  if [ ! -e "${ProgramPath}/${OasiScript}" ]; then
     echo "Script ${ProgramPath}/${OasiScript} can't be found."\
      "Please check script path.";
     exit 1;
  fi;
#c Checking if the program is executable:
  if [ ! -x "${ProgramPath}/${OasiScript}" ]; then
     chmod +x "${ProgramPath}/${OasiScript}";
  fi;
  if [[ "$?" == 1 ]]; then
     echo " You're not allowed to change the permissions of "\
      "${ProgramPath}/${OasiScript}. Exiting.";
     exit 1;
  fi;
#c __MAIN__
  OldPwd=${PWD};
#c Moving to the folder containing the metakernel 
  cd "${Path2Kernel}"
#c Creating temporary file
  TmpFile="/tmp/OSIRIS_ephspk_ROS.tmp";
  touch "${TmpFile}";
#c Naming variable that shall be printed in temp file
  NomDates="";
#c Creating output filename from ephemerids index
  Prefix="pos_M00000226_P00000010_";
  Suffix=".dat";
#c Executing OasisScript for all lines but comments.
  while read line; do 
     if [[ "${line:0:1}" != "#" ]]; then 
        NomDates=${Prefix}${line:0:3}${Suffix}${line:3:24} ;
        echo "${NomDates}" > "${TmpFile}"; 
        ${OasisScript};
        NomDates="";
     fi;
  done < "${OasisFolder}/ROS/${Ephemerids}";
#c Moving results
  mv "${PWD}/${Prefix}"*dat "${Path2Output}" ;
#c Cleaning
  rm "${TmpFile}" ephspk.out;
#c Setting back to previous folder
  cd "${OldPwd}";
#c Exiting
  echo "End of script reached.";
exit 0
