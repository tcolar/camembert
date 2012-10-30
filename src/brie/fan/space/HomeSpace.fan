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
    podGroups := ItemList[,]
    pods := sys.index.pods.dup
    sys.index.srcDirs.each |indexDir|
    {
      items := Item[,]
      items.add(Item(indexDir) { it.dis = FileUtil.pathDis(indexDir) })
      podsInDir := pods.findAll |p|
      {
        p.srcDir != null && FileUtil.contains(indexDir, p.srcDir)
      }
      podsInDir.each |p|
      {
        pods.removeSame(p)
        items.add(Item(p))
      }
      podGroups.add(ItemList(frame, items))
    }

    grid := GridPane
    {
      numCols = podGroups.size
      valignCells = Valign.fill
      expandRow = 0
    }
    podGroups.each |g| { grid.add(g) }
    return InsetPane(0, 5, 5, 5) { grid, }
  }
}

