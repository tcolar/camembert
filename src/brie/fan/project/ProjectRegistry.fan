// History:
//  Jan 25 13 tcolar Creation
//

using concurrent
using netColarUtils

**
** ProjectFinder
**
const class ProjectRegistry : Actor
{

  new make(Uri[] srcDirs) : super.make(ActorPool())
  {
    Actor.locals["camembert.projectCache"] = ProjectCache(srcDirs)
  }

  override Obj? receive(Obj? msg)
  {
    items := msg as Obj[]
    action := items[0] as Str
    if(action == "index")
    {
      cache.scanProjects
    }
    else if(action == "projects")
    {
      return cache.projects
    }
    return null
  }

  private ProjectCache cache()
  {
    Actor.locals["camembert.projectCache"]
  }

  static File:Project projects()
  {
    return Sys.cur.prjReg.send("projects").get as File:Project
  }
}

class ProjectCache
{
  FileWatcher watcher := FileWatcher()
  File[] rootDirs
  ** All known projects
  File:Project projects := [:]

  new make(Uri[] srcDirs)
  {
    rootDirs := [,]
    srcDirs.each {rootDirs.add(it.toFile)}
  }

  ** Look for projects, return the list of new ones
  File:Project scanProjects(File[] dirs := rootDirs)
  {
    Sys.cur.log.info("Starting project scan in $dirs")

    // remove projects whose sources are gone
    projects = projects.findAll |prj|
    {
      return prj.item.file.exists
    }

    // scan for new projects
    |File -> Project?|[] pluginFuncs := [,]
    Sys.cur.plugins.each {pluginFuncs.add(it.projectFinder)}

    File:Project newProjects := [:]
    // TODO: this will go in full dir depth and look for projects in projects
    // so might be able to do some optiizations here
    dirs.each |srcDir|
    {
      watcher.changedDirs(srcDir, 10).each |dir|
      {
        prj := pluginFuncs.eachWhile {it.call(dir)}
        if(prj != null)
          newProjects[dir] = prj
      }
    }

    projects.setAll(newProjects)

    Sys.cur.log.info("Found $newProjects.size projects during scan in $dirs")

    return newProjects
  }
}