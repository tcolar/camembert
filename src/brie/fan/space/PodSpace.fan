//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt

**
** Fantom pod space
**
@Serializable
const class PodSpace : Space
{
  new make(Sys sys, Str name, File dir) : super(sys)
  {
    if (!dir.exists) throw Err("Dir doesn't exist: $dir")
    if (!dir.isDir) throw Err("Not a dir: $dir")
    this.name = name
    this.dir  = dir.normalize
  }

  const Str name

  const File dir

  override Str dis() { name }
  override Image icon() { Theme.iconFan }

  override Widget onLoad(Frame frame)
  {
    Label { text = "Pod Space: $name [$dir]" }
  }

  override Str:Str saveSession()
  {
    ["pod":name, "dir":dir.uri.toStr]
  }

  static Space loadSession(Sys sys, Str:Str props)
  {
    make(sys, props.getOrThrow("pod"),
         props.getOrThrow("dir").toUri.toFile)
  }
}

