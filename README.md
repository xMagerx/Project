# TripleA Maps Project
- Game engine:  http://github.com/triplea-game/triplea

## How to Suggest an Update to a Map / How to Submit a Map Bug Report

* Find the map you would like changed: http://github.com/triplea-maps
* Find and click on the "issues" link, click "new", and fill out the web form that follows. It's okay to be brief, but please be specific.
* For reporting problems global to all maps, please report it in the map Project ticket queue: http://github.com/triplea-maps/Project/issues/new
* Game bugs should be reported with the game engine: http://github.com/triplea-game/triplea/issues/new

## Map Maker Setup
- [Map Maker Getting Started Page](https://github.com/triplea-maps/Project/wiki/Map-Makers:--Getting-Started-and-Workflow)
- Game engine configuration that controls which maps are available for in-game download: http://github.com/triplea-game/triplea/blob/master/triplea_yaml.xml
- How to add your map for in-game download: https://github.com/triplea-maps/Project/wiki/Update-Triplea_maps.yaml
- Jump on gitter: https://gitter.im/triplea-maps/Project
  - You can chat there about maps, map making. And also you'll hear announcements as well, and the general community chatter. If you drop off for some time, for a few weeks or a few months, then you'll need to review the docs a bit to see what you missed. At least, that is the intent. So if you have any questions, where you want to reach map makers and the map admins, you can ask them on gitter, and chances are decent they'll be answered within hours or a day. 
 
  
## Submitting Maps, and Map Zip Requirements
* Do not use spaces in file names, replace them with underscores pls.

### Step 1: Request a Github Repository for Your Map

Create a ticket here: http://github.com/triplea-maps/Project/issues/new

Subject: Please Create Map Repo: {name}
Body:
- post a link to your map zip file
or
- request that a empty shell repository be created. A shell repository will have an empty map folder where you can then use github to drag and drop your files in to create your map from scratch.

### map zip requirements
Zip all the files together, rather than zipping the folder. When you extract the zip file, you should get a mass of files. If instead you get a single folder, change directory to that folder. Zip all of the files in that folder together.

An example of zipping files together (PRs/issues with more examples are welcome):
```
## Folder my_map contains all of your map files
$ cd my_map
$ zip -r my_map.zip *
```


### Step 2: Work on your map

Once you're set up in a repository, any update to it will create automatically a new map zip folder that will be deployed to your repository 'releases' section, for example:  http://github.com/triplea-maps/tutorial/releases

** BIG NOTE: We will see about updating the game so a map clone can be loaded by the game directly: https://github.com/triplea-game/triplea/issues/703


### Step 3: Request your map to be included for in-game download</h3>

This file controls which maps are available in the game: http://github.com/triplea-game/triplea/blob/master/triplea_maps.xml

Click the pencil icon to start editing the file. Github will guide you through the process of creating  a pull request which will notify the game engine admins of the changes (note, we have map admins, and we also have game engine admins. The first are admins, the second are the game devs). 

#### To Update a PR
* If you would like to update your pull request, here the steps (in this example we will assume your github username is "Mappy"):
1. Head to your fork of triplea: https://github.com/Mappy/triplea
2. Click the branches button to view your branches: https://github.com/Mappy/triplea/branches
3. Find the branch which you used to create the PR: https://github.com/Mappy/triplea/tree/patch-1
4. Update the triplea_yaml file as normal, click it and use the pencil icon,
*profit* The update/commit of the triplea_yaml file will automatically update the PR



### Github repo change ownership option

If you would prefer, you can mimic the file structure of an existing map repo, and upload that to a repo which you own. Then in the github repository settings, there is a change ownership option which can move the repo to 'triplea-maps'. From there the map admins would set up the '.travis.yml' file to have an automated map zip build.


## For Admins - Admin Setup

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
