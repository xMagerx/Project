#!/bin/bash

MAP_FOLDER=$(echo $1 | sed 's|/$||')
TOKEN_FILE=$2


if [[ -z "$MAP_FOLDER" ]] || [[ ! -f "$TOKEN_FILE" ]]; then
  echo "usage: $(basename $0) <map_folder> <token_file>"
  echo "  map_folder: map repository to delete"
  echo "  token_file: file containing nothing but a github personal access token"
  exit 
fi

if [ -e "$MAP_FOLDER" ]; then
#  (
#   cd $MAP_FOLDER
#   travis login --github-token $(cat "$TOKEN_FILE")
#   travis env clear
#  )
  rm -rf "$MAP_FOLDER"
fi

curl -X DELETE -H "Authorization: token $(cat $TOKEN_FILE)" https://api.github.com/repos/triplea-maps/$MAP_FOLDER

travis sync
sleep 1
