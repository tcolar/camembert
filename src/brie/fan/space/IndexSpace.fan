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
  override Widget ui
  override View? view := null
  override Nav? nav := null
  Frame frame

  override Str dis() { "home" }
  override Image icon() { Sys.cur.theme.iconHome }

  new make(Frame frame)
  {
    this.frame = frame
    ui = InsetPane(0, 5, 5, 5) { makeUi }
  }

  GridPane makeUi()
  {
    podRoots := ItemList[,]
    projects := getPluginProjects()

    Sys.cur.index.srcDirs.each |indexDir|
    {
      items := Item[,]
      items.add(FileItem.makeProject(indexDir).setIcon(Sys.cur.theme.iconHome))
      items.addAll(projects.findAll{FileUtil.contains(indexDir, it.file)})
      podRoots.add(ItemList(frame, items))
    }

    grid := GridPane
    {
      numCols = podRoots.size
      valignCells = Valign.fill
      expandRow = 0
    }
    podRoots.each |g| { grid.add(g) }
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

  FileItem[] getPluginProjects()
  {
    FileItem[] items := [,]
    item := Sys.cur.plugins.vals.eachWhile |p|
    {
      items.addAll(p.projects)
    }
    items.sort |a, b| { a.sortStr <=> b.sortStr }
    return items
  }
}

