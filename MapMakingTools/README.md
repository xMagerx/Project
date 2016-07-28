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


