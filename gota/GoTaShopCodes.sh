#!/bin/bash
#c afterwards once you know what to compare and found exactly what you wanted
#c rewrite as curl can do bulk download
#c can one start downloading only the http_code and if page adress valid download the rest of the page?
#c other possibility check all pages
#c download all valid pages
#c extract codes and TimeLimit without the page adress
#c
#c find out if when you get CodeTimeName you're not actually already downloading the whole page
#c

#c Adapt eventually the maximum value. Experience tells us that there is no need for that.
for index in {230..300};do
#c Define the nth adress you're going to reach.
  WebPage="http://gota.disruptorbeam.com/play/special_offer/"${index}
#c Check if page is empty or not.
  HTTPCode=$(curl --write-out "%{http_code}\n" --silent --output /dev/null ${WebPage} )
#c In case the page is not empty and then parse and grab the shop code, its name and expiration date.
  if [ ${HTTPCode} == 200 ]; then
     CodeTimeName=$(curl -s ${WebPage} | tee 1>/dev/null  >(grep -ao '<p style="margin-top: 20px;">Redeem your code for a gift! Your code will grant you: .*</p>') >(grep -ao 'expires: .*\. ') >(grep -ao '<p style="margin-top: 15px; color: white; font-size: 32pt">.*</p>') );
#c If string isn't empty, print out results.
     if [[ ${CodeTimeName} != '' ]]; then 
        echo ${CodeTimeName} | sed 's/\(<p style="margin-top: 20px;">Redeem your code for a gift! Your code will grant you: \|expires:\ \|\.\ \|<p style="margin-top: 15px; color: white; font-size: 32pt">\|<\/p>\)/*/g' | awk -F* '{print $4,"index",page,$2,$6}' page="${index}" | sed "s/&#x27;/\'/";
     fi;
  fi;
done
