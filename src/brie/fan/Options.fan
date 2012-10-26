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
  static const File file := Env.cur.workDir + `etc/camenbert/options.props`
  
  ** Reload options
  static Options load()
  {
    Options? options
    if (file.exists) 
    {
      try
        options = SettingUtils().read(Options#, file.in)
      catch (Err e)
        echo("ERROR: Cannot load $file\n  $e")
    }
    else
    {
      options = Options()
    }  
    // always save as to merge possible new settings
    SettingUtils().save(options, file.out)
    return options
  }

  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
      fanHome = fanHomeUri.toFile.normalize
  }
  
  @Setting{ help = ["Directories to crawl looking for sources, file navigation"] }
  const Uri[] indexDirs := [file.parent.uri]

  @Setting{ help = ["Home directory to use for fan/build commands"] }
  const Uri fanHomeUri := Env.cur.homeDir.uri

  @Setting{ help = ["Name of theme to use (saved in etc/camembert/theme-name.props)"] }
  const Str theme := "default"
  
  ** File of `fanHomeUri`
  const File fanHome  
}

