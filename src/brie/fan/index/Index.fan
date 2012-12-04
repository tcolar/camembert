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

**
** Index maintains listing of files and pods we've crawled
**
const class Index
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Construct with directories to crawl
  new make(Sys sys)
  {
    this.sys = sys
    dirs := File[,]
    sys.options.srcDirs.each |uri|
    {
      try
      {
        file := File(uri, false).normalize
        if (!file.exists) throw Err("Dir does not exist")
        if (!file.isDir) throw Err("Not dir")
        dirs.add(file)
      }
      catch (Err e) echo("Invalid srcDir: $uri\n  $e")
    }
    this.srcDirs = dirs
    dirs.clear
    sys.options.podDirs.each |uri|
    {
      try
      {
        file := File(uri, false).normalize
        if (!file.exists) throw Err("Dir does not exist")
        if (!file.isDir) throw Err("Not dir")
        dirs.add(file)
      }
      catch (Err e) echo("Invalid podDir: $uri\n  $e")
    }
    this.podDirs = dirs
    reindexAll
  }

  const Sys sys

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  ** Source directories to crawl and maintain synchronization
  const File[] srcDirs

  ** Pods directories to crawl and maintain synchronization
  const File[] podDirs

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
        frame := sys.frame
        if (frame.curSpace is HomeSpace) frame.reload
        else frame.updateStatus
        if(! val)  // done indexing
          frame.helpPane.indexUpdated
      }
    }
    catch {}
  }

  ** List all pods found
  PodInfo[] pods() { ((Unsafe)cache.send(Msg("pods")).get(timeout)).val }

  ** List all groups found
  PodGroup[] groups() { ((Unsafe)cache.send(Msg("groups")).get(timeout)).val }

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

  ** Rebuild the entire index asynchronously
  Void reindexAll()
  {
    cache.send(Msg("clearAll"))
    crawler.send(Msg("reindexAll"))
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

  ** Match types
  SlotInfo[] matchSlots(Str pattern, MatchKind kind := MatchKind.startsWith, Bool methodsOnly := true)
  {
    cache.send(Msg("matchSlots", pattern, kind, methodsOnly)).get(timeout)->val
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
    c := Actor.locals["cache"] as IndexCache
    if (c == null) Actor.locals["cache"] = c = IndexCache(this)

    id := msg.id
    if (id === "pods")        return Unsafe(c.listPods)
    if (id === "groups")      return Unsafe(c.listGroups)
    if (id === "pod")         return c.pod(msg.a)
    if (id === "podForFile")  return c.podForFile(msg.a)
    if (id === "groupForFile")  return c.groupForFile(msg.a)
    if (id === "matchTypes")  return Unsafe(c.matchTypes(msg.a, msg.b))
    if (id === "matchSlots")  return Unsafe(c.matchSlots(msg.a, msg.b, msg.c))
    if (id === "matchPods")  return Unsafe(c.matchPods(msg.a, msg.b))
    if (id === "matchFiles")  return Unsafe(c.matchFiles(msg.a, msg.b))
    if (id === "addPodSrc")   return c.addPodSrc(msg.a, msg.b, msg.c)
    if (id === "addPodLib")   return c.addPodLib(msg.a, msg.b, msg.c)
    if (id === "addGroup")   return c.addGroup(msg.a, msg.b)
    if (id === "clearAll")    return Actor.locals["cache"] = IndexCache(this)

    echo("ERROR: Unknown msg: $msg.id")
    throw Err("Unknown msg: $msg.id")
  }

//////////////////////////////////////////////////////////////////////////
// Crawler Actor
//////////////////////////////////////////////////////////////////////////

  private Obj? receiveCrawler(Msg msg)
  {
    try
    {
      c := Actor.locals["crawl"] as IndexCrawler
      if (c == null) Actor.locals["crawl"] = c = IndexCrawler(this)

      id := msg.id
      if (id === "reindexPod") return c.indexPod(msg.a)
      if (id === "reindexAll") return c.indexAll

      echo("ERROR: Unknown msg: $msg.id")
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