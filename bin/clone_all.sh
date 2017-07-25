#!/bin/bash


 ## note:
 ##  -  it appears that it takes some time for a repo to show up in an orgs repo list
 ##  -  the curl call below is rate limited, not intended for repeated invocations

for j in 1 2; do
  while read gitUrl; do 
    echo "clone $gitUrl"; 
    git clone $gitUrl; 
  done < <(curl --silent "https://api.github.com/orgs/triplea-maps/repos?page=$j&per_page=1000" | grep git_url  | sed 's/.*git:/git:/' | sed 's/",//')
done



