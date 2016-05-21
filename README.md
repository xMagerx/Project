## TripleA Maps Project

- Game engine:  http://github.com/triplea-game/triplea

### Map Maker Setup
- [Map Maker Getting Started Page](https://github.com/triplea-maps/Project/wiki/Map-Makers:--Getting-Started-and-Workflow)
- Game engine configuration that controls which maps are available for in-game download: http://github.com/triplea-game/triplea/blob/master/triplea_maps.xml
- Community map listing: http://github.com/triplea-maps
- How to add your map for in-game download: https://github.com/triplea-maps/Project/wiki/Update-Triplea_maps.yaml
- Once you have a map added to github, the admins will create a team that matches your github name. You'll be added to this team and given admin rights for that team (so you can add more people). That team will also be added as admin for any map which you own. 
- Finally, jump on gitter: https://gitter.im/triplea-maps/Project
  - You can chat there about maps, map making. And also you'll hear announcements as well, and the general community chatter. If you drop off for some time, for a few weeks or a few months, then you'll need to review the docs a bit to see what you missed. At least, that is the intent. So if you have any questions, where you want to reach map makers and the map admins, you can ask them on gitter, and chances are decent they'll be answered within hours or a day. 

### Reporting map bugs, suggesting map changes

* Find the map repository hosting the map in question: http://github.com/triplea-maps
  * If you have trouble finding a map, remember that map repository names are all lower case, and have underscores instead of spaces
* Once at the repository page, say for example: "http://github.com/triplea-maps/world_at_war", look for the "issues" link and click "new". Fill out the web form, give the issue a title and add details about the problem, then click submit. Alternatively, if you know the repostory url, the new issue URL is pretty easy to type in manually: http://github.com/triplea-maps/world_at_war/issues/new
* When reporting an issue, a key is to be as specific and as consice as possible. For example, state explicity what the problem is, when it happens, and what you expected to have happened. This will make it much easier to identify and solve the problem.
* For reporting problems global to all maps, please report it in the map Project ticket queue: http://github.com/triplea-maps/Project/issues/new, or the source forge forums: http://triplea.sourceforge.net/mywiki/Forum
* Game bugs can be reported at: http://github.com/triplea-game/triplea/issues/new

### Submitting Maps, and Map Zip Requirements
* If you have a map zip:
 - create an issue in this project with a link to the map zip: https://github.com/triplea-maps/Project/issues/new
* map zip requirements:
 - Do not zip the map folder, zip all of the files in one zip. Said another way, change directory into your map folder, then select all and zip that. Contract that with going up a folder and zipping up the map folder. When the zip file is extracted, there should be a lot of files and a 'games' folder at the top level. For better or worse - this is the format the engine is expecting.
 


### Admin Setup

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
