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
  static Item[] makeFiles(File[] files)
  {
    acc := Item[,]
    files.sort |a,b| { a.name <=> b.name }
    files.each |f| { if (f.isDir) acc.add(makeFile(f)) }
    files.each |f| { if (!f.isDir) acc.add(makeFile(f)) }
    return acc
  }

  new makeFile(File file, |This|? f := null)
  {
    this.dis  = file.name + (file.isDir ? "/" : "")
    this.icon = Theme.fileToIcon(file)
    this.file = file
    if (f != null) f(this)
  }

  new makeType(TypeInfo t, |This|? f := null)
  {
    this.dis  = t.qname
    this.icon = Theme.iconType
    this.file = t.toFile
    this.line = t.line
    if (f != null) f(this)
  }

  new makeSlot(SlotInfo s, |This|? f := null)
  {
    this.dis  = s.qname
    this.icon = s is FieldInfo ? Theme.iconField : Theme.iconMethod
    this.file = s.type.toFile
    this.line = s.line
    if (f != null) f(this)
  }

  new make(|This| f) { f(this) }

  const Str dis

  const Image? icon

  const File? file

  const Int line

  const TypeInfo? type

  const Bool isHeading

  const Int indent

  override Str toStr() { dis }

}

