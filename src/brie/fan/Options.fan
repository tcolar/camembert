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
** Configuration options
**
@Serializable
const class Options
{
  static const File standard := Env.cur.workDir + `etc/camenbert/options.props`

  ** Reload options
  static Options load(File file := standard)
  {
    return (Options) SettingUtils.load(file, Options#)
  }

  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
      fanHome = fanHomeUri.toFile.normalize
  }

  @Setting{ help = [
  "Note that you can create alternate configs: options_foo.props, options_bar.props ...",
  "",
  "Home directory to use for fan/build commands"] }
  const Uri fanHomeUri := Env.cur.homeDir.uri

  @Setting{ help = ["Sources Directories to crawl"] }
  const Uri[] srcDirs := [standard.parent.uri]

  @Setting{ help = ["Pod directories to crawl. Typically [fanHomeUri]/lib/fan/"] }
  const Uri[] podDirs := [Env.cur.homeDir.uri]

  @Setting{ help = ["Name of theme to use (saved in etc/camembert/theme-name.props)"] }
  const Str theme := "default"

  @Setting{ help = ["Patterns of file/directories to hide from pod navigation. Uses Pattern.match() on File full uri's to match",
                    "Examples: '.*\\.hg/.*' or '.*~'   - REQUIRES FULL RESTART to take effect"] }
  const Str[] hidePatterns := [".*\\.svn/.*", ".*\\.hg/.*", ".*~"]

  ** File of `fanHomeUri`
  const File fanHome
}

