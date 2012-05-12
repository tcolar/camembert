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
    this.curPod = file != null ? app.index.podForFile(file) : null

    // history items
    his = makeLister(app.his)
    his.paintRightDiv = true
    add(his)

    // level 0 is pod names
    level0 = makeLister(app.index.pods)
    level0.paintRightDiv = true
    level0.paintTopDiv = true
    add(level0)

    // level 1 is pod types and files
    level1 = makeTypesAndFilesLister(curPod)
    level1.paintRightDiv = true
    add(level1)

    // level 2 types/slots in given file
    level2 = makeSlotsLister(curPod, file)
    add(level2)
  }

  private Lister makeTypesAndFilesLister(PodInfo? pod)
  {
    if (pod == null) return makeEmptyLister

    // types
    items := Obj[,]
    pod.types.each |t| { items.add(t) }

    // files organized by their directory
    if (!items.isEmpty) items.add("")
    dirs := Str:File[][:]
    pod.srcFiles.each |src|
    {
      dirPath := src.path[pod.srcDir.path.size..-2].join("/") + "/"
      if (dirPath.size == 1) dirPath = ""
      dir := dirs.getOrAdd(dirPath) { File[,] }
      dir.add(src)
    }
    dirs.keys.sort.each |dir|
    {
      if (!dir.isEmpty) items.add(dir)
      indent := dir.isEmpty ? "" : "  "
      files := dirs[dir].sort |a, b| { a.name <=> b.name }
      files.each |f| { items.add(Mark(FileRes(f), 0, 0, 0, "$indent$f.name")) }
    }
    return makeLister(items)
  }

  private Lister makeSlotsLister(PodInfo? pod, File? file)
  {
    if (pod == null || pod.types.isEmpty || file == null) return makeEmptyLister

    types := pod.types.findAll |t| { t.file == file.name }
    if (types.isEmpty) return makeEmptyLister
    types.sort |a, b| { a.line <=> b.line }

    items := Obj[,]
    multi := types.size > 1
    str := StrBuf()
    types.each |t|
    {
      items.add(t)
      str.add(t.name).add("\n")
      slots := t.slots.dup.sort |a, b| { a.line <=> b.line }
      slots.each |s|
      {
        str.add("  ").add(s.name).add("\n")
        items.add(s)
      }
    }
    if (items.isEmpty) return makeEmptyLister

    return makeLister(items, str.toStr)
  }

  private Lister makeEmptyLister() { makeLister([,]) }

  private Lister makeLister(Obj[] items, Str str := items.join("\n"))
  {
    lister := Lister(items, str)
    lister.onAction.add |e| { navTo(e.data) }
    lister.onKeyDown.add |e| { if (!e.consumed) app.controller.onKeyDown(e) }
    return lister
  }

  Void onReady(Int num)
  {
    switch (num)
    {
      case 0: his.focus
      case 1: level0.focus
      case 2: level1.focus
      case 3: level2.focus
    }
  }

  Void navTo(Obj item)
  {
    if (item is Res)      { app.load(item); return }
    if (item is Mark)     { app.goto(item); return }
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
    levelw := w / 3 - 10
    col0w := w - levelw*2

    levelx := 0
    his.bounds    = Rect(0, 0, col0w, h/2)
    level0.bounds = Rect(0, his.bounds.h, col0w, h-his.bounds.h)
    level1.bounds = Rect(level0.bounds.w, 0, levelw, h)
    level2.bounds = Rect(level1.bounds.x + level1.bounds.w, 0, levelw, h)
  }

  App app
  Res res
  PodInfo? curPod
  Lister his
  Lister level0
  Lister level1
  Lister level2
}


