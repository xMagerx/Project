#!/bin/bash

clear 

export bold=$(tput bold)
export normal=$(tput sgr0)
NC='\033[0m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'

ORG_NAME=triplea-maps
BOT_ACCOUNT=tripleabuilderbot


SCRIPT_NAME=$(basename "$0")
function usage() {

cat << EOF

Usage: ./$SCRIPT_NAME -g {path_to_token_file} -p {path_to_bot_password_file}
Example: ./$SCRIPT_NAME -g ~/.github/personal_access_token -p ~/.github/builderbot_password
    path_to_token_file = relative or absolute path to a file 
             containing a GitHub admins personal access token.
    path_to_bot_password_file = relative or absolute path to a 
             file that contains the tripleabuilderbot
             GitHub account password.

TripleA Map Zip file to GitHub repository migration Tool

Scans the current folder for any zip files. For each one, normalized the name, creates a folder to host the github repo, extracts the zip into a map folder inside of teh hosting folder. The script then copies in and configures the Git support files, it also then remotely configures GitHub.com and Travis.org.

Security Note: The bot account password will be displayed on standard 
    out in plain text occasionally while this script is running.
EOF
exit 1
}


if [ $# == 0 ]; then
  usage
fi

while [[ $# -gt 1 ]]
do
  key="$1"
  case $key in
    -g|--github-admin-token)
      ADMIN_TOKEN_FILE="$2"
      shift 2
      ;;
    -p|--bot-account-password)
      BOT_PASSWORD_FILE="$2"
      shift 2
      ;;

    *)
      echo "${bold}Unrecognized argument: $key${normal}"
      usage
      ;;
  esac
done


################


function printTitle() {
  COLOR=$2
  echo -e "${COLOR}${bold}$1${NC}"
}

function printBlueTitle() {
  printTitle "$1" "${BLUE}"  
}

function printGreenTitle() {
  printTitle "$1" "${PURPLE}"  
}


function die() {
  printTitle "Script Error $1"
  exit 1
}


function verifyDependency() {
  local DEPENDENCY=$1
  hash "$DEPENDENCY" 2> /dev/null || { echo "expect not installed"; exit 1; }
}

function printZipFilesFound() {
  echo
  printBlueTitle "<<Starting>>"
  printTitle "Found $(find . -maxdepth 1 -name '*zip' | wc -l) File(s)"
  find . -maxdepth 1 -name '*zip' | sed 's|^./||'
  echo
}

function checkFileExists() {
  local FILE_TO_CHECK=$1
  if [ ! -f "$FILE_TO_CHECK" ]; then
   die "Did not find file: $FILE_TO_CHECK"
  fi
}

function checkNotEmpty() {
  local TOKEN=$1
  if [ -z "$TOKEN" ]; then
    die "empty token found in the password or token file supplied as parameters"
  fi
}

function checkValidCredentials() {
  printTitle "Verifying GitHub credentials"
  local token=$1
  local botAccount=$2
  local botPassword=$3
  
  DEAD=0
  echo -n "Admin -"
  curl --silent -u "${token}:x-oauth-basic" https://api.github.com/user | grep login || \
     { echo "Failed to authenticate against GitHub with the admin token provided."; DEAD=1; }
  echo -n "Bot   -"
  curl --silent -u "${botAccount}:${botPassword}" https://api.github.com/user | grep login || \
     { echo "Failed to authenticate against GitHub with bot password token."; DEAD=1; }
  if [ "$DEAD" != 0 ]; then
   die
  fi
  echo
}


function normalizeName() {
  local mapZip=$1
     # normalization will:
     #  - strip the zip sufix
     #  - insert an underscore between lower case and upper case letter to break up camel casing
     #  - lower case everything
     #  - upper case first letter of all words
     #  - replace spaces with underscores 
  local normalized=$(echo "$mapZip" | sed 's/.zip$//' | \
                sed 's/\([a-z]\)\([A-Z]\)/\1_\2/g' | tr '[:upper:]' '[:lower:]' | \
                sed "s/  */_/g" | sed 's|^\./||')
  
  echo "$normalized"
}

function extractMapToNormalizedFolder() {
  local mapZip=$1
  local targetFolder=$2
    ## in the zip and folder name, remove the leading "./"
  printTitle "Extracting zip"
  
  mkdir -p "$targetFolder"
  UNZIP_COUNT=$(unzip -n "$mapZip" -d "${targetFolder}" 2>&1 | wc -l)
  echo "Extracted $((UNZIP_COUNT-1)) files from '${mapZip//.\//}'"
  echo ""
}


verifyDependency "expect"
verifyDependency "parallel"


printZipFilesFound

checkFileExists "$ADMIN_TOKEN_FILE"
checkFileExists "$BOT_PASSWORD_FILE"

function curFolder() {
(
    local NEW_FOLDER=$(dirname "$0")
    cd "$NEW_FOLDER"
    pwd
  )
}

function deleteBotGitHubToken() {
  local botPassword=$1
  local tokenName=$2
  
  local botAuth="$BOT_ACCOUNT:$botPassword"
  local oldTokenId=$(curl --silent -u "$botAuth" "$githubAuthUrl" 2>&1 | grep -i -B3 "\"name\": \"$tokenName\"" | grep id | sed 's|.*: ||g' | sed 's|,$||');
  if [ ! -z "$oldTokenId" ]; then
    curl -X DELETE -u "$botAuth" --silent "https://api.github.com/authorizations/$oldTokenId"
  fi

}

 ## todo
githubAuthUrl="https://api.github.com/authorizations"

function resetTravisBotToken() {
  local botPassword=$1
  local tokenName=$2
  deleteBotGitHubToken "$botPassword" "$tokenName"
  
  local botAuth="$BOT_ACCOUNT:$botPassword"

  local newBotToken=$(curl --silent -d "{\"note\":\"$tokenName\", \"scopes\": [\"public_repo\"] }" \
       -u "$botAuth" $githubAuthUrl 2>&1 | grep  "\"token\": " | sed 's|.*: "||' | sed 's|",$||');
  travis env set GITHUB_PERSONAL_ACCESS_TOKEN_FOR_TRAVIS "$newBotToken"
}

function initTravis() {
  printTitle "--Setting up Travis--"
  export mapRepo=$1
  local adminToken=$2
  local botPassword=$3
  if [ -f "$mapRepo/.travis.yml" ]; then
    echo "Skipped: .travis.yml already exists"
    echo
    return
  fi
  (
   cd "$mapRepo"
   printTitle "Travis: Logging In" 
   travis login -g "$adminToken"
   travis sync

   echo
   printTitle "Travis: Setting Environment Values"
   local tokenName="automatic releases for ${ORG_NAME}/$mapRepo (tag pushes)"
   local travisValues=$(travis env -R "$ORG_NAME/$mapRepo" --org list)

   echo "$travisValues" | grep "GITHUB_PERSONAL" || resetTravisBotToken "$botPassword" "$tokenName"
   echo "$travisValues" | grep "REPO_NAME" || travis env set -P REPO_NAME "$mapRepo"
   echo "$travisValues" | grep "MAP_VERSION" || travis env set -P MAP_VERSION 0

   echo
   printTitle "Travis Init and Enable"
   "$SCRIPT_FOLDER/files/expect_scripts/travis_init.expect" "$ORG_NAME/$mapRepo"

   echo
   printTitle "Travis Init: Deleting Bot Push Tag Token"
   local priorSetupToken=$(curl --silent -u "${BOT_ACCOUNT}:${botPassword}" "${githubAuthUrl}" 2>&1 | egrep -B3 -i "name.*$mapRepo" | grep "id" | sed 's|.*: ||' | sed 's|,$||')
   if [ -z "$priorSetupToken" ]; then
     echo "Skipped: prior token did not exist"
   else
      curl -s -X DELETE -u "${BOT_ACCOUNT}:$botPassword" "https://api.github.com/authorizations/$priorSetupToken"
      echo "Deleted bot token $PRIOR_SETUP_TOKEN"
   fi

   echo
   printTitle "Travis: Setup Releases" 
   deleteBotGitHubToken "$botPassword" "automatic releases for $ORG_NAME/$mapRepo"
   "$SCRIPT_FOLDER/files/expect_scripts/travis_releases.expect" "$ORG_NAME/$mapRepo" "$BOT_ACCOUNT" "$botPassword" | tail -n +2

   echo
   printTitle "Travis: copy api key into template and commit"
   local newKey="$(grep secure .travis.yml)"
   sed "s|.*secure:.*|$newKey|" "$TRAVIS_TEMPLATE_FILE" > .travis.yml

   git add .travis.yml
   git commit .travis.yml -m 'Add map build configuration file: .travis.yml' | grep "^.master" 
  )
  echo
}


function createRemoteGitHubRepo() {
  local REPO_NAME=$1
  printTitle "Creating GitHub repository"

  local repoUrl="https://api.github.com/orgs/$ORG_NAME/repos"
  EXISTS_COUNT=$(curl --silent -H "${GITHUB_AUTH}" "${repoUrl}"?"${GITHUB_PAGE_ARGS}" |  grep -c "\"name\": \"$REPO_NAME\",$")
  
  if [ "$EXISTS_COUNT" == 0 ]; then
    echo -n "Creating "
    curl --silent -H "${GITHUB_AUTH}" ${repoUrl} -d "{ \"name\": \"$REPO_NAME\", \"private\": false}" | egrep -i "full_name|error|message" | sed 's/"//g' | sed 's/,$//g' | sed 's|^ *||'
  else
     echo "Skipped: repo already exists"
  fi
  echo
}

function initRepo() {
  local repoName=$1
  printTitle "Initializing local repo"
  (
   cd "$repoName"
   if [ ! -d ".git" ]; then
     git init
   else
     echo "Skipped: .git already exist"
   fi
 
   REMOTE_COUNT=$(git remote -v | grep -c "origin")
   if [ "$REMOTE_COUNT" == 0 ]; then
     REMOTE_ORIGIN="git@github.com:${ORG_NAME}/$repoName.git"
     git remote add origin "$REMOTE_ORIGIN"
     echo "Added remote origin ${REMOTE_ORIGIN}"
   else
     echo "Skipped: remote origin already exists"
   fi
   git fetch origin
   curl -s -H "${GITHUB_AUTH}" https://api.github.com/repos/${ORG_NAME}/"${repoName}"/branches 2>&1 | \
     grep -q "\"master\"" && git checkout master && git branch --set-upstream-to=origin/master master 
   git pull --rebase origin master
  )
  echo
}

function createReadme() {
  printTitle "Repository init with readme file"
  local repoName=$1
  if [ ! -f "$repoName/README.md" ]; then
   (
    cd "$repoName"
    echo "## $repoName" >> README.md
    git add README.md
    git commit -m 'Initial commit' 2>&1 | egrep -i "file changed"
    git push origin -u master 2>&1 &
   )
  else
    echo "Skipped: README.md already exists"
  fi
  echo
}
 
function addMapAdminTeam() {
  printTitle "Adding map admin"
  local mapRepo=$1

  MAP_ADMIN_ID=$(curl -s -H "${GITHUB_AUTH}" https://api.github.com/orgs/triplea-maps/teams 2>&1 | grep -A1 "MapAdmins" | grep id | sed 's/.*: //g' | sed 's/,$//g')
 
  if [[ ! "$MAP_ADMIN_ID" =~ [0-9]+ ]]; then
     die "Failed to correctly parse map admin ID, value parsed is: $MAP_ADMIN_ID"
  fi
  local MAP_ADMIN_TEAM_ADDED=$(curl -s -H "${GITHUB_AUTH}" "https://api.github.com/teams/${MAP_ADMIN_ID}/repos" 2>&1 | grep -c "name\": \"$mapRepo\"")


  if [ "$MAP_ADMIN_TEAM_ADDED" == 0 ]; then
    curl -X PUT -d "{\"permission\": \"push\"}" -H "${GITHUB_AUTH}" -H "Accept: application/vnd.github.ironman-preview+json" "https://api.github.com/teams/$MAP_ADMIN_ID/repos/${ORG_NAME}/$mapRepo"
    echo "Map admin team added to repository"
  else
    echo "Skipping: map admin teams already added to the repository"
  fi
  echo
}

function copyStaticFile() {
  local file=$1
  local repoName=$2
  cp "${SCRIPT_FOLDER}/files/static/$file" "$repoName"
  (
   cd "$repoName"
   git add "$file"
   git commit "$file" -m "Add project support file $file" | grep "^.master"
  )   

}

function copyStaticFiles() {
  printTitle "Copying static project files"
  local repoName=$1

  for fileName in $(ls -a "${SCRIPT_FOLDER}/files/static/" | egrep -v "^..?$"); do
    if [ ! -f "$repoName/$fileName" ]; then
       copyStaticFile "$fileName" "$repoName"
       updated=1
    else
       echo "Skipped: file already exists $fileName"
    fi
  done;

  echo
}

function runOptiPng() {
  local mapRepo=$1
  printTitle "Running optiPng ($(find $mapRepo -name "*.png" | wc -l) files)"
  parallel optipng {} 2>&1 < <(find $mapRepo -name "*.png") | grep -i "error"
  echo "Re-run optipng with fix flag to be sure we got everything"
  parallel optipng -fix {} 2>&1 < <(find $mapRepo -name "*.png") | grep -i "error"
  echo "Done"
  echo
}

function commitAndPushMapFiles() {
  local mapRepo=$1
  printTitle "Commit map files and push"
  (
   cd $mapRepo
   git add map
   git commit map -m 'add map files' | grep master
   git push origin master
  )  
  echo
}

###########


SCRIPT_FOLDER=$(curFolder)
checkFileExists "${SCRIPT_FOLDER}/files/static/build.gradle"
checkFileExists "${SCRIPT_FOLDER}/files/static/.gitattributes"
checkFileExists "${SCRIPT_FOLDER}/files/static/.gitignore"

TRAVIS_TEMPLATE_FILE="${SCRIPT_FOLDER}/files/templates/.travis.yml"
checkFileExists "$TRAVIS_TEMPLATE_FILE"
checkFileExists "${SCRIPT_FOLDER}/files/expect_scripts/travis_init.expect"
checkFileExists "${SCRIPT_FOLDER}/files/expect_scripts/travis_releases.expect"


ADMIN_TOKEN=$(head -1 "$ADMIN_TOKEN_FILE")
checkNotEmpty "$ADMIN_TOKEN"
GITHUB_AUTH="Authorization: token $ADMIN_TOKEN"
GITHUB_PAGE_ARGS="page=1&per_page=10000"

BOT_PASSWORD=$(head -1 "$BOT_PASSWORD_FILE")
checkNotEmpty "$BOT_PASSWORD"
checkValidCredentials "$ADMIN_TOKEN" "$BOT_ACCOUNT" "$BOT_PASSWORD"

export -f printTitle
export -f extractMapToNormalizedFolder

MAP_COUNT=$(find . -maxdepth 1 -name "*zip" | wc -l)
COUNT=0
find . -maxdepth 1 -name "*zip" | while read zipFile; do
 START_TIME=$(date +%s)
 COUNT=$((COUNT+1)) 
 NORMALIZED_NAME=$(normalizeName "$zipFile")
 printGreenTitle "Processing Map ($COUNT of $MAP_COUNT): $NORMALIZED_NAME"
 extractMapToNormalizedFolder "$zipFile" "$NORMALIZED_NAME/map"

 # kick off in background conversion of wav files to mp3

 createRemoteGitHubRepo "$NORMALIZED_NAME"
 initRepo "$NORMALIZED_NAME"
 createReadme "$NORMALIZED_NAME"
 printTitle "Cleaning up line endings"
 find "$NORMALIZED_NAME" -type f -not -name "*.png" -not -name "*.jpeg" -not -name "*.pdg" -not -name "*jpg" -not -name "*gif" | \
       grep -v "^$NORMALIZED_NAME/.git/" | xargs dos2unix 2>&1 | egrep -o "converting|not a regular file|No such file" | sort | uniq -c
 echo

 addMapAdminTeam "$NORMALIZED_NAME"
 initTravis "$NORMALIZED_NAME" "$ADMIN_TOKEN" "$BOT_PASSWORD"
 copyStaticFiles "$NORMALIZED_NAME"
 runOptiPng "$NORMALIZED_NAME"
 commitAndPushMapFiles "$NORMALIZED_NAME"
 printBlueTitle "<$NORMALIZED_NAME processed in $((END_TIME-START_TIME))s>"
done

END_TIME=$(date +%s)
printBlueTitle "<<Done>>"

exit 0

