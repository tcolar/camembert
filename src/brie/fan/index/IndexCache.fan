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

  Obj? addPodSrc(Str name, File srcDir, File[] srcFiles)
  {
    cur := pods[name] ?: PodInfo(name, null, TypeInfo[,], null, File#.emptyList)
    pods[name] = PodInfo(name, cur.podFile, cur.types, srcDir, srcFiles)
    return null
  }

  Obj? addPodLib(Str name, File podFile, TypeInfo[] types)
  {
    cur := pods[name] ?: PodInfo(name, null, TypeInfo[,], null, File#.emptyList)
    pods[name] = PodInfo(name, podFile, types, cur.srcDir, cur.srcFiles)
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

  Item[] matchFiles(Str pattern, MatchKind kind)
  {
    results := Item[,]
    pods.vals.sort.each |pod|
    {
      pod.srcFiles.each |f|
      {
        if(match(f.name, pattern, kind))
          results.add(Item(f) { dis="$pod.name::$f.name" })
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
}

enum class MatchKind
{
  exact, startsWith, contains
}