## TripleA Maps Project

- Game engine:  http://github.com/triplea-game/triplea

### Map Maker Setup
- [Map Maker Getting Started Page](https://github.com/triplea-maps/Project/wiki/Map-Makers:--Getting-Started-and-Workflow)
- Game engine configuration that controls which maps are available for in-game download: http://github.com/triplea-game/triplea/blob/master/triplea_maps.xml
- Community map listing: http://github.com/triplea-maps

### Admin Setup

To clone everything:
```
git clone git@github.com:triplea-maps/Project.git
./Project/bin/clone_all.sh
```
Note, new map repos will take time to show up in the github CLI API, perhaps up to a day or more. 


Links:
- [Admin Maintenance Wiki Docs](http://github.com/triplea-maps/Project/wiki/Adding-a-New-Official-Map-Repository)
- [Travis Builds - http://travis-ci.org/triplea-maps](http://travis-ci.org/triplea-maps)


### Reporting map bugs, suggesting map changes

* Find the map repository hosting the map in question: http://github.com/triplea-maps
  * If you have trouble finding a map, remember that map repository names are all lower case, and have underscores instead of spaces
* Once at the repository page, say for example: "http://github.com/triplea-maps/world_at_war", look for the "issues" link and click "new". Fill out the web form, give the issue a title and add details about the problem, then click submit. Alternatively, if you know the repostory url, the new issue URL is pretty easy to type in manually: http://github.com/triplea-maps/world_at_war/issues/new
* When reporting an issue, a key is to be as specific and as consice as possible. For example, state explicity what the problem is, when it happens, and what you expected to have happened. This will make it much easier to identify and solve the problem.
* For reporting problems global to all maps, please report it in the map Project ticket queue: http://github.com/triplea-maps/Project/issues/new, or the source forge forums: http://triplea.sourceforge.net/mywiki/Forum
* Game bugs can be reported at: http://github.com/triplea-game/triplea/issues/new
