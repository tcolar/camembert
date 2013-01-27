//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using netColarUtils

**
** Global configuration options
**
@Serializable
const class Options
{
  ** Reload options
  static Options load(File file)
  {
    return (Options) JsonSettings.load(file, Options#)
  }

  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  @Setting{ help = ["Sources Directories to crawl"] }
  const Uri[] srcDirs := [Sys.confDir.uri]

  @Setting{ help = ["Name of theme to use (saved in config/tehmes/name.props)"] }
  const Str theme := "default"

  @Setting{ help = ["Patterns of file/directories to hide from pod navigation. Uses Pattern.match() on File full uri's to match",
                    "Examples: '.*\\.hg/.*' or '.*~'   - REQUIRES FULL RESTART to take effect"] }
  const Str[] hidePatterns := [".*\\.svn/.*", ".*\\.hg/.*", ".*\\.git/.*", ".*~"]
}

