// History:
//  Jan 05 13 tcolar Creation
//

using gfx
using netColarUtils

**
** FantomPlugin
** Builtin plugin for fantom features
**
const class FantomPlugin : Plugin
{
  ** FantomIndexing service
  const FantomIndex index := FantomIndex()

  override PluginConfig? readConfig(Sys sys)
  {
    index.reindexAll

    return FantomConfig(sys)
  }

  override Void onInit(File configDir)
  {
    // TODO: init index and so on here
  }

  override Void onFrameReady(Frame frame)
  {
    // todo : start indexer etc ...
  }

  /*override FileItem[] projects()
  {
    FileItem[] items := [,]
    // pod groups
    index.groups.each
    {
      path := groupPath(it)[0..-2]
      indent := 0 ; path.chars.each {if(it == '/') indent++}
      items.add(FileItem.makeProject(it.srcDir, indent, path).setDis(it.name))
    }
    // pods
    index.pods.each
    {
      if(srcDir != null)
      {
        path := podPath(it)
        indent := 0 ; path.chars.each {if(it == '/') indent++}
        items.add(FileItem.makeProject(it.srcDir, indent, path).setDis(it.name))
      }
    }
    return items
  }*/

 /* private Str podPath(PodInfo pi)
  {
    return groupPath(pi.group) + pi.name
  }

  private Str groupPath(PodGroup? group)
  {
    path := ""
    while(group != null)
    {
      path = "${group.name}/$path"
      group = group.parent
    }
    return path
  }*/

  override |File -> Project?| projectFinder := |File f -> Project?|
  {
     if( ! f.exists || ! f.isDir) return null
     // pod group
     buildFile := FantomUtils.findBuildGroup(f, f)
     if(buildFile != null)
      return Project{
        it.item = FileItem.makeProject(f)
        it.item.icon = Sys.cur.theme.iconPodGroup
        it.plugin = FantomPlugin#
        it.params = ["isGroup" : "true"]
      }
     // pod
     buildFile = FantomUtils.findBuildPod(f, f)
     if(buildFile != null)
      return Project{
        it.item = FileItem.makeProject(f)
        it.item.icon = Sys.cur.theme.iconPod
        it.plugin = FantomPlugin#
      }

     return null
  }

  override Space createSpace(Project prj)
  {
    if(prj.plugin != FantomPlugin#)
      return null
    return FantomSpace(Sys.cur.frame, prj.item.dis, prj.item.file, null)
  }

  override Int spacePriority(Project prj)
  {
    if(prj.plugin != FantomPlugin#)
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

  static FantomConfig config()
  {
    return PluginManager.cur.conf(FantomPlugin#.pod.name) as FantomConfig
  }

  static FantomPlugin cur()
  {
    return Sys.plugin(FantomPlugin#) as FantomPlugin
  }
}