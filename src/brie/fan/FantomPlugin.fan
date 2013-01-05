// History:
//  Jan 05 13 tcolar Creation
//

**
** FantomPlugin
** Builtin plugin for fantom features
**
const class FantomPlugin : Plugin
{
  override Void onInit()
  {
    // TODO create config / template if not there yet
  }

  override Void onFrameReady(Frame frame)
  {
    // todo : start indexer etc ...
  }

  override Space? createSpace(File file)
  {
    group := Sys.cur.index.isGroupDir(file)
    if(group != null)
      return PodSpace(Sys.cur.frame, group.name, file)
    pod := Sys.cur.index.isPodDir(file)
    if(pod != null)
      return PodSpace(Sys.cur.frame, pod.name, file)
    return null
  }

  override Int? spacePriority() { 50 }

  override Item? projectItem(File file, Int indent)
  {
    if(file.isDir)
    {
      group := Sys.cur.index.isGroupDir(file)
      if(group != null)
        return FantomItem.forGroup(group, null, indent)
      pod := Sys.cur.index.isPodDir(file)
      if(pod != null)
        return FantomItem.forPod(pod, null, indent)
      // fantom files handled by standard code
    }
    return null
  }

  override Void onShutdown()
  {
  }
}