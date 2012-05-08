//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt
using compiler

**
** Nav
**
class Nav : Pane
{

  new make(App app, Res res)
  {
    this.app = app
    this.res = res

    // if file resource, then get PodInfo for file
    file := (res as FileRes)?.file
    pod := file != null ? app.index.podForFile(file) : null

    // level 0 is pod names
    level0 := Lister(app.index.pods)
    level0.onAction.add |e| { navTo(e.data) }
    this.levels = [level0]

    // level 1 is pod types
    level1 := makeTypesLister(pod)
    if (level1 != null) levels.add(level1)

    // level 2 types/slots in given file
    level2 := makeSlotsLister(pod, file)
    if (level2 != null) levels.add(level2)

    levels.eachRange(1..-1) |level| { level.paintLeftDiv = true }
    levels.each |level| { add(level) }
  }

  private Lister? makeTypesLister(PodInfo? pod)
  {
    if (pod == null || pod.types.isEmpty) return null

    items := Obj[,]
    pod.types.each |t| { items.add(t) }

    lister := Lister(items)
    lister.onAction.add |e| { navTo(e.data) }
    return lister
  }

  private Lister? makeSlotsLister(PodInfo? pod, File? file)
  {
    if (pod == null || pod.types.isEmpty || file == null) return null

    types := pod.types.findAll |t| { t.file == file.name }
    if (types.isEmpty) return null

    items := Obj[,]
    multi := types.size > 1
    str := StrBuf()
    types.each |t|
    {
      items.add(t)
      str.add(t.name).add("\n")
      t.slots.each |s|
      {
        str.add("  ").add(s.name).add("\n")
        items.add(s)
      }
    }
    if (items.isEmpty) return null

    lister := Lister(items, str.toStr)
    lister.onAction.add |e| { navTo(e.data) }
    return lister
  }

  Void navTo(Obj item)
  {
    if (item is PodInfo)  { navToPod(item); return }
    if (item is PodInfo)  { navToPod(item); return }
    if (item is TypeInfo) { navToType(item); return }
    if (item is SlotInfo) { navToSlot(item); return }
    echo("ERR: unknown item: $item.typeof $item")
  }

  Void navToPod(PodInfo pod)
  {
    navToFile(pod, "build.fan", 0)
  }

  Void navToType(TypeInfo type)
  {
    navToFile(type.pod, type.file, type.line)
  }

  Void navToSlot(SlotInfo slot)
  {
    navToFile(slot.type.pod, slot.type.file, slot.line)
  }

  Void navToFile(PodInfo pod, Str filename, Int line := 0)
  {
    if (pod.srcDir == null || !pod.srcDir.exists)
      throw Err("Unknown srcDir for pod $pod")

    // find file
    File? file := null
    pod.srcDir.walk |f| { if (f.name == filename) file = f }
    if (file == null)
      throw Err("Cannot file file $pod::$filename")


    app.goto(Mark(FileRes(file), line, 0))
  }

  override Size prefSize(Hints hints := Hints.defVal) { Size(500, 500) }

  override Void onLayout()
  {
    w := size.w
    h := size.h
    levelw := w / 3.max(levels.size)
    levelx := 0
    levels.each |level, i|
    {
      if (i == levels.size-1) levelw = w - levelx
      level.bounds = Rect(levelx, 0, levelw, h)
      levelx += levelw
    }
  }

  App app
  Res res
  Lister[] levels
}


