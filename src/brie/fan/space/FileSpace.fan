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
class FileSpace : BaseSpace
{
  override View? view
  override Nav? nav

  new make(Frame frame, File dir)
    : super(frame, FileUtil.pathDis(dir), dir)
  {
    view = View.makeBest(frame, this.file)
    nav = FancyNav(frame, dir, StdItemBuilder(this), FileItem.forFile(this.file))

    viewParent.content = view
    navParent.content = nav.list
  }

  override Image icon() { Sys.cur.theme.iconDir }

  override Str:Str saveSession()
  {
    props := ["dir": dir.uri.toStr]
    return props
  }

  static Space loadSession(Frame frame, Str:Str props)
  {
    make(frame, File(props.getOrThrow("dir").toUri, false))
  }

  override Int match(FileItem item)
  {
    if (!FileUtil.contains(this.dir, item.file)) return 0
    // if project we don't want to open them here but in a proper space
    if (item.isProject) return 0
    return this.dir.path.size
  }
}

