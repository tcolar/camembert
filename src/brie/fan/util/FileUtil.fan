//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 12  Brian Frank  Creation
//

using concurrent

**
** FileUtil
**
internal const class FileUtil
{
  static Str pathDis(File file)
  {
    names := file.path.dup
    if (names.first.endsWith(":")) names.removeAt(0)
    return "/" + names.join("/")
  }

  static Bool contains(File dir, File? x)
  {
    if (x == null) return false
    return x.normalize.uri.toStr.startsWith(dir.normalize.uri.toStr)
  }

  static Uri pathIn(File dir, File x)
  {
    x.uri.toStr[dir.uri.toStr.size..-1].toUri
  }
}