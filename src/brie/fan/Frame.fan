//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 May 12  Brian Frank  Creation
//

using gfx
using fwt
using concurrent

**
** Top-level frame
**
class Frame : Window
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Construct for given system
  new make(Sys sys) : super(null)
  {
    // initialize
    this.sys = sys
    Actor.locals["frame"] = this

    // eventing
    onClose.add |Event e| { e.consume; sys.commands.exit.invoke(e) }
    onKeyDown.add |e| { trapKeyDown(e) }

    // build UI
    this.spaceBar = SpaceBar(this)
    this.spacePane = ContentPane()
    this.statusBar = StatusBar(this)
    this.console   = Console(this)
    this.content = EdgePane
    {
      it.top = spaceBar
      it.center = SashPane
      {
        orientation = Orientation.vertical
        weights = [70, 30]
        spacePane,
        console,
      }
      it.bottom = statusBar
    }

    // load session and home space
    loadSession
    curSpace = spaces.first
    load(curSpace, 0)
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  ** System services
  const Sys sys

  ** Current space
  Space curSpace

  ** Current space file
  File? curFile() { curSpace.curFile }

  ** Current space pod
  PodInfo? curPod() { curSpace.curPod }

  ** If current space has loaded a view
  View? view { private set }

  ** Currently open spaces
  Space[] spaces := [,] { private set }

  ** Console
  Console console { private set }

//////////////////////////////////////////////////////////////////////////
// Space Lifecycle
//////////////////////////////////////////////////////////////////////////

  ** Select given space
  Void select(Space space)
  {
    load(space, spaceIndex(space))
  }

  ** Reload current space
  Void reload() { load(curSpace, spaceIndex(curSpace)) }

  ** Route to best open space or open new one for given item.
  Void goto(Item item)
  {
    // if this item is one of our marks, let console know
    markIndex := marks.indexSame(item)
    if (markIndex != null)
    {
      &curMark = markIndex
      console.highlight(item)
    }

    // check if current view is on item
    if (view?.file == item.file) { view.onGoto(item); return }

    // find best space to handle item, or create new one
    best := matchSpace(item)
    if (best != null)
    {
      load(best.goto(item), spaceIndex(best))
    }
    else
    {
      c := create(item)
      if (c == null) { echo("WARN: Cannot create space $item.dis"); return }
      load(c, null)
    }

    // now check if we have view to handle line/col
    if (view != null) Desktop.callAsync |->| { view.onGoto(item) }
  }

  Void closeSpace(Space space)
  {
    i := spaceIndex(space)
    if (i == 0) return
    spaces = spaces.dup { removeAt(i) }.toImmutable
    if (curSpace == space)
      curSpace = spaces.getSafe(i) ?: spaces.last
    reload
  }

  private Space? matchSpace(Item item)
  {
    // current always trumps others
    if (curSpace.match(item) > 0) return curSpace

    // find best match
    Space? bestSpace := null
    Int bestPriority := 0
    this.spaces.each |s|
    {
      priority := s.match(item)
      if (priority == 0) return
      if (priority > bestPriority) { bestSpace = s; bestPriority = priority }
    }
    return bestSpace
  }

  private Space? create(Item item)
  {
    file := item.file
    if (file == null) return null

    pod := sys.index.podForFile(file)
    if (pod != null) return PodSpace(sys, pod.name, pod.srcDir)

    dir := file.isDir ? file : file.parent
    return FileSpace(sys, dir)
  }

  ** Load current space
  private Void load(Space space, Int? index)
  {
    // confirm if we should close
    if (!confirmClose) return

    // unload current view
    try
      view?.onUnload
    catch (Err e)
      sys.log.err("View.onUnload", e)
    view = null

    // update space references
    oldSpace := curSpace
    this.curSpace = space
    if (index == null)
      this.spaces = spaces.add(space)
    else
      this.spaces = spaces.dup.set(index, space)

    // load space
    spaceBar.onLoad
    spacePane.content = space.onLoad(this)

    // see if current space content has view
    this.view = findView(spacePane.content)
    updateStatus

    // relayout
    spaceBar.relayout
    spacePane.relayout
    relayout
  }

  private static View? findView(Widget w)
  {
    if (w is View) return w
    return w.children.eachWhile |kid| { findView(kid) }
  }

  private Int spaceIndex(Space space)
  {
    spaces.indexSame(space) ?: throw Err("Space not open: $space.typeof")
  }

//////////////////////////////////////////////////////////////////////////
// Marks (build errors/finds)
//////////////////////////////////////////////////////////////////////////

  Item[] marks := Item[,]
  {
    set { &marks = it; &curMark = -1; view?.onMarks(it) }
  }

  internal Int curMark
  {
    set
    {
      if (it >= marks.size) it = marks.size - 1
      if (it < 0) it = 0
      &curMark = it
      if (!marks.isEmpty) goto(marks[it])
    }
  }

//////////////////////////////////////////////////////////////////////////
// View Lifecycle
//////////////////////////////////////////////////////////////////////////

  private Bool confirmClose()
  {
    if (view == null || !view.dirty) return true
    r := Dialog.openQuestion(this, "Save changes to $view.file.name?",
      [Dialog.yes, Dialog.no, Dialog.cancel])
    if (r == Dialog.cancel) return false
    if (r == Dialog.yes) save
    return true
  }

  Void save()
  {
    if (view == null) return
    if (view.dirty) view.onSave
    view.dirty = false
    updateStatus
  }

  internal Void updateStatus()
  {
    title := "Brie"
    if (view != null)
    {
      title += " $view.file.name"
      if (view.dirty) title += "*"
    }
    this.title = title
    this.statusBar.update
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  internal Void trapKeyDown(Event event)
  {
    cmd := sys.commands.findByKey(event.key)
    if (cmd != null) cmd.invoke(event)
  }

//////////////////////////////////////////////////////////////////////////
// Session State
//////////////////////////////////////////////////////////////////////////

  internal Void loadSession()
  {
    // read props
    props := Str:Str[:]
    try
      if (sessionFile.exists) props = sessionFile.readProps
    catch (Err e)
      sys.log.err("Cannot load session: $sessionFile", e)

    // read bounds
    this.bounds = Rect(props["frame.bounds"] ?: "100,100,600,500")

    // spaces
    spaces := Space[,]
    for (i:=0; true; ++i)
    {
      // check for "space.nn.type"
      prefix := "space.${i}."
      typeKey := "${prefix}type"
      type := props[typeKey]
      if (type == null) break

      // get all "space.nn.xxxx" props
      spaceProps := Str:Str[:]
      props.each |val, key|
      {
        if (key.startsWith(prefix))
          spaceProps[key[prefix.size..-1]] = val
      }

      // load the space from session
      try
      {
        loader := Type.find(type).method("loadSession")
        Space space := loader.callList([sys, spaceProps])
        spaces.add(space)
      }
      catch (Err e) sys.log.err("ERROR: Cannot load space $type", e)
    }

    // always insert HomeSpace
    if (spaces.first isnot HomeSpace)
      spaces.insert(0, HomeSpace(sys))

    // save spaces
    this.spaces = spaces.toImmutable
  }

  internal Void saveSession()
  {
    props := Str:Str[:]
    props.ordered = true

    // frame state
    props["saved"] = DateTime.now.toStr
    props["frame.bounds"] = this.bounds.toStr

    // spaces
    spaces.each |space, i|
    {
      props["space.${i}.type"] = space.typeof.qname
      spaceProps := space.saveSession
      spaceProps.keys.sort.each |key|
      {
        props["space.${i}.${key}"] = spaceProps.get(key)
      }
    }

    // write
    try
      sessionFile.writeProps(props)
    catch (Err e)
      sys.log.err("Cannot save $sessionFile", e)
  }

//////////////////////////////////////////////////////////////////////////
// Private Fields
//////////////////////////////////////////////////////////////////////////

  private File sessionFile := Env.cur.workDir + `etc/brie/session.props`
  private SpaceBar spaceBar
  private ContentPane spacePane
  private StatusBar statusBar
}

