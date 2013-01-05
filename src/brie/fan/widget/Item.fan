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

const class Item
{
  const Str dis
  const Image? icon := null
  const ItemLoc? loc := null
  const Int indent := 0
  // space ref
  const Str? spaceId := null

  Space? space() {Sys.cur.frame.spaces.find{spaceId == buildSpaceId(it)}}

  static Str buildSpaceId(Space space) {return "$space.typeof $space?.root"}

  new make(|This|? f := null)
  {
    if(f!=null) f(this)
  }

  new makeStr(Str dis) { this.dis = dis }

  Pos pos() { Pos(loc?.line ?: 1, loc?.col ?: 0) }

  virtual Void selected(Frame frame) {}
  virtual Menu? popup(Frame frame) {return null}
}

const class ItemLoc
{
  const Int line := 1
  const Int col := 0
  const Span? span := null

  new make(|This|? f)
  {
    if(f != null) f(this)
  }
}

const class FileItem : Item
{
  const File? file
  const Bool collapsed
  const Bool isProject

  ** dDon't use directly usually
  new make(|This|? f) : super(f)
  {
  }

  static FileItem forFile(File f, Int? indent := 0, Str? dis := null, Image? icon := null)
  {
    FileItem{
      it.indent = indent
      it.file = f
      it.dis = dis ?: f.name + (f.isDir ? "/" : "")
      it.icon = icon ?: Theme.fileToIcon(f)
      it.collapsed = false
      it.isProject = false
    }
  }

  static FileItem forProject(File f, Int? indent := 0, Str? dis := null, Image? icon := null)
  {
    FileItem{
      it.icon = icon ?: Theme.fileToIcon(f)
      it.indent = indent
      it.file = f
      it.dis = dis ?: f.name + (f.isDir ? "/" : "")
      it.isProject = true
      it.collapsed = false
    }
  }

  static FileItem[] makeFiles(File[] files)
  {
    acc := Item[,]
    files.sort |a,b| { a.name <=> b.name }
    files.each |f| { if (f.isDir) acc.add(forFile(f)) }
    files.each |f| { if (!f.isDir) acc.add(forFile(f)) }
    return acc
  }

  ** Called when this item is left clicked
  override Void selected(Frame frame)
  {
    if(isProject || ! file.isDir)
      frame.goto(this)
  }

  ** call when item is right clicked
  override Menu? popup(Frame frame)
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

  static FileItem toCollapsed(FileItem item, Bool val := ! item.collapsed)
  {
    return FileItem
    {
      it.collapsed = val
      it.icon = it.collapsed ? Sys.cur.theme.iconFolderClosed : Sys.cur.theme.iconFolderOpen
      // copy
      it.file = item.file
      it.isProject = item.isProject
      it.dis = item.dis
      it.loc = item.loc
      it.indent = item.indent
      it.spaceId = item.spaceId
    }
  }
}

