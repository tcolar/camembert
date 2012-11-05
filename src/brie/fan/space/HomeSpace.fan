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
** HomeSpace
**
@Serializable
const class HomeSpace : Space
{
  new make(Sys sys) : super(sys) {}

  override Str dis() { "home" }
  override Image icon() { sys.theme.iconHome }

  override Str:Str saveSession()
  {
    Str:Str[:]
  }

  static Space loadSession(Sys sys, Str:Str props)
  {
    make(sys)
  }

  override File? curFile() { null }

  override PodInfo? curPod() { null }

  override Int match(Item item) { 0 }

  override This goto(Item item) { this }

  override Widget onLoad(Frame frame)
  {
    podRoots := ItemList[,]
    pods := sys.index.pods.dup
    groups := sys.index.groups.dup
    sys.index.srcDirs.each |indexDir|
    {
      items := Item[,]
      items.add(Item(indexDir) { it.dis = FileUtil.pathDis(indexDir) })

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
    return InsetPane(0, 5, 5, 5) { grid, }
  }
  Void addPod(PodInfo p, Item[] items)
  {
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
}

