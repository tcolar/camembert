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

  PodGroup[] listGroups() { groups.vals.sort |g1, g2| {g1.name <=> g2.name}}

  Str:TrioInfo listTrioInfo() { trioInfo }

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

  PodGroup? groupForFile(File file)
  {
    file = file.normalize
    return groups.find |group|
    {
      return file.pathStr.startsWith(group.srcDir.pathStr)
    }
  }

  Obj? addTrioInfo(Str:TrioInfo info)
  {
    trioInfo = info
  }

  Obj? addPodSrc(Str name, File srcDir, File[] srcFiles)
  {
    cur := pods[name] ?: PodInfo(name, null, TypeInfo[,], null, File#.emptyList, null)
    if(cur.srcDir != null && cur.srcDir.uri !=  srcDir.uri)
      echo("WARNING: Ignoring second source root for pod $name : $cur.srcDir.osPath .. $srcDir.osPath")
    else
      pods[name] = PodInfo(name, cur.podFile, cur.types, srcDir, srcFiles, findGroup(srcDir))
    return null
  }

  ** If those pods are under a pod group, return it (ldeepest one)
  private PodGroup? findGroup(File srcDir)
  {
    PodGroup? result := null
    Str path := ""
    groups.vals.each
    {
       cur := it.srcDir
       if(srcDir.osPath.startsWith(cur.osPath))
       {
        if(cur.osPath.size > path.size)
        {
          path = cur.osPath
          result = it
        }
       }
    }
    return result
  }

  Obj? addPodLib(Str name, File podFile, TypeInfo[] types)
  {
    cur := pods[name] ?: PodInfo(name, null, TypeInfo[,], null, File#.emptyList, null)
    if(cur.podFile != null && cur.podFile.uri !=  podFile.uri)
      echo("WARNING: Ignoring second pod file for pod $name : $cur.podFile.osPath .. $podFile.osPath")
    else
      pods[name] = PodInfo(name, podFile, types, cur.srcDir, cur.srcFiles, null)
    return null
  }

  Obj? addGroup(File groupDir, Str? curGroup)
  {
    groups[groupDir.name] = PodGroup(groupDir, curGroup == null ? null : groups[curGroup])
    return null
  }

  PodInfo[] matchPods(Str pattern, MatchKind kind)
  {
    results := PodInfo[,]
    pods.vals.sort.each |pod|
    {
      if(match(pod.name, pattern, kind))
        results.add(pod)
    }
    return results
  }

  TypeInfo[] matchTypes(Str pattern, MatchKind kind)
  {
    results := TypeInfo[,]
    pods.vals.sort.each |pod|
    {
      pod.types.each |t|
      {
        if((pattern.contains("::") && match(t.qname, pattern, kind)) || match(t.name, pattern, kind))
          results.add(t)
      }
    }
    return results
  }

  SlotInfo[] matchSlots(Str pattern, MatchKind kind, Bool methodsOnly := true)
  {
    results := SlotInfo[,]
    pods.vals.sort.each |pod|
    {
      pod.types.each |t|
      {
        t.slots.each |s|
        {
          if((pattern.contains("::") && match(s.qname, pattern, kind)) || match(s.name, pattern, kind))
            results.add(s)
        }
      }
    }
    return results
  }

  FuncInfo[] matchFuncs(Str pattern, MatchKind kind)
  {
    results := FuncInfo[,]
    trioInfo.each |info|
    {
      info.funcs.each |func, name|
      {
        if(match(name, pattern, kind))
          results.add(func)
      }
    }
    return results.sort |a, b| {a.name <=> b.name}
  }

  TagInfo[] matchTags(Str pattern, MatchKind kind)
  {
    results := TagInfo[,]
    trioInfo.each |info|
    {
      info.tags.each |tag, name|
      {
        if(match(name, pattern, kind))
          results.add(tag)
      }
    }
    return results.sort |a, b| {a.name <=> b.name}
  }

  Item[] matchFiles(Str pattern, MatchKind kind)
  {
    results := Item[,]
    pods.vals.sort.each |pod|
    {
      pod.srcFiles.each |f|
      {
        if(match(f.name, pattern, kind))
          results.add(FileItem { it.file = f; it.dis="$pod.name::$f.name" })
      }
    }
    return results
  }

  private Bool match(Str name, Str pattern, MatchKind kind)
  {
    nm := name.lower
    p := pattern.lower
    switch(kind)
    {
      case MatchKind.exact:
        return nm == p
      case MatchKind.startsWith:
        return nm.startsWith(p)
      case MatchKind.contains:
        return nm.contains(p)
    }
    return false
  }

  private Str:PodInfo pods := [:]
  private Str:PodGroup groups := [:]
  ** Trio info / keyed by pod name
  private Str:TrioInfo trioInfo := [:]
}

enum class MatchKind
{
  exact, startsWith, contains
}