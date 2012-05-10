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

    // history items
    str := app.his.join("\n") |r|
    {
      try
        if (r.dis == "build.fan")
          return app.index.podForFile(r.toFile).name
      catch {}
      return r.dis
    }
    this.his = makeLister(app.his, str)

    // if file resource, then get PodInfo for file
    file := (res as FileRes)?.file
    this.curPod = file != null ? app.index.podForFile(file) : null

    // level 0 is pod names
    level0 := makeLister(app.index.pods)
    level0.paintTopDiv = true
    this.levels = [level0]

    // level 1 is pod types
    level1 := makeTypesLister(curPod)
    if (level1 != null) levels.add(level1)

    // level 2 types/slots in given file
    level2 := makeSlotsLister(curPod, file)
    if (level2 != null) levels.add(level2)

    levels.eachRange(1..-1) |level| { level.paintLeftDiv = true }
    add(his)
    levels.each |level| { add(level) }
  }

  private Lister? makeTypesLister(PodInfo? pod)
  {
    if (pod == null || pod.types.isEmpty) return null

    items := Obj[,]
    pod.types.each |t| { items.add(t) }

    return makeLister(items)
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

    return makeLister(items, str.toStr)
  }

  private Lister makeLister(Obj[] items, Str str := items.join("\n"))
  {
    lister := Lister(items, str)
    lister.onAction.add |e| { navTo(e.data) }
    lister.onKeyDown.add |e| { if (!e.consumed) app.controller.onKeyDown(e) }
    return lister
  }

  Void onReady(Int num)
  {
    if (num == 0)
      his.focus
    else
      levels.getSafe(num-1)?.focus
  }

  Void navTo(Obj item)
  {
    if (item is Res)      { app.load(item); return }
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
      levely := 0
      levelh := h
      if (i == levels.size-1) levelw = w - levelx
      if (i == 0)
      {
        his.bounds = Rect(levelx, 0, levelw, levelh/2)
        levely += his.bounds.h
        levelh = h - levely
      }
      level.bounds = Rect(levelx, levely, levelw, levelh)
      levelx += levelw
    }
  }

  App app
  Res res
  PodInfo? curPod
  Lister his
  Lister[] levels
}


