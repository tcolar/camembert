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
** IndexSpace
** Projects Index
**
class IndexSpace : Space
{
  override Str? plugin := null
  override Widget ui
  override View? view := null
  override Nav? nav := null
  Frame frame

  override Str dis() { "home" }
  override Image icon() { Sys.cur.theme.iconHome }

  new make(Frame frame)
  {
    this.frame = frame
    ui = InsetPane(0, 5, 5, 5) { content = makeUi }
  }

  GridPane makeUi()
  {
    prjRoots := ItemList[,]
    projects := getProjects()
    Sys.cur.srcRoots.each |indexDir|
    {
      items := Item[,]
      items.add(FileItem.makeProject(indexDir.toFile).setIcon(Sys.cur.theme.iconHome))
      items.addAll(projects.findAll {FileUtil.contains(indexDir.toFile, it.file)})
      prjRoots.add(ItemList(frame, items))
    }

    grid := GridPane
    {
      numCols = prjRoots.size
      valignCells = Valign.fill
      expandRow = 0
    }
    prjRoots.each |g| { grid.add(g) }
    return grid
  }

  override Str:Str saveSession()
  {
    Str:Str[:]
  }

  static Space loadSession(Frame frame, Str:Str props)
  {
    return IndexSpace(frame)
  }

  override File? curFile() { null }

  override Int match(FileItem item) { 0 }

  override Void goto(FileItem? item)
  {
    if(item == null) // refresh
    {
      (ui as ContentPane).content= makeUi
      ui.relayout
    }
  }

  FileItem[] getProjects()
  {
    FileItem[] items := [,]
    ProjectRegistry.projects.each |prj|
    {
      items.add(FileItem.makeProject(prj.dir.toFile).setIcon(prj.icon))
    }
    items.sort |a, b| { a.sortStr <=> b.sortStr }
    return items
  }
}

