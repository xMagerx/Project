
## General Admin Documentation

To clone everything:
```
$ cd ~/work/maps  ## or wherever you wish to use as a working root folder
$ git clone git@github.com:triplea-maps/Project.git
$ ./Project/bin/clone_all.sh
```
Note, new map repos will take time to show up in the github CLI API, perhaps up to a day or more. 


Links:
- [Admin Maintenance Wiki Docs](http://github.com/triplea-maps/Project/wiki/Adding-a-New-Official-Map-Repository)
- [Travis Builds - http://travis-ci.org/triplea-maps](http://travis-ci.org/triplea-maps)


### Admin Map Uploads

#### Prep authentication files
- create a folder ~/.github
- create a file: ~/.github/bot_passsword, then type in the bot password as line 1
- create a file: ~/.github/token, in that file you'll add a personal access token from github:
  - head to: https://github.com/settings/profile > personal access tokens > generate new token
  - give the token a name, and the following access: ` public_repo, read:org, repo:status`
  - you'll be shown the token value, copy token value to the first line of the "token" file
- create a file ~/.github/bot_token, open a web browser in incognito/private mode, and repeat the steps above but log in as 'tripleabuilderbot', and give the token only `public_repo`


#### Stage the zip file
**Note**: Check that the zip file is zipped correclty. If a "map_name.zip" unzips to a "map_name" folder, then it was zipped 'wrong'. Unzip it, cd to the map_name folder, then rezip it with: `zip -r map_name.zip *`

I have a ~/work/maps folder where I stage/root everything. Move the map zip file in to that folder. Then you'll run `./Project/bin/createMapRepo.sh -m <map>`


Example:
```
cd ~/work/maps
mv ~/Downloads/mapZipFile.zip ./
./Project/bin/createMapRepo.sh -m mapZipFile.zip
```

Example2:

```
#TODO: document the formatting/structure of the zip file required, post those instructions to 'how to get your maps uploaded'

$ cd ~/work/maps
$ mv ~/Downloads/big_world_1939.zip ./
$ ./Project/bin/createMapRepo.sh

Usage: ./createMapRepo.sh -m <MAP>
  admin_token_file = file with one line, an an organization owner
  bot_token_file = personal access token of the github account
  bot_password_file =  file containing the password of the bot account
 -d = use defaults:
     -a ~/.github/token
     -b ~/.github/bot_token
     -p ~/.github/bot_password

$ ./Project/bin/createMapRepo.sh -m big_world_1939.zip 

```

### Admin Fix Travis - Regenerate Tokens
Each map needs two tokens on the builder bot account.
1. One that looks like this (hand created): automatic releases for triplea-maps/elemental_forces (tag pushes)
2. A second that looks like this (setup by travis ruby): automatic releases for triplea-maps/elemental_forces


To re-kick the travis token generation:
- locally find the .travis.yml file and delete everything in the 'deploy section'
- run: `travis setup releases`, use the tripleabuilderbot credentials
- Now fix up the .travis.yml file so the only thing that changes is the deploy key
- Push and verify the build works well


# Keeping maps up to date

There is a check map script which will at least inform you of out of date maps.

```
dan@dan-desk:~/work/maps/Project/production_config$ ../bin/check_map_versions.sh 

-------------------------
version check

star_wars_tatooine_war latest = (0.64) -> current = 0.56/star_wars_tatooine_war.zip
global_war latest = (0.9) -> current = 0.3/global_war.zip
total_ancient_war latest = (0.9) -> current = 0.5/total_ancient_war.zip
cold_war_asia1948 latest = (0.5) -> current = 0.3/cold_war_asia1948.zip
ultimate_world latest = (0.9) -> current = 0.3/ultimate_world.zip
pact_of_steel_variations latest = (0.9) -> current = 0.3/pact_of_steel_variations.zip
   is latest - diplomacy-map_skin2
greyhawk latest = (0.9) -> current = 0.5/greyhawk.zip
   is latest - world_war_ii_global-battlemap_skin
ur_quan_war_masters_edition latest = (0.7) -> current = 0.3/ur_quan_war_masters_edition.zip
pacific_1942 latest = (0.7) -> current = 0.3/pacific_1942.zip
feudal_japan_warlords latest = (0.11) -> current = 0.7/feudal_japan_warlords.zip
ancient_times latest = (0.9) -> current = 0.5/ancient_times.zip
world_war_ii_v6_1941 latest = (0.9) -> current = 0.3/world_war_ii_v6_1941.zip
   is latest - diplomacy-map_skin1
1914-cow-empires latest = (0.8) -> current = 0.4/1914-cow-empires.zip
```

