//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using concurrent
using wisp
using netColarUtils

**
** Sys manages references to system services
**
const class Sys : Service
{
  ** Shortcuts config
  const Shortcuts shortcuts := Shortcuts.load

  ** Configuration options
  const Options options

  ** Theme
  const Theme theme

  ** Indexing service
  const Index index

  ** Application level commands
  const Commands commands

  ** Logger
  const Log log := Log.get("camembert")

  const WispService docServer

  ** Top-level frame (only in UI thread)
  Frame frame() { Actor.locals["frame"] ?: throw Err("Not on UI thread") }

  new make(|This|? f)
  {
    if(f!=null) f(this)
    theme = Theme.load(options.theme)
    index = Index(this)
    commands = Commands(this)
    wPort := NetUtils.findAvailPort(8787)
    docServer = WispService { port = wPort; root = DocWebMod() }.start
    PluginManager.cur.onConfigLoaded(this)
  }

  override Void onStart()
  {
    index.reindexAll
  }

  override Void onStop()
  {
    if(docServer.isRunning)
    {
      docServer.stop
      docServer.uninstall
      index.cache.pool.stop
      index.crawler.pool.stop
      Actor.sleep(1sec)
      index.cache.pool.kill
      index.crawler.pool.kill
      echo("Sys.onStop completed.")
    }
  }

  static Void loadConfig(File config := Options.standard)
  {
    frame := Sys.cur.frame
    frame.spaces.each {Sys.cur.frame.closeSpace(it)}

    // Note : calling manually onStop to make sure it fully stops before we restart
    // because sys.stop calls it asynchronously
    Sys.cur.onStop

    Sys.cur.uninstall

    Sys sys := Sys
    {
      options = Options.load(config)
    }
    sys.start
  }

  ** Look for alternate config files (options_xyz.props)
  Str:File configs()
  {
    Str:File results := [:]
    Options.standard.parent.listFiles.each |f|
    {
      if(f.name.startsWith("options_") && f.ext =="props")
        results.add(f.basename[8 .. -1], f)
    }
    return results
  }

  Str:Plugin plugins() {PluginManager.cur.plugins}

  static Sys cur()
  {
    return (Sys) Service.find(Sys#)
  }
}

