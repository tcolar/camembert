//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using concurrent

**
** Sys manages references to system services
**
const class Sys : Service
{
  ** Configuration options
  const Options options := Options.load

  ** Theme
  const Theme theme := Theme.load(options.theme)
  
  ** Indexing service
  const Index index := Index(this)

  ** Application level commands
  const Commands commands := Commands(this)

  ** Top-level frame (only in UI thread)
  Frame frame() { Actor.locals["frame"] ?: throw Err("Not on UI thread") }

  ** Logger
  const Log log := Log.get("camembert")
  
  override Void onStop()
  {
    index.cache.pool.stop
    index.crawler.pool.stop
    Actor.sleep(1sec)
    index.cache.pool.kill
    index.crawler.pool.kill
  }
  
  static Void reload()
  {
    sys := Service.find(Sys#) as Sys
 sys.uninstall
    
    sys = Sys()
    sys.install  
    sys.frame.update(sys)  
  } 
}

