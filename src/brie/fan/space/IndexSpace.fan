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
    ui = InsetPane(0, 3, 3, 3) {content = makeUi}
  }

  Widget makeUi()
  {
    prjRoots := ItemList[,]
    projects := getProjects()
    Sys.cur.srcRoots.each |indexDir|
    {
      items := FileItem[,]
      items.add(FileItem.makeProject(indexDir.toFile).setIcon(Sys.cur.theme.iconHome))
      items.addAll(
        projects.findAll {
          FileUtil.contains(indexDir.toFile, it.file)
      }.sort |a, b| {a.sortStr <=> b.sortStr})
      prjRoots.add(ItemList(frame, items))
    }
    grid := GridPane
    {
      numCols = prjRoots.size
      valignCells = Valign.fill
      expandRow = 0
    }
    prjRoots.each |g| { grid.add(g) }
    return BgEdgePane{it.left=grid}
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
    indent := 0
    Uri[] stack  := [,] // path stack
    Str[] path := [,]
    ProjectRegistry.projects.vals.sort |a, b|{a.dir.pathStr <=> b.dir.pathStr}.each |prj|
    {
      while(! (stack.isEmpty || contains(stack.peek, prj.dir)))
      {
        stack.pop
        path.pop
      }
      stack.push(prj.dir)
      path.push(prj.dir.name)
      item := FileItem.makeProject(prj.dir.toFile, stack.size).setIcon(prj.icon)
      item.dis = prj.dis
      item.sortStr = path.join("/")
      items.add(item)
    }
    return items
  }

  ** whether uri2 is "under" uri
  private Bool contains(Uri uri, Uri uri2)
  {
    return uri2.pathStr.startsWith(uri.pathStr)
  }
}


