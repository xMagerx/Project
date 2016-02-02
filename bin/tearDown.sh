#!/bin/bash


function usage() {
  echo "usage: $(basename $0) -t <token_file_for_admin> -a <account_name_bot> -p <password_file_for_bot> -m <local_map_folder>"
  echo " -a bot_account_name: bot account name, used to delete access tokens"
  echo " -p bot_password_file: github auth api needs username password to delete access tokens" 
  echo " -t admin_token_file: path to a file containing an access token for an admin, able to delete the repository"
  echo " -m map_folder: local map repository folder that is the target of deletion"  
  echo "example: $(basename $0) -a tripleabuilderbot -t ~/.github/token -p ~/.github/bot_password -m MAP"
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

GITHUB_ACCOUNT=""
GITHUB_TOKEN_FILE=""
GITHUB_PASSWORD_FILE=""
MAP_FOLDER=""

while [[ $# -gt 1 ]]
do
  key="$1"
  case "$key" in
    -a|--bot-account-name)
      GITHUB_ACCOUNT="$2"
      shift 2
      ;;
    -t|--bot-token-file)
      GITHUB_TOKEN_FILE="$2"
      shift 2
      ;;
    -p|--bot-password-file)
      GITHUB_PASSWORD_FILE="$2"
      shift 2
      ;;
    -m|--map-folder)
        # remove trailing slash
      MAP_FOLDER=$(echo "$2" | sed 's|/$||')
      shift 2
      ;;
  esac
done

if [[ "$MAP_FOLDER" == "." ]] || [[ "$MAP_FOLDER" == ".." ]]; then
  echo "Error: map folder to delete should not be the current folder, check the '-m' parameter"
  exit -1
fi

if [ ! -f "$GITHUB_TOKEN_FILE" ]; then
  echo "Error: '-t' token file parameter was not set or is not a file: $GITHUB_TOKEN_FILE"
  exit -1
fi

if [ ! -f "$GITHUB_PASSWORD_FILE" ]; then
  echo "Error: '-p' token file parameter was not set or is not a file: $GITHUB_PASSWORD_FILE"
  exit -1
fi

if [ -z "$GITHUB_ACCOUNT" ]; then
  echo "Error: '-a' bot account name parameter was not set"
  exit -1
fi



AUTH_STRING="$GITHUB_ACCOUNT:$(cat $GITHUB_PASSWORD_FILE)"

 ## first just check that hte username and password combination are valid
curl -su "$AUTH_STRING" https://api.github.com/authorizations  | grep -q "Bad credentials" &&  { echo "Check authentication credentials"; exit -1; }

echo "Removing Map: $MAP_FOLDER"

curl -sX DELETE -H "Authorization: token $(cat $GITHUB_TOKEN_FILE)" "https://api.github.com/repos/triplea-maps/$MAP_FOLDER" | grep -q "Not Found" && { echo "WARNING, could not delete remote repo. Make sure you are using your own token an not a bot token. 404 is either because the repo does not exist or you the token does not have permission to delete the repo $MAP_FOLDER"; }

 ## delete tokens
for i in $(curl -su "$AUTH_STRING" "https://api.github.com/authorizations?per_page=1000&page=1"  | egrep -B4 -i "\"name\".*$MAP_FOLDER" | grep "id" | sed 's/.*: //' | sed 's/,$//'); do
  echo "Deleting token:"
  curl -su "$AUTH_STRING" "https://api.github.com/authorizations?per_page=1000&page=1"  | egrep -B4 -i "\"name\".*$MAP_FOLDER"
  
  curl -X DELETE -su "$AUTH_STRING" "https://api.github.com/authorizations/$i"
  echo "Deleted token: $i"
  sleep 3
done

rm -rf "$MAP_FOLDER"

echo 'done, run travis sync when everything is all done'
