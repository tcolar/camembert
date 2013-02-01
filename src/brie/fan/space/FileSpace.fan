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
** File system space
**
class FileSpace : FileSpaceBase
{
  new make(Frame frame, File dir, Int navWidth := 250)
    : super(frame, dir, navWidth)
  {
  }

  static Space loadSession(Frame frame, Str:Str props)
  {
    make(frame, File(props.getOrThrow("dir").toUri, false))
  }
}

