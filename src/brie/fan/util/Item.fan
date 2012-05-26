//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 May 12  Brian Frank  Creation
//

using gfx
using fwt
using concurrent

**
** Item represents an active item such as file or type
** that has an icon, display string, and popup
**
const class Item
{
  new make(|This| f) { f(this) }

  new makeFile(File file)
  {
    this.dis  = file.name + (file.isDir ? "/" : "")
    this.icon = Theme.fileToIcon(file)
    this.file = file
  }

  static Item[] makeFiles(File[] files)
  {
    acc := Item[,]
    files.sort |a,b| { a.name <=> b.name }
    files.each |f| { if (f.isDir) acc.add(makeFile(f)) }
    files.each |f| { if (!f.isDir) acc.add(makeFile(f)) }
    return acc
  }

  const Str dis

  const Image icon

  const File? file

  const Int line

  const TypeInfo? type

  override Str toStr() { dis }

}

