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
using bocce

**
** Item represents an active item such as file or type
** that has an icon, display string, and popup
**
const class Item
{
  const Sys? sys := Service.find(Sys#) as Sys
  
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

  new makePod(PodInfo p, |This|? f := null)
  {
    this.dis  = p.name
    this.icon = sys.theme.iconPod
    this.file = p.srcDir + `build.fan`
    this.pod  = p
    if (f != null) f(this)
  }

  new makeType(TypeInfo t, |This|? f := null)
  {
    this.dis  = t.qname
    this.icon = sys.theme.iconType
    this.file = t.toFile
    this.line = t.line
    this.pod  = t.pod
    this.type = t
    if (f != null) f(this)
  }

  new makeSlot(SlotInfo s, |This|? f := null)
  {
    this.dis  = s.qname
    this.icon = s is FieldInfo ? sys.theme.iconField : sys.theme.iconMethod
    this.file = s.type.toFile
    this.line = s.line
    this.col  = 2
    this.pod  = s.type.pod
    this.type = s.type
    this.slot = s
    if (f != null) f(this)
  }

  new makeStr(Str dis) { this.dis = dis }

  new make(|This| f) { f(this) }

  static Item makeDupSpace(Item orig, Space space)
  {
    map := Field:Obj?[:]
    orig.typeof.fields.each |f| { if (!f.isStatic) map[f] = f.get(orig) }
    map[#space] = space
    return make(Field.makeSetFunc(map))
  }

  const Str dis

  const Image? icon

  const Space? space

  const File? file

  const Int line

  const Int col

  const Span? span

  const PodInfo? pod

  const TypeInfo? type

  const SlotInfo? slot

  const Bool header

  const Int indent

  override Str toStr() { dis }

  Pos pos() { Pos(line, col) }

  Menu? popup(Frame frame)
  {
    if (file == null) return null
    FindCmd findCmd := frame.sys.commands.find
    return Menu
    {
      MenuItem
      {
        it.text = "Find in \"$dis\""
        it.onAction.add |e| { findCmd.find(file) }
      },
    }
  }

}

