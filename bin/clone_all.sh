#!/bin/bash


 ## note:
 ##  -  it appears that it takes some time for a repo to show up in an orgs repo list
 ##  -  the curl call below is rate limited, not intended for repeated invocations
for i in $(curl --silent "https://api.github.com/orgs/triplea-maps/repos?page=1&per_page=10000" | grep git_url | sed 's/.*: "//i' | sed 's/",$//'); do
 mapName=$(echo $i | sed 's/.git$//' | sed 's|.*/||')

 echo $mapName - $i
 if [ ! -d "$mapName" ]; then
   echo git clone $i
 fi
done



