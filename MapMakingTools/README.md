## How to Request Map XML Updates
* This can be done using just your web browser:
  * Find the github map repo of the map you would like to update: https://github.com/triplea-maps
  * Click through the maps/games folder
  * Now you can edit the XML file, click the file name, and follow these instructions: http://help.github.com/articles/editing-files-in-your-repository
* This will lead to the creation of a pull request. Map admins and or map owners will review the change and will then either comment on it requesting clarification or updates, or they will merge it.

## Map Releases and Automated Zipping
* We are integrated with Travis that will watch map repositories for updates. Whenever a map repository is updated, Travis will kick and will version the map, and publish a map zip to the '/releases' section of the map repo. For example: https://github.com/triplea-maps/age_of_tribes/releases
* You should find that you no longer have to do any map zipping or unzipping.
 

## Github repo change ownership option

Create a repository in github. Use the same general layout as the other map repositories. Stage your map repo from the 'downloadedMaps' folder, here the game engine will pick it up and you can test it out and update it. Check it all in, and push it to your repository. Then in the github repository settings, look for the 'change ownership' option, and you can request for the 'triplea-maps' org to take ownership. After ownership has been transferred we would add in a ".travis" file to enable automated zipping, and we would update: https://github.com/triplea-maps/Project/blob/master/production_config/triplea_maps.yaml, to make the map live


## Local Map Testing

* Some minimal Git knowledge allows the process to be self-service
  * You need a github account: http://github.com/account
  * You need a git client tool on your local machine. An easy one that gives you a graphical user interface is [Git for windows](https://git-scm.com/download/win)
  * - [Setup your local Git email and username](http://github.com/triplea-maps/Project/wiki/Map-Makers:-Git-Username-and-Email-Setup)



### Clone a map repo
Navigate to your home folder 'triplea/downloadedMaps'. You can change that location in-game in the settings window. You may clone map repositories to this location, and the game engine will pick up and load the map. Note, clear out an existing .zip file of the same file. It can be advisable to use a new folder somewhere to hold your clones, and use the game settings to use that folder for maps.

Next, actually clone the map repo:

* Find the map repo, https://github.com/triplea-maps/
  * Fork the map if you are not an owner/admin. To fork, click through to the repo and simply click the 'fork' button
* Follow these steps to clone: https://help.github.com/articles/cloning-a-repository/#platform-windows, until it says "open git bash". To use the Git for windows user interface instead of command line, then go to section 3 of this: http://www.thegeekstuff.com/2012/02/git-for-windows/
* Note 'git bash' is git command line. You can open a git interface on any folder in windows by right clicking it and selecting the 'git gui from here' option. 



### Modify files
Now you can modify the maps files. You can add/remove, or modify any of the files and git will track the changes locally. 

### Upload Changes
Using git for windows you can add new files to "staged", you will then commit them, and then push. 
Stay tuned for some more help notes here.. Please post an issue if you find any good links/documentations: github.com/triplea-maps/Project/issues/new


## Getting More Help
- Ask questions here: github.com/triplea-maps/Project/issues/new
- Or Jump on gitter: https://gitter.im/triplea-maps/Project
  - You can chat there about maps, map making. And also you'll hear announcements as well, and the general community chatter. If you drop off for some time, for a few weeks or a few months, then you'll need to review the docs a bit to see what you missed. At least, that is the intent. So if you have any questions, where you want to reach map makers and the map admins, you can ask them on gitter, and chances are decent they'll be answered within hours or a day. 


## How are maps included with the game?

* Map description and download links are pulled from: https://github.com/triplea-maps/Project/blob/master/production_config/triplea_maps.yaml
* Please submit a PR to that file to include/update maps.


## General note - To Update a PR
* If you would like to update your pull request, here the steps (in this example we will assume your github username is "Mappy"):
1. Head to your fork of triplea: https://github.com/Mappy/triplea
2. Click the branches button to view your branches: https://github.com/Mappy/triplea/branches
3. Find the branch which you used to create the PR: https://github.com/Mappy/triplea/tree/patch-1
4. Update the triplea_yaml file as normal, click it and use the pencil icon,
*profit* The update/commit of the triplea_yaml file will automatically update the PR



## Was this confusing?
Please help clarify these notes:
* https://github.com/triplea-maps/Project/edit/master/MapMakingTools/README.md
* Pencil icon
* Edit, fix things up
* Then click save, submit a PR, Github will guide you along
 
TripleA is a community supported project. Any help with the documentation is really appreciated. If you follow these steps, pay forward to the next person and fill in missing steps and add clarifications!
