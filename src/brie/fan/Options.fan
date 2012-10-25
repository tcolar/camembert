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
  static const File file := Env.cur.workDir + `etc/camenbert/options.fog`
  
  ** Reload options
  static Options load()
  {
    Options? options
    if (file.exists) 
    {
      try
        options = file.readObj
      catch (Err e)
        echo("ERROR: Cannot load $file\n  $e")
    }
    else
    {
      options = Options()
      options.save()
    }  
    return options
  }

  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
      fanHome = fanHomeUri.toFile.normalize
  }
  
  Void save()
  {
    file.writeObj(this)
  }

  ** Directories to crawl looking for for pod, file navigation
  const Uri[] indexDirs := [file.uri]

  ** Home directory to use for fan/build commands
  const Uri fanHomeUri := Env.cur.homeDir.uri

  ** File of `fanHomeUri`
  @Transient
  const File fanHome
  
  ** Name of theme to use (saved in etc/camembert/theme-name.fog)
  const Str theme := "default"
}

