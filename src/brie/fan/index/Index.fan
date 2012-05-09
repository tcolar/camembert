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
  new make(Uri[] uris)
  {
    dirs := File[,]
    uris.each |uri|
    {
      try
      {
        file := uri.toFile.normalize
        if (!file.exists) throw Err("Dir does not exist")
        if (!file.isDir) throw Err("Not dir")
        dirs.add(file)
      }
      catch (Err e) echo("Invalid indextDir: $uri\n  $e")
    }
    this.dirs = dirs
    reindexAll
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  ** Directories to crawl and maintain synchronization
  const File[] dirs

  ** List all pods found
  PodInfo[] pods() { ((Unsafe)cache.send(Msg("pods")).get(timeout)).val }

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

  ** Rebuild the entire index asynchronously
  Void reindexAll()
  {
    cache.send(Msg("clearAll"))
    crawler.send(Msg("reindexAll"))
  }

  ** Match types
  TypeInfo[] matchTypes(Str pattern)
  {
    cache.send(Msg("matchTypes", pattern)).get(timeout)->val
  }

  ** Match files
  Mark[] matchFiles(Str pattern)
  {
    cache.send(Msg("matchFiles", pattern)).get(timeout)->val
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
    if (id === "pod")         return c.pod(msg.a)
    if (id === "podForFile")  return c.podForFile(msg.a)
    if (id === "matchTypes")  return Unsafe(c.matchTypes(msg.a))
    if (id === "matchFiles")  return Unsafe(c.matchFiles(msg.a))
    if (id === "addPodSrc")   return c.addPodSrc(msg.a, msg.b, msg.c)
    if (id === "addPodLib")   return c.addPodLib(msg.a, msg.b)
    if (id === "clearAll")    return Actor.locals["cache"] = IndexCache(this)

    echo("ERROR: Unknown msg: $msg.id")
    throw Err("Unknown msg: $msg.id")
  }

//////////////////////////////////////////////////////////////////////////
// Crawler Actor
//////////////////////////////////////////////////////////////////////////

  private Obj? receiveCrawler(Msg msg)
  {
    c := Actor.locals["crawl"] as IndexCrawler
    if (c == null) Actor.locals["crawl"] = c = IndexCrawler(this)

    id := msg.id
    if (id === "reindexAll") return c.indexAll

    echo("ERROR: Unknown msg: $msg.id")
    throw Err("Unknown msg: $msg.id")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal const Duration timeout := 10sec
  internal const Actor cache   := Actor(ActorUtil.pool) |msg| { receiveCache(msg) }
  internal const Actor crawler := Actor(ActorUtil.pool) |msg| { receiveCrawler(msg) }
}