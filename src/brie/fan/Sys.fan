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

  const Plugin[] plugins := [,]

  const WispService docServer

  ** Top-level frame (only in UI thread)
  Frame frame() { Actor.locals["frame"] ?: throw Err("Not on UI thread") }

  new make(|This|? f)
  {
    if(f!=null) f(this)
    theme = Theme.load(options.theme)
    index = Index(this)
    commands = Commands(this)
    docServer = WispService { port = 8787; root = DocWebMod() }.start
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
    sys := Service.find(Sys#) as Sys
    frame := sys.frame
    frame.spaces.each {sys.frame.closeSpace(it)}

    // Note : calling manually onStop to make sure it fully stops before we restart
    // because sys.stop calls it asynchronously
    sys.onStop

    sys.uninstall

    sys = Sys
    {
      options = Options.load(config)
    }
    sys.install
    frame.updateSys(sys)
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
}

mixin SysListener
{
  ** Called whne sys chnages
  abstract Void updateSys(Sys sys)
}