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
using petanque

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
    // check if this is a pod / group root first
    if(file.isDir)
    {
      g := sys.index.isGroupDir(file)
      p := sys.index.isPodDir(file)
      if(g != null)
      {
        this.dis  = g.name
        this.icon = sys.theme.iconPodGroup
        this.file = g.srcDir
      }
      else if(p != null)
      {
        this.dis  = p.name
        this.icon = sys.theme.iconPod
        this.file = FileUtil.findBuildPod(p.srcDir, p.srcDir)
        this.pod  = p
      }
    }
    if (f != null) f(this)
  }

  new makePod(PodInfo p, |This|? f := null)
  {
    this.dis  = p.name
    this.icon = sys.theme.iconPod
    this.file = FileUtil.findBuildPod(p.srcDir, p.srcDir)

    this.pod  = p
    if (f != null) f(this)
  }

  new makeGroup(PodGroup g, |This|? f := null)
  {
    this.dis  = g.name
    this.icon = sys.theme.iconPodGroup
    this.file = g.srcDir
    this.group = g.name
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

  const Str? group

  override Str toStr() { dis }

  Str debug() {"$dis $file $pod $type $slot"}

  Pos pos() { Pos(line, col) }

  Menu? popup(Frame frame)
  {
    if (file == null) return null
    // File menus
    return Menu
    {
      MenuItem
      {
        it.text = "Find in \"$file.name\""
        it.onAction.add |e|
          { (frame.sys.commands.find as FindCmd).find(file) }
      },
      MenuItem
      {
        dir := file.isDir ? file : file.parent
        it.text = "New file in \"$dir.name\""
        it.onAction.add |e|
          { (frame.sys.commands.newFile as NewFileCmd).newFile(dir, frame) }
      },
      MenuItem
      {
        it.text = "Delete \"$file.name\""
        it.onAction.add |e|
        {
          (frame.sys.commands.delete as DeleteFileCmd).delFile(file, frame)
          frame.goto(this) // refresh
        }
      },
      MenuItem
      {
        it.text = "Rename/Move \"$file.name\""
        it.onAction.add |e|
        {
          (frame.sys.commands.move as MoveFileCmd).moveFile(file, frame)
          frame.goto(this) // refresh
        }
      },
    }
  }

}

