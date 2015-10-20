#!/bin/bash
FAIL=0


# TODO check map versioning

function usage() {
  echo "usage: $(basename "$0") -t <token_file> -m <map_repository>"
  echo "   token: a file containing one line, a github personal access token."
  echo "   map_repository: relative path to a local map repository clone."
  exit 1
}


if [ $# == 0 ]; then
  usage
fi

while [[ $# -gt 1 ]]
do
  key="$1"
  case "$key" in
    -t|--token)
      TOKEN_FILE="$2"
      shift 2
      ;;
    -m|--map)
      MAP=${2//^\./}
      shift 2
      ;;
    *)
      echo "Unrecognized argument: $key"
      usage
      ;;
  esac
done


function checkLocalState() {
  if [ -z "$TOKEN_FILE" ]; then
    echo "Error, token parameter missing"
    usage
    exit 1
  fi

  if [ ! -f "$TOKEN_FILE" ]; then
    echo "Error, token file does not exist: $TOKEN_FILE"
    usage
    exit 1
  fi
  
  ACCESS_TOKEN=$(cat "$TOKEN_FILE")
  if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error, no token found in file: $TOKEN_FILE"
    exit 1 
  fi
  
  curl --silent -u "${ACCESS_TOKEN}:x-oauth-basic" https://api.github.com/user | grep -q login || \
      { echo "Failed to authenticate against GitHub with the admin token provided."; exit 1; }
  if [[ -z "$MAP" ]] || [[ ! -d "$MAP" ]]; then
    echo "Error, not a map folder: $MAP"
    exit 1
  fi
}


function setGlobals() {
  GITHUB_AUTH="Authorization: token $ACCESS_TOKEN"
  ORG_NAME="triplea-maps"
  MAP_ADMIN_TEAM_ID=1797261
  PAGING="?page=1&per_page=10000"
  
  GIT_FILES=".git .gitignore map .travis.yml build.gradle"
  MAP_FILES="map/place.txt map/polygons.txt map/polygons.txt map/baseTiles"
  MAP_FOLDERS="map/games"

  TRAVIS_SLUG="$ORG_NAME/$MAP"
  TRAVIS_LOGIN="travis login -g $ACCESS_TOKEN"
  EXPECTED_TRAVIS_KEYS="language jdk script before_deploy deploy provider api_key secure file skip_cleanup prerelease"
  TRAVIS_EXPECTED_ENV_VALUES="REPO_NAME=$MAP MAP_VERSION GITHUB_PERSONAL_ACCESS_TOKEN_FOR_TRAVIS"
  ZIP_MIN_KB=300
  ZIP_MAX_KB=100000
}
function fail() {
   local FAIL_MSG=$1
   echo "$MAP - FAILED - $FAIL_MSG"
   FAIL=1
}

function checkFileExists() {
  local FILE=$1

  if [ ! -e "$FILE" ]; then
    fail "File or folder missing: $FILE"
  fi
}

function checkExpectedFilesAndFoldersPresent() {
  local mapFolder=$1

  for file in $GIT_FILES $MAP_FILES $MAP_FOLDERS; do
    checkFileExists "$mapFolder/$file"
  done
}

function checkMapXml() {
  local mapFolder=$1
  
  if [ ! -d "$mapFolder/map/games" ]; then
    fail "Did not find folder $mapFolder/map/games"
  else
    ## check for at least one map xml
    local XML_COUNT=$(find "$mapFolder/map/games" -name "*.xml" | grep -c "^")
    if [ "$XML_COUNT" == 0 ]; then
      fail "Found $XML_COUNT map xmls, expected at least one in $mapFolder/map/games."
    fi

    while read xml; do
      grep "property" "$xml" | grep "\"mapName\"" | grep -q "\"$mapFolder\"" || \
          {
            fail "XML does not contain a 'mapName' property with value $mapFolder in $xml";
            echo -n "       Instead found: ";
            grep "property" "$xml" | grep "\"mapName\"" | sed 's|^ *||'
          }
    done < <(find "$mapFolder/map/games" -type f -name "*.xml")
  fi
}

function checkFolderContents() {
  local mapFolder=$1
  ### Check that local folder contains no zip folders
  local ZIP_COUNT=$(find "$mapFolder" -name "*.zip" | wc -l)
  if [ "$ZIP_COUNT" -gt 0 ]; then
    fail "Found ($ZIP_COUNT) zip files, expected zero."
  fi

}

function checkGitSetup() {
  local mapFolder=$1

  ## Check remote origin repository has been set up
  if [ -d ".git" ]; then
    local REMOTE_ORIGIN_COUNT=$(git remote -v | grep -c "^origin.*git@github.com:${ORG_NAME}/$MAP.git")
    if [ ! "$REMOTE_ORIGIN_COUNT" == 2 ]; then
      fail "Did not find two remote origins with 'git remote -v', found: $REMOTE_ORIGIN_COUNT"
    fi
  fi
}

function checkRemoteSetup() {
  local mapFolder=$1
  ## Check github org has the repository
  local GITHUB_ORG_REPO_COUNT=$(curl "https://api.github.com/orgs/${ORG_NAME}/repos?${PAGING}" 2>&1 | grep -c "full_name.*$TRAVIS_SLUG\"") 
  if [ "$GITHUB_ORG_REPO_COUNT" == 0 ]; then
    fail "GitHub - Repository does not exist with GitHub organization ${ORG_NAME}"
  fi
}

function checkGitTeams() {
  local mapFolder=$1
  
  ## Check admin team has been added to this repository
  local ADMIN_TEAM_ADDED=$(curl -H "$GITHUB_AUTH" "https://api.github.com/teams/$MAP_ADMIN_TEAM_ID/repos?${PAGING}" 2>&1 | grep -c "clone_url.*$MAP.git")
  if [ "$ADMIN_TEAM_ADDED" == 0 ]; then
    fail "GitHub Teams - Map admin team not added"
  fi

  ## Check admin team has write access to this repository
  local ADMIN_TEAM_PUSH_GRANTED=$(curl -H "$GITHUB_AUTH" "https://api.github.com/teams/1797261/repos?${PAGING}" 2>&1 | grep -A25 "clone_url.*$MAP.git" | grep -c "push.*true")

  if [ "$ADMIN_TEAM_PUSH_GRANTED" == 0 ]; then
    fail "GitHub Teams - Map admin team write access not granted"
  fi
}

function checkTravisKey() {
  local KEY_TO_CHECK=$1
  local KEY_COUNT=$(grep -c "$KEY_TO_CHECK:" .travis.yml)
  if [ "$KEY_COUNT" == 0 ]; then
     fail "Travis yml config - failed to find key $KEY_TO_CHECK"
  fi 
}

function checkTravisValue() {
  local VALUE_TO_CHECK="$1"
  local VALUE_COUNT=$(grep -c "$VALUE_TO_CHECK" .travis.yml)
  if [ "$VALUE_COUNT" == 0 ]; then
     fail "Travis yml config - failed to find exact value: $VALUE_TO_CHECK"
  fi
}

function checkTravis() {
  local mapFolder=$1

  local TRAVIS_YML_LENGTH=$(sed '/^ *$/d' "$mapFolder/.travis.yml" | grep -c "^")
  if [ -f ".travis.yml" ]; then
    if [ "$TRAVIS_YML_LENGTH" -lt 20 ]; then
      fail "Travis yml length is too short to be correct."
    else
  
      for key in $EXPECTED_TRAVIS_KEYS; do
        checkTravisKey "$key"
      done 
  
      checkTravisValue "tags: false"
      checkTravisValue "all_branches: true"
      checkTravisValue "gradle zipMap"
  
      ### check travis slug name is correct in the .git/config file
      local SLUG_COUNT=$(grep -c "slug = $TRAVIS_SLUG" .git/config)
      if [ "$SLUG_COUNT" == 0 ]; then
       fail "Travis Config - Did not find correct slug name in .git/config"
      fi
    
      ### Check travis builds for a successful build
      local PASSED=$(travis status -r "$TRAVIS_SLUG"  | grep -c "passed$")
      if [ "$PASSED" == 0 ]; then
       fail "Travis Build - Last travis build did not succeed"
      fi
    fi
  fi
}

function checkTravisEnvironmentVariables() {
  local TRAVIS_ENV=$(travis env list -r "$TRAVIS_SLUG")
  
  for envVariable in $TRAVIS_EXPECTED_ENV_VALUES; do
    local ENV_FOUND_COUNT=$(echo "$TRAVIS_ENV" | grep -c "$envVariable")
    if [ "$ENV_FOUND_COUNT" == 0 ]; then
      fail "Missing Travis Environment Variable: $envVariable"
    fi
  done
}


function compareFiles() {
  local originalFile=$1
  local releasedFile=$2

  ## echo "Do a DU file size check right here compare $originalFile to $releasedFile"

}

function checkZippedFile() {
  local mapFolder=$1
  local zippedFile=$2
  find "$mapFolder/map/$zippedFile" &> /dev/null || fail "Original file ($mapFolder/$zippedFile) does not exist, but was found in the zip release file: $zippedFile"
    
   if [[ -e "$tempFolder/$zippedFile" ]] && [[ -e "$mapFolder/map/$zippedFile" ]]; then
     local zipSize=$(du -s "$tempFolder/$zippedFile" | sed 's|\s.*$||')
     local srcSize=$(du -s "$mapFolder/map/$zippedFile" | sed 's|\s.*$||')

     if [ "$zipSize" != "$srcSize" ]; then
       fail "Differing file size between $zippedFile ($zipSize bytes), and: $mapFolder/map/$zippedFile ($srcSize bytes)"
     fi
   fi
}
export -f checkZippedFile

function checkLatestRelease() {
  local mapFolder=$1
  
  local tagCount=$(curl -s -H "$GITHUB_AUTH" "https://api.github.com/repos/triplea-maps/$mapFolder/releases" | grep -c \"tag_name\")
  if [ "$tagCount" == 0 ]; then
    fail "No tags found in: https://api.github.com/repos/triplea-maps/$mapFolder/releases"
    return
  fi 

  local latestTag=$(curl -s -H "$GITHUB_AUTH" "https://api.github.com/repos/triplea-maps/$mapFolder/releases" | grep "\"tag_name\"" | sed 's/",$//' | sed 's/.*"//g' | head -1)
  if [ -z "$latestTag" ]; then
    fail "Did not get the latest tag from https://api.github.com/repos/triplea-maps/$mapFolder/releases, are there any tags?"
    return
  fi
 
  local tempFolder=./tmp.check_map.$(date +%s)
  local zipFile="${mapFolder}.zip"
  
  wget -q -P "$tempFolder" "https://github.com/${ORG_NAME}/${mapFolder}/releases/download/${latestTag}/${zipFile}"
  if [ ! -f "${tempFolder}/${zipFile}" ]; then
    fail "Failed to download release zip file: https://github.com/${ORG_NAME}/${mapFolder}/releases/download/${latestTag}/${zipFile}"
    return
  fi

  local zipSize=$(du -s -BK "$tempFolder/$zipFile" | sed 's|K.*$||' ) 
  if [ "$zipSize" -gt "$ZIP_MAX_KB" ]; then
    fail "Zip size is: ${zipSize}K, over the limit of ${ZIP_MAX_KB}K"
  fi
  if [ "$zipSize" -lt "$ZIP_MIN_KB" ]; then
    fail "Zip size is suspiciously small: ${zipSize}K, under warning limit of ${ZIP_MIN_KB}K"
  fi


  unzip -d "$tempFolder/" "$tempFolder/$zipFile" &> /dev/null
     ## make sure we can find every file in the zipped archive somewhere back in the source, then compare file sizes
  find "$tempFolder" -type f | sed "s|^$tempFolder/||" | grep -v "^${zipFile}$" | parallel checkZippedFile "$mapFolder" "{}"
  rm -rf "$tempFolder/$zipFile"


  local zipFileCount=$(find "$tempFolder" -type f | wc -l)
  local srcFileCount=$(find "${mapFolder}/map" -type f | wc -l)
  if [ "$zipFileCount" != "$srcFileCount" ]; then
    fail "Zipped file contained $zipFileCount files but source contains $srcFileCount many files"
  fi

  rm -rf $tempFolder
}

###

checkLocalState
setGlobals
if [ -f .travis.yml ]; then
  "$TRAVIS_LOGIN"
fi
echo "-- Checking $MAP"
checkExpectedFilesAndFoldersPresent "$MAP"
checkMapXml "$MAP"
  ## TODO: check and maker sure that nothing has spaces in it..
checkFolderContents "$MAP"
checkGitSetup "$MAP"
checkRemoteSetup "$MAP"
checkGitTeams "$MAP"
checkTravis "$MAP" 
checkTravisEnvironmentVariables

checkLatestRelease "$MAP"

if [ "$FAIL" == 1 ]; then
  echo "$MAP result: FAILED" 
  exit -1
fi

echo "$MAP result: PASSED."
exit 0
