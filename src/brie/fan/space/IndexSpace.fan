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
    pods := Sys.cur.index.pods.dup
    groups := Sys.cur.index.groups.dup
    Sys.cur.index.srcDirs.each |indexDir|
    {
      items := Item[,]
      items.add(Item(indexDir) { it.dis = FileUtil.pathDis(indexDir) })

      addPluginProjects(indexDir, items)

      addItems(indexDir, groups, pods, items)
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

  override Int match(Item item) { 0 }

  override Void goto(Item? item)
  {
    if(item == null) // refresh
    {
      (ui as ContentPane).content= makeUi
      ui.relayout
      ui.repaint
    }
  }

  Void addItems(File indexDir, PodGroup[] groups, PodInfo[] pods, Item[] items, Str curGroup := "", Int ind := 0)
  {
    groupsInDir := groups.findAll |g|
    {
      return (g.parent?.name ?: "") == curGroup
          && FileUtil.contains(indexDir, g.srcDir)
    }
    podsInDir := pods.findAll |p|
    {
      return (p.group?.name ?: "") == curGroup
          && p.srcDir != null
          && FileUtil.contains(indexDir, p.srcDir)
    }
    // pod groups
    groupsInDir.each |g|
    {
      groups.removeSame(g)
      items.add(Item(g) {indent = ind})
      // Now recurse for what is in this group
      addItems(g.srcDir, groups, pods, items, g.name, ind + 1)
    }
    // single pods
    podsInDir.each |p|
    {
      pods.removeSame(p)
      items.add(Item(p) {indent = ind})
    }
  }

  Void addPluginProjects(File dir, Item[] items, Int ind:=0)
  {
    // look for plugin projects
    Sys.cur.plugins.vals.each |p|
    {
      item := p.projectItem(dir, ind)
      if(item != null)
        items.add(item)
    }
    // recurse
    dir.listDirs.sort |a, b| { a <=> b }
      .each {addPluginProjects(it, items, ind + 1)}
  }
}

