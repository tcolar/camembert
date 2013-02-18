// History:
//  Jan 25 13 tcolar Creation
//

using concurrent
using util
using netColarUtils
using fwt

**
** ProjectRegistry
**
const class ProjectRegistry : Actor
{
  const File stateFile
  const AtomicBool isScanning := AtomicBool()

  const Uri[] srcDirs

  new make(Uri[] srcDirs, File optionsDir) : super(ActorPool())
  {
    this.srcDirs = srcDirs
    this.stateFile = optionsDir + `state/projects.fog`
  }

  override Obj? receive(Obj? msg)
  {
    try
    {
      items := msg as Obj[]
      action := items[0] as Str
      ProjectCache? c := Actor.locals["camembert.projectCache"]
      if(action == "scan")
      {
        if(c == null)
        {
          // "Lazilly" init the cache on first scan
           c = ProjectCache(srcDirs)
          Actor.locals["camembert.projectCache"] = c
        }
        newProjects := _scan(c)

        saveProjects(c) // perisst for faster startup next time

        if( ! newProjects.isEmpty)
        {
          // let the plugins know about the found projects
          PluginManager.cur.onChangedProjects(newProjects.vals)
        }

      }
      else if(action == "projects")
      {
        // If a a scan wasn't performed yet then use the saved projects
        // from a previous run for faster startups
        Uri:Project projects := [:]
        if( ! isScanning.val && c != null)
          projects = c.projects
        else
          projects = savedProjects
        return projects
      }
      else if(action == "add")
      {
        newPrj := c.addProject(items[1] as Uri)
        if(newPrj != null)
          PluginManager.cur.onChangedProjects([newPrj])
      }
      else if(action == "remove")
      {
        c.removeProject(items[1] as Uri)
      }
      else
        Sys.log.err("Unexpected project reistry thread action: $action !")
    }catch(Err e)
    {
      Sys.log.err("Project Registry thread error", e)
    }
    return null
  }

  internal Void saveProjects(ProjectCache c)
  {
    out := stateFile.out
    out.writeObj(c.projects)
    out.flush
    out.close
  }

  internal Uri:Project savedProjects()
  {
    Uri:Project projects := [:]
    try
    {
      if(stateFile.exists)
      {
        obj := stateFile.in.readObj
        if(obj != null && obj is Uri:Project)
          projects = (Uri:Project) obj
      }
    }catch(Err e)
    {
      // if loading the file fails, then remove it (either corrupt or new format)
      stateFile.delete
    }
    return projects
  }

  internal Uri:Project _scan(ProjectCache c)
  {
    Uri:Project newProjects := [:]
    setIsScanning(true)
    try
      newProjects = c.scanProjects
    finally
      setIsScanning(false)
    return newProjects
  }

  internal Void setIsScanning(Bool val)
  {
    isScanning.val = val
    try
    {
      Desktop.callAsync |->|
      {
        frame := Sys.cur.frame
        frame.updateStatus
        if( ! val)
        {
          // At end of scan, refresh the indexSpace
          refreshIndexSpace
        }
      }
    }
    catch {}
  }

  Void refreshIndexSpace()
  {
    Sys.cur.frame.spaces.each
    {
      if(it is IndexSpace)
        it.refresh
    }
  }


  static Uri:Project projects()
  {
    return (Uri:Project) Sys.cur.prjReg.send(["projects"]).get
  }

  static Uri:Project pluginProjects(Str pluginName)
  {
    return projects.findAll{it.plugin == pluginName}
  }

  ** Manually register a new project
  static Void register(Uri dir)
  {
     Sys.cur.prjReg.send(["add", dir]).get
  }

  static Void unRegister(Uri dir)
  {
     Sys.cur.prjReg.send(["remove", dir]).get
  }

  ** start a sync (asynchronous)
  static Void scan()
  {
    Sys.cur.prjReg.send(["scan"])
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
    Sys.log.info("Starting project scan in $dirs")
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

      dirs.each |srcDir|
      {
        f := srcDir.toFile
        if(f.exists && f.isDir)
        {
          watcher.changedDirs(f, 10).each |dir|
          {
            Project? prj := pluginFuncs.eachWhile {it.call(dir)}
            if(prj != null)
              newProjects[dir] = prj
          }
        }
      }

      projects.setAll(newProjects)
    }
    catch(Err e)
    {
      Sys.log.err("Project Scanning failed.", e)
    }
    Sys.log.info("Found $newProjects.size projects during scan in $dirs")

    return newProjects
  }

  Project? addProject(Uri? dir)
  {
    |Uri -> Project?|[] pluginFuncs := [,]
    Sys.cur.plugins.each {pluginFuncs.add(it.projectFinder)}
    Project? prj := pluginFuncs.eachWhile {it.call(dir)}
    if(prj != null)
      projects[dir] = prj
    return prj
  }

  Void removeProject(Uri? dir)
  {
    projects.remove(dir)
  }
}

