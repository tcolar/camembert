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
  const AtomicBool isScanning := AtomicBool()

  const Uri[] srcDirs

  new make(Uri[] srcDirs) : super(ActorPool())
  {
    this.srcDirs = srcDirs
    Actor.locals["camembert.projectCache"] = ProjectCache(srcDirs)
   echo("**************** cache : "+Actor.locals["camembert.projectCache"])
  }

  override Obj? receive(Obj? msg)
  {
    try
    {
      items := msg as Obj[]
      ProjectCache? c := Actor.locals["camembert.projectCache"]
      if(c == null)
      {
        c = ProjectCache(srcDirs)
        Actor.locals["camembert.projectCache"] = c
        c.scanProjects
        echo("**************** no cache ??")
        return [:]
      }
      action := items[0] as Str
echo("Action: $action")
      if(action == "index")
      {
        isScanning.val = true
        // todo: update the status bar ?
echo(">index")
        c.scanProjects
echo("<index")

        isScanning.val = false
        // todo: update the status bar ?
      }
      else if(action == "projects")
      {
        return c.projects
      }
    }catch(Err e)
    {
      Sys.cur.log.err("Project Registry thread error", e)
    }
    return null
  }

  static Uri:Project projects()
  {
    return (Uri:Project) Sys.cur.prjReg.send(["projects"]).get
  }
}

class ProjectCache
{
  FileWatcher watcher := FileWatcher()
  Uri[] rootDirs
  ** All known projects
  Uri:Project projects := [:]

  new make(Uri[] srcDirs)
  {
    rootDirs = srcDirs
  }

  ** Look for projects, return the list of new ones
  Uri:Project scanProjects(Uri[] dirs := rootDirs)
  {
    Sys.cur.log.info("Starting project scan in $dirs")
    Uri:Project newProjects := [:]
    try
    {

      // remove projects whose sources are gone
      projects = projects.findAll |prj|
      {
        return prj.dir.toFile.exists
      }

      // scan for new projects
      |Uri -> Project?|[] pluginFuncs := [,]
      Sys.cur.plugins.each {pluginFuncs.add(it.projectFinder)}

      // TODO: this will go in full dir depth and look for projects in projects
      // so might be able to do some optiizations here
      dirs.each |srcDir|
      {
        watcher.changedDirs(srcDir.toFile, 10).each |dir|
        {
          Project? prj := pluginFuncs.eachWhile {it.call(dir)}
          if(prj != null)
            newProjects[dir] = prj
        }
      }

      projects.setAll(newProjects)
    }
    catch(Err e)
    {
      Sys.cur.log.err("Project Scanning failed.", e)
    }
    Sys.cur.log.info("Found $newProjects.size projects during scan in $dirs")

    return newProjects
  }
}