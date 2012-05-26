//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx

**
** Configuration options
**
@Serializable
const class Options
{
  ** Reload options
  static Options load()
  {
    f := Env.cur.workDir + `etc/brie/options.fog`
    try
      if (f.exists) return f.readObj
    catch (Err e)
      echo("ERROR: Cannot load $f\n  $e")
    return Options()
  }

  ** Default constructor with it-block
  new make(|This|? f := null) { if (f != null) f(this) }

  ** Directories to crawl looking for for pod, file navigation
  const Uri[] indexDirs := [,]
}

