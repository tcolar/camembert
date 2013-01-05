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
class Item
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
    this.file = file
    // check if this is a pod / group root first
    if(file.isDir)
    {
      g := Sys.cur.index.isGroupDir(file)
      p := Sys.cur.index.isPodDir(file)
      if(g != null)
      {
        this.dis  = g.name
        this.icon = Sys.cur.theme.iconPodGroup
        this.file = g.srcDir
        isProject = true
      }
      else if(p != null)
      {
        this.dis  = p.name
        this.icon = Sys.cur.theme.iconPod
        this.file = FileUtil.findBuildPod(p.srcDir, p.srcDir)
        isProject = true
        this.pod  = p
      }
    }
    if (f != null) f(this)
    if(! isProject)
      this.icon = collapsed ? Sys.cur.theme.iconFolderClosed : Theme.fileToIcon(file)
  }

  new makePod(PodInfo p, |This|? f := null)
  {
    this.dis  = p.name
    this.icon = Sys.cur.theme.iconPod
    this.file = FileUtil.findBuildPod(p.srcDir, p.srcDir)
    isProject = true
    this.pod  = p
    if (f != null) f(this)
  }

  new makeGroup(PodGroup g, |This|? f := null)
  {
    this.dis  = g.name
    this.icon = Sys.cur.theme.iconPodGroup
    this.file = g.srcDir
    this.group = g.name
    isProject = true
    if (f != null) f(this)
  }

  new makeType(TypeInfo t, |This|? f := null)
  {
    this.dis  = t.qname
    this.icon = Sys.cur.theme.iconType
    this.file = t.toFile
    this.line = t.line
    this.pod  = t.pod
    this.type = t
    if (f != null) f(this)
  }

  new makeSlot(SlotInfo s, |This|? f := null)
  {
    this.dis  = s.qname
    this.icon = s is FieldInfo ? Sys.cur.theme.iconField : Sys.cur.theme.iconMethod
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

  const Str dis

  Image? icon

  Space? space

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

  Bool isProject := false

  ** whether an item(folder) is collapsed
  Bool collapsed := false

  override Str toStr() { dis }

  Str debug() {"$dis $file $pod $type $slot"}

  Pos pos() { Pos(line, col) }

  ** Called when this item is left clicked
  virtual Void selected(Frame frame)
  {
    if(! file.isDir || isProject)
      frame.goto(this)
  }

  ** call when item is right clicked
  virtual Menu? popup(Frame frame)
  {
    if (file == null) return null
    // File menus
    return Menu
    {
      MenuItem
      {
        it.text = "Find in \"$file.name\""
        it.onAction.add |e|
          { (Sys.cur.commands.find as FindCmd).find(file) }
      },
      MenuItem
      {
        dir := file.isDir ? file : file.parent
        it.text = "New file in \"$dir.name\""
        it.onAction.add |e|
          { (Sys.cur.commands.newFile as NewFileCmd).newFile(dir, "NewFile.fan", frame) }
      },
      MenuItem
      {
        it.text = "Delete \"$file.name\""
        it.onAction.add |e|
        {
          (Sys.cur.commands.delete as DeleteFileCmd).delFile(file, frame)
          frame.goto(this) // refresh
        }
      },
      MenuItem
      {
        it.text = "Rename/Move \"$file.name\""
        it.onAction.add |e|
        {
          (Sys.cur.commands.move as MoveFileCmd).moveFile(file, frame)
          frame.goto(this) // refresh
        }
      },
    }
  }

}

