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
      items.add(FileItem.forFile(indexDir, 0, FileUtil.pathDis(indexDir), Sys.cur.theme.iconHome))
      addPluginProjects(indexDir, items)

      //addItems(indexDir, groups, pods, items)
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

  /*Void addItems(File indexDir, PodGroup[] groups, PodInfo[] pods, Item[] items, Str curGroup := "", Int ind := 0)
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
      items.add(FantomItem.forGroup(g, null, ind))
      // Now recurse for what is in this group
      addItems(g.srcDir, groups, pods, items, g.name, ind + 1)
    }
    // single pods
    podsInDir.each |p|
    {
      pods.removeSame(p)
      items.add(FantomItem.forPod(p, null, ind))
    }
  }*/

  Void addPluginProjects(File dir, Item[] items, Int ind:=0, Int depth:=0)
  {
    // look only a few levels deep to save time
    if(depth > 2)
      return

    // look for plugin projects
    item := Sys.cur.plugins.vals.eachWhile |p|
    {
      p.projectItem(dir, ind)
    }
    if(item != null)
    {
      items.add(item)
      ind++
    }
    // recurse
    dir.listDirs.sort |a, b| { a.name.lower <=> b.name.lower }.each {
      if(it.name[0]!='.')
        addPluginProjects(it, items, ind, item == null ? depth + 1 : 0)
    }
  }
}

