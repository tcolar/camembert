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
** Fantom pod space
**
class PodSpace : BaseSpace
{
  override View? view
  override Nav? nav
  override Image icon() { isGroup ? Sys.cur.theme.iconPodGroup : Sys.cur.theme.iconPod }
  ** Whether this is a pod or a pod group
  Bool isGroup
  Widget? slots
  Str podName

  new make(Frame frame, Str name, File dir, File? file := null)
      : super(frame, name, dir, file)
  {
    this.podName = name
    this.isGroup = Sys.cur.index.isGroupDir(dir) != null

    view = View.makeBest(frame, this.file)
    nav = FancyNav(frame, dir, Item(this.file))
    slots = makeSlotNav

    viewParent.content = view
    navParent.content = nav.items
    slotsParent.content = slots
  }


  PodInfo? curPod() { Sys.cur.index.pod(podName, false) }

  TypeInfo? curType()
  {
    pod := curPod
    if (pod == null) return null
      types := pod.types.findAll |t| { t.file == file.name }
    if (types.size == 0) return null
      if (types.size == 1) return types.first
      types.sort |a, b| { a.line <=> b.line }
    curLine := Sys.cur.frame.curView?.curPos?.line ?: 0
    for (i := 1; i<types.size; ++i)
      if (types[i].line > curLine) return types[i-1]
      return types.first
  }

  override Str:Str saveSession()
  {
    ["pod":podName, "dir":dir.uri.toStr, "file":file.uri.toStr]
  }

  static Space loadSession(Frame frame, Str:Str props)
  {
    make(frame, props.getOrThrow("pod"),
      props.getOrThrow("dir").toUri.toFile,
      props.get("file")?.toUri?.toFile)
  }

  override Item[] findGotoMatches(Str text)
  {
    Item[] acc := [,]

    /// slots in current type
    if (curType != null)
    {
      curType.slots.each |s|
      {
        if (s.name.startsWith(text)) acc.add(Item(s) { it.dis = s.name })
        }
    }

    // match types
    if (!text.isEmpty)
      acc.addAll(Sys.cur.index.matchTypes(text).map |t->Item| { Item(t) })

    // f <file>
    if (text.startsWith("f ") && text.size >= 3)
      acc.addAll(Sys.cur.index.matchFiles(text[2..-1]))

    // all matching slots from other types
    acc.addAll(Sys.cur.index.matchSlots(text)
      .findAll |s| {s.type.qname != curType?.qname}
      .findAll |s| {s.name.size>0 && text.size>0 && s.name[0] == text[0]}
      .map |s->Item| { Item(s) })

    return acc
  }

  override Int match(Item item)
  {
    // add 1000 so always preferred over filespace
    // use length so the "Deepest" (sub)pod matches first
    if (!FileUtil.contains(this.dir, item.file)) return 0
    // Pods from groups should open in own space
    if(isGroup && item.pod != null) return 0
    return 1000 + dir.pathStr.size
  }

  private Widget? makeSlotNav()
  {
    if (file.ext != "fan") return null
    pod := Sys.cur.index.pod(this.podName, false)
    if (pod == null) return null

    types := pod.types.findAll |t| { return t.file == file.name }

    if (types.isEmpty) return null

    items := Item[,]
    types.sort |a, b| { a.line <=> b.line }
    types.each |t|
    {
      items.add(Item(t) { it.dis = t.name } )
      slots := t.slots.dup.sort |a, b| { a.name <=> b.name }
      slots.each |s|
      {
        items.add(Item(s) { it.dis = s.name; it.indent = 1 })
      }
    }
    return ItemList(frame, items, 175)
  }

  ** Go to the given item. (in Editor & Nav)
  override Void goto(Item? item)
  {
    super.goto(item)

    // Update slot nav ?
    newSlots := makeSlotNav()
    slotsParent.content = newSlots
    newSlots?.repaint
  }
}

