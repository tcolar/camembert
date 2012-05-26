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
const class Sys
{
  ** Configuration options
  const Options options := Options.load

  ** Indexing service
  const Index index := Index(this)

  ** Application level commands
  const Commands commands := Commands(this)

  ** Top-level frame (only in UI thread)
  Frame frame() { Actor.locals["frame"] ?: throw Err("Not on UI thread") }

  ** Logger
  const Log log := Log.get("brie")
}

