Camembert is a lightweight Fantom IDE.

It started as a fork of Brie: `https://bitbucket.org/brianfrank/brie`

But was since cutomized quite a lot and amny features where added.

# Installation / Usage:
You need Fantom installed obviously

**Install** :
> fanr install -r http://repo.status302.com/fanr/ camembert

**Run** :
> fan camembert

First start: At the first start you will want to go in Options/edit config and edit **options.props**

You will want to at least set:

* **fanHomeUri** : Set the path to the Fan home to use for build / deploy
* **srcDirs**    : Set the directories where to find all your Fantom project sources
* **podDirs**    : Set the directories where the compiled pods are (typically /lib/fan/ under fanHomeUri)

Note that if you are going to work on the fan source code itself then you will want to run camembert witha different fantom env than fanHomeUri.

You might want to edit the other config files to your liking.

Then **Restart camembert** and you should see all your projects listed.

# Features added to Brie:
* Better default fonts and added support for support for themes (all text & colors customizable) in theme file
* Added menubar to the window to run all the commands
* Edit /reload config functionalities
* Close / Close others on SpaceBar items
* Line numbers in the editor
* Different color for num litterals in editor
* Goto command: if only 1 hit, go straight there
* Commands for Build / Run / BuildAndRun and terminating running pods
* Fandoc pane with full search / navigation capabilities
* All keyboard shortcuts are customizable
* Better separation of runtime fantom env VS deploy/index env
* Alt+Space for quicly switching between last 2 files
* New File command