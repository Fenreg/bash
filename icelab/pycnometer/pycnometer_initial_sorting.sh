#==============================================================================
#d NAME: pycnometer_initial_sorting.sh
#d AUTHOR: Clément Feller (cxlfeller--at--gmx<dot>com)
#d PURPOSE: sorting, arranging, consolidating initial batch of data (Dec-2019, 
#d   May-2020)
#d CHANGELOG: 2020-05-26 v1.0 first light
#d I/O:
#d <- Nothing
#d -> Two files sorted
#d
#d USAGE: (example)
#d COMMENTS: (give it a blue thumb)
#d DEPENDANCIES: (compiler version, version of functions used)
#d NOTES: None
#d COPYRIGHT: CC-BY-NC-ND
#==============================================================================
#c In 2019 folder
#for file in ./ultraReportcf201912??-?.txt; do mv "${file}" "${file/-/-0}"; done

#c In 2020 folder
#mv ./ultraReportcf20200518.txt ./ultraReportcf20200518-00.txt
#mv ./ultraReportcf20200519.txt ./ultraReportcf20200519-00.txt
for file in ./ultraReport{cf,CF}202007*-?.txt; do mv "${file}" "${file/-/-0}"; done
for file in ./ultraReport{cf,CF}2020????.txt; do mv "${file}" "${file/\.txt/-00\.txt}"; done

for file in ./*txt; do pycnometer_get_data.sh $file; done

output="${file/-*/}"
out__v="${output}_volume.lst"
out__d="${output}_density.lst"

#c Volume
for file in ./*cleaned.dat; do \
  a="$(grep -ai volume -A1 "${file}"| tail -n1)";
  echo -e "${file/_cleaned\.dat/\.txt}\t${a}" >> "${out__v}";
done
sort -t ' ' -k2 "${out__v}" > tmp.tmp
cat tmp.tmp > "${out__v}"

#c Density
for file in ./*cleaned.dat; do \
  a="$(grep -ai density -A1 "${file}"| tail -n1)";
  echo -e "${file/_cleaned\.dat/\.txt}\t${a}" >> "${out__d}";
done
sort -t ' ' -k2 "${out__d}" > tmp.tmp
cat tmp.tmp > "${out__d}"

# Cleaning
rm tmp.tmp
