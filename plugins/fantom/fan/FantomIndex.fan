//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using concurrent
using compilerDoc
using camembert

**
** Index maintains listing of files and pods we've crawled
**
const class FantomIndex
{
  ** Whether we have done the initial pod indexing
  const AtomicBool podsIndexed := AtomicBool()

  ** Are we currently indexing
  Bool isIndexing() { isIndexingRef.val }

  ** Update indexing status
  internal Void setIsIndexing(Bool val)
  {
    isIndexingRef.val = val
    try
    {
      Desktop.callAsync |->|
      {
        frame := Sys.cur.frame
        frame.updateStatus
        if(! val)  // done indexing
        {
          frame.spaces.each
          {
            if(it is IndexSpace)
              it.refresh
          }
          frame.helpPane.indexUpdated
        }
      }
    }
    catch {}
  }

  ** List all pods found
  PodInfo[] pods() { ((Unsafe)cache.send(Msg("pods")).get(timeout)).val }

  ** List all groups found
  PodGroup[] groups() { ((Unsafe)cache.send(Msg("groups")).get(timeout)).val }

  Str:TrioInfo trioInfo() { ((Unsafe)cache.send(Msg("trioInfo")).get(timeout)).val }

  ** Find given pod
  PodInfo? pod(Str name, Bool checked := true)
  {
    PodInfo? pod := cache.send(Msg("pod", name)).get(timeout)
    if (pod == null && checked) throw UnknownPodErr(name)
    return pod
  }

  ** Find given pod
  PodInfo? podForFile(File file)
  {
    cache.send(Msg("podForFile", file)).get(timeout)
  }

  ** Find given pod
  PodGroup? groupForFile(File file)
  {
    cache.send(Msg("groupForFile", file)).get(timeout)
  }

  ** Reindex given sources / pods
  Void reindex(File[] srcDirs, File[] podDirs, Bool clearIndex := false)
  {
    if(clearIndex)
      cache.send(Msg("clearAll"))
    crawler.send(Msg("reindex", srcDirs, podDirs))
  }

  ** Rebuild index for given pod, if null no-op
  Void reindexPod(PodInfo? pod)
  {
    if (pod == null) return
    crawler.send(Msg("reindexPod", pod))
  }

  ** Match pods
  PodInfo[] matchPods(Str pattern, MatchKind kind := MatchKind.startsWith)
  {
    cache.send(Msg("matchPods", pattern, kind)).get(timeout)->val
  }

  ** Match types
  TypeInfo[] matchTypes(Str pattern, MatchKind kind := MatchKind.startsWith)
  {
    cache.send(Msg("matchTypes", pattern, kind)).get(timeout)->val
  }

  ** Match slots
  SlotInfo[] matchSlots(Str pattern, MatchKind kind := MatchKind.startsWith, Bool methodsOnly := true)
  {
    cache.send(Msg("matchSlots", pattern, kind, methodsOnly)).get(timeout)->val
  }

  ** Match funcs
  FuncInfo[] matchFuncs(Str pattern, MatchKind kind := MatchKind.startsWith)
  {
    cache.send(Msg("matchFuncs", pattern, kind)).get(timeout)->val
  }

  ** Match tags
  TagInfo[] matchTags(Str pattern, MatchKind kind := MatchKind.startsWith)
  {
    cache.send(Msg("matchTags", pattern, kind)).get(timeout)->val
  }

  ** Match files
  Item[] matchFiles(Str pattern, MatchKind kind := MatchKind.startsWith)
  {
    cache.send(Msg("matchFiles", pattern, kind)).get(timeout)->val
  }

  ** Whether this is the srcDir(root) of a pod
  ** Returns the matching pod or null if no match
  PodInfo? isPodDir(File f)
  {
    return pods.eachWhile |p|
    {
      if(p.srcDir == null)
        return null
      if(p.srcDir.normalize.uri == f.normalize.uri)
        return p
      return null
    }
  }

  ** Whether this is the srcDir(root) of a group
  ** Returns the matching group or null if no match
  PodGroup? isGroupDir(File f)
  {
    return groups.eachWhile |g|
    {
      if(g.srcDir.normalize.uri == f.normalize.uri)
        return g
      return null
    }
  }


//////////////////////////////////////////////////////////////////////////
// Cache Actor
//////////////////////////////////////////////////////////////////////////

  private Obj? receiveCache(Msg msg)
  {
    c := Actor.locals["cache"] as FantomIndexCache
    if (c == null) Actor.locals["cache"] = c = FantomIndexCache(this)

    id := msg.id
    if (id === "pods")        return Unsafe(c.listPods)
    if (id === "groups")      return Unsafe(c.listGroups)
    if (id === "pod")         return c.pod(msg.a)
    if (id === "trioInfo")    return Unsafe(c.listTrioInfo())
    if (id === "podForFile")  return c.podForFile(msg.a)
    if (id === "groupForFile")  return c.groupForFile(msg.a)
    if (id === "matchTypes")  return Unsafe(c.matchTypes(msg.a, msg.b))
    if (id === "matchSlots")  return Unsafe(c.matchSlots(msg.a, msg.b, msg.c))
    if (id === "matchFuncs")  return Unsafe(c.matchFuncs(msg.a, msg.b))
    if (id === "matchTags")  return Unsafe(c.matchTags(msg.a, msg.b))
    if (id === "matchPods")  return Unsafe(c.matchPods(msg.a, msg.b))
    if (id === "matchFiles")  return Unsafe(c.matchFiles(msg.a, msg.b))
    if (id === "addPodSrc")   return c.addPodSrc(msg.a, msg.b, msg.c)
    if (id === "addPodLib")   return c.addPodLib(msg.a, msg.b, msg.c)
    if (id === "addGroup")   return c.addGroup(msg.a, msg.b)
    if (id === "clearAll")    return Actor.locals["cache"] = FantomIndexCache(this)
    if (id === "addTrioInfo")  return c.addTrioInfo(msg.a)

    Sys.log.info("ERROR: Unknown msg: $msg.id")
    throw Err("Unknown msg: $msg.id")
  }

//////////////////////////////////////////////////////////////////////////
// Crawler Actor
//////////////////////////////////////////////////////////////////////////

  private Obj? receiveCrawler(Msg msg)
  {
    try
    {
      c := Actor.locals["crawl"] as FantomIndexCrawler
      if (c == null) Actor.locals["crawl"] = c = FantomIndexCrawler(this)

      id := msg.id
      if (id === "reindexPod") return c.indexPod(msg.a)
      if (id === "reindex") return c.reindex(msg.a, msg.b)

      Sys.log.info("ERROR: Unknown msg: $msg.id")
      throw Err("Unknown msg: $msg.id")
    }
    catch (Err e) { e.trace; throw e }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal const Duration timeout := 10sec
  internal const Actor cache   := Actor(ActorPool()) |msg| { receiveCache(msg) }
  internal const Actor crawler := Actor(ActorPool()) |msg| { receiveCrawler(msg) }
  private const AtomicBool isIndexingRef := AtomicBool()
}
