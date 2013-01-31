// History:
//  Jan 05 13 tcolar Creation
//

using gfx
using netColarUtils
using fwt
using camembert

**
** FantomPlugin
** Builtin plugin for fantom features
**
const class FantomPlugin : Plugin
{
  static const Str _name := "camFantomPlugin"

  ** FantomIndexing service
  const FantomIndex index

  override PluginCommands? commands() {FantomCommands()}
  override PluginDoc? docProvider() {FantomDoc(this)}
  override Str name() {return _name}

  new make()
  {
    index = FantomIndex()
  }

  override PluginConfig? readConfig(Sys sys)
  {
    return FantomConfig(sys)
  }

  override Void onFrameReady(Frame frame)
  {
    (frame.menuBar as MenuBar).plugins.add(FantomMenu(frame))
  }

  override Void onChangedProjects(Project[] projects, Bool clearAll := false)
  {
    File[] srcDirs := (File[])projects.map |proj -> File| {proj.dir.toFile}
    File[] podDirs := config.curEnv.podDirs.map |uri -> File| {uri.plusSlash.toFile}
    echo("chnaged projects: $projects.size $srcDirs")

    index.reindex(srcDirs, podDirs, clearAll)
  }

  override Bool isIndexing() {index.isIndexing}

  override const |Uri -> Project?| projectFinder:= |Uri uri -> Project?|
  {
    f := uri.toFile
    if( ! f.exists || ! f.isDir) return null
     // pod group
     buildFile := FantomUtils.findBuildPod(f, f)
     if(buildFile != null)
      return Project{
        it.dis = FantomUtils.getPodName(f)
        it.dir = f.uri
        it.icon = Sys.cur.theme.iconPod
        it.plugin = name
      }

     // pod
     buildFile = FantomUtils.findBuildGroup(f, f)
     if(buildFile != null)
      return Project{
        it.dis = FantomUtils.getPodName(f)
        it.dir = f.uri
        it.icon = Sys.cur.theme.iconPodGroup
        it.plugin = name
        it.params = ["isGroup" : "true"]
      }
     return null
  }

  override Space createSpace(Project prj)
  {
    return FantomSpace(Sys.cur.frame, prj.dir.toFile, null)
  }

  override Int spacePriority(Project prj)
  {
    if(prj.plugin != name)
      return 0
    // group
    if(prj.params["isGroup"] == "true")
      return 55
    //pod
    return 50
  }

  override Image? iconForFile(File file)
  {
    if(file.isDir)
    {
      pod := index.isPodDir(file)
      if(pod != null)
        return Sys.cur.theme.iconPod
      group := index.isGroupDir(file)
      if(group != null)
        return Sys.cur.theme.iconPodGroup
    }
    // fantom files handled by standard Theme code
    return null
  }

  override Void onShutdown(Bool isKill := false)
  {
    if( ! isKill)
    {
      index.cache.pool.stop
      index.crawler.pool.stop
    }
    else
    {
      index.cache.pool.kill
      index.crawler.pool.kill
    }
  }

  // Utilities
  static FantomConfig config()
  {
    return (FantomConfig) PluginManager.cur.conf(_name)
  }

  static FantomPlugin cur()
  {
    return (FantomPlugin) Sys.cur.plugin(_name)
  }

  static File? findBuildFile(File? f)
  {
    return FantomUtils.findBuildPod(f.parent, null)
  }

  static File? findBuildGroup(File? f)
  {
    return FantomUtils.findBuildGroup(f.parent, null)
  }

  static Void warnNoBuildFile(Frame frame)
  {
    Dialog.openErr(frame, "No build.fan BuildPod file found")
  }

  static Void warnNoBuildGroupFile(Frame frame)
  {
    Dialog.openErr(frame, "No build.fan / buildall.fan BuildGroup file found")
  }
}