//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 12  Brian Frank  Creation
//

using compilerDoc

**
** IndexCache
**
internal class IndexCache
{
  new make(Index index) { this.index = index }

  const Index index

  PodInfo[] listPods() { pods.vals.sort }

  PodInfo? pod(Str name) { pods[name] }

  PodInfo? podForFile(File file)
  {
    file = file.normalize
    return pods.find |pod|
    {
      if (pod.srcDir == null) return false
      return file.pathStr.startsWith(pod.srcDir.pathStr)
    }
  }

  Obj? addPodSrc(Str name, File srcDir)
  {
    cur := pods[name] ?: PodInfo(name, null, TypeInfo[,], null)
    pods[name] = PodInfo(name, cur.doc, cur.types, srcDir)
    return null
  }

  Obj? addPodLib(DocPod doc, TypeInfo[] types)
  {
    name := doc.name
    cur := pods[name] ?: PodInfo(name, null, TypeInfo[,], null)
    pods[name] = PodInfo(name, doc, types, cur.srcDir)
    return null
  }

  private Str:PodInfo pods := [:]
}