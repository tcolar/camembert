//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 12  Brian Frank  Creation
//

using gfx
using fwt
using bocce

**
** Bookmark
**
@Serializable
const class Bookmark
{
  static Bookmark[] load()
  {
    try
    {
      f := Env.cur.workDir + `etc/brie/bookmarks.fog`
      return (Bookmark[])f.readObj
    }
    catch (Err e) e.trace
    return Bookmark[,]
  }

  ** Constructor
  new make(|This| f) { f(this) }

  const Str dis

  const Uri uri

  override Str toStr() { dis }

  Mark toMark() { Mark(FileRes(uri.toFile), 0, 0, 0, dis) }
}

