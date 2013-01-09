// History:
//  Jan 05 13 tcolar Creation
//
using gfx

**
** FantomPlugin
** Builtin plugin for fantom features
**
const class FantomPlugin : Plugin
{
  override Void onInit()
  {
    // TODO create config / template if not there yet
    // TODO: init index and so on here
  }

  override Void onFrameReady(Frame frame)
  {
    // todo : start indexer etc ...
  }

  override FileItem[] projects()
  {
    FileItem[] items := [,]
    // pod groups
    Sys.cur.index.groups.each
    {
      path := groupPath(it)[0..-2]
      indent := 0 ; path.chars.each {if(it == '/') indent++}
      items.add(FileItem.makeProject(it.srcDir, indent, path).setDis(it.name))
    }
    // pods
    Sys.cur.index.pods.each
    {
      if(srcDir != null)
      {
        path := podPath(it)
        indent := 0 ; path.chars.each {if(it == '/') indent++}
        items.add(FileItem.makeProject(it.srcDir, indent, path).setDis(it.name))
      }
    }
    return items
  }

  private Str podPath(PodInfo pi)
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
  }

  override Space? createSpace(File file)
  {
    if(file.isDir)
    {
      group := Sys.cur.index.isGroupDir(file)
      if(group != null)
        return PodSpace(Sys.cur.frame, group.name, file)
      pod := Sys.cur.index.isPodDir(file)
      if(pod != null)
        return PodSpace(Sys.cur.frame, pod.name, file)
    }
    return null
  }

  override Int spacePriority(File prjDir)
  {
    if(projectItem(prjDir, 0) != null)
      return 50
    return 0
  }

  override Image? iconForFile(File file)
  {
    if(file.isDir)
    {
      pod := Sys.cur.index.isPodDir(file)
      if(pod != null)
        return Sys.cur.theme.iconPod
      group := Sys.cur.index.isGroupDir(file)
      if(group != null)
        return Sys.cur.theme.iconPodGroup
    }
    // fantom files handled by standard Theme code
    return null
  }

  override Void onShutdown()
  {
  }
}