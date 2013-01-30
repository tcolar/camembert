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
using petanque

**
** Top-level frame
**
class Frame : Window
{

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

  ** Construct for given system
  new make() : super(null)
  {
    // initialize
    this.icon = Image(`fan://icons/x32/blueprints.png`)
    Actor.locals["frame"] = this

    history.pushListeners.add(
      |history| {recentPane.update(history)}
    )

    // menu
    menuBar = MenuBar()

    // eventing
    onClose.add |Event e| { e.consume; Sys.cur.commands.exit.invoke(e) }
    onKeyDown.add |e| { trapKeyDown(e) }
    onDrop = |data| { doDrop(data) }

    // build UI
    this.spaceBar = SpaceBar(this)
    this.spacePane = ContentPane()
    this.statusBar = StatusBar(this)
    this.console   = Console(this)
    this.helpPane = HelpPane(this)
    this.recentPane = RecentPane(this)
    this.content = EdgePane
    {
      it.top = spaceBar
      it.center = SashPane
      {
        orientation = Orientation.vertical
        weights = [80, 20]
        SashPane
        {
          orientation = Orientation.horizontal
          weights = [80, 20]
          spacePane,
          SashPane
          {
            orientation = Orientation.vertical
            weights = [30, 70]
            recentPane,
            helpPane,
          }
        },
        console,
      }
      it.bottom = statusBar
    }

    // load session and home space
    loadSession

    switchSpace(spaces.first)
    curSpace = spaces.first

    PluginManager.cur.onFrameReady(this)
  }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

  ** Last license template used
  Str? lastLicense

  ** Current space index
  Space curSpace

  ** Current space file
  File? curFile() { curSpace.curFile }

  ** If current space has loaded a view
  View? curView() { curSpace.view }

  ** Currently open spaces
  Space[] spaces := [,] { private set }

  ** Console
  Console console { private set }

  HelpPane helpPane { private set }

  RecentPane recentPane { private set }

  ** Navigation history
  History history := History() { private set }

  ProcessUtil process := ProcessUtil() { private set }

  //////////////////////////////////////////////////////////////////////////
  // Space Lifecycle
  //////////////////////////////////////////////////////////////////////////

  ** Select given space (upon being picked in spacebar)
  Void select(Space space)
  {
    switchSpace(space)
  }

  ** Route to best open space or open new one for given item.
  Void goto(Item? item)
  {
    if(item == null)
      return

    // if this item is one of our marks, let console know
    markIndex := marks.indexSame(item)
    if (markIndex != null)
    {
      &curMark = markIndex
      console.highlight(item)
    }

    // check if current view is on current item, if so nothing to do
    if ( !(item is FileItem) || curView?.file == (item as FileItem).file)
    {
      curView.onGoto(item)
      return
    }

    // confirm if we should close
    if (!confirmClose) return

      // save current file line number
    if (curView != null)
      filePosHis[curView.file] = curView.curPos

    // unload current view
    try
      curView?.onUnload
    catch (Err e)
      Sys.cur.log.err("View.onUnload", e)

    // Push into history
    if (item != null)
      history.push(curSpace, item)

    // find best open space to handle item
    best:= matchSpace(item)
    if (best != null)
    {
      best.goto(item)
    }
    else
    {
      // create new space
      best = create(item)
      if (best == null)
       { echo("WARN: Cannot create space $item.dis"); return }
      else
       spaces.add(best)
    }

    switchSpace(best)

    // now check if we have view to handle line/col
    if (curView != null) Desktop.callAsync |->|
    {
      if (item == null || item.loc.line <= 0)
      {
        pos := filePosHis[curView.file]
        if (pos != null) item = Item.makeLoc(pos.line, pos.col, null).setDis(pos.toStr)
      }
      if (item != null) curView.onGoto(item)
    }
  }

  Void switchSpace(Space? space)
  {
    if(space == null)
      space = spaces.first
    if(space <=> curSpace != 0)
    {
      curSpace = space
      spacePane.content = space.ui
      spacePane.relayout
      spaceBar.onLoad
      spaceBar.relayout
      updateStatus
    }
  }

  Int? spaceIndex(Space space)
  {
    return spaces.eachWhile |Space sp, Int i -> Int?|
    {
      return sp <=> space == 0 ? i : null
    }
  }

  Void closeSpace(Space space)
  {
    i := spaceIndex(space)
    if (i == null) return // home space

    spaces.removeAt(i)
    if (curSpace <=> space == 0)
    {
      space = spaces.getSafe(i) ?: spaces.last
      switchSpace(space)
    }
    else
      spaceBar.onLoad
  }

  Void closeOtherSpaces(Space space)
  {
    spaces = [spaces.first, space]
    if (curSpace <=> space != 0)
    {
      switchSpace(space)
    }
    else
      spaceBar.onLoad
  }

  Void closeSpaces()
  {
    spaces = [spaces.first]
    switchSpace(spaces.first)
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

  private Space? create(FileItem item)
  {
    if (item.space != null && ! (item.space is IndexSpace))
     return item.space

    file := item.file

    pSpace := createPluginSpace(file, 11)
    if(pSpace != null)
      return pSpace

    // if we found no spaces with prio over 10, use filespace
    dir := file.isDir ? file : file.parent
    return FileSpace(this, dir)
  }

  ** Find and create the space with the highest prio for given file
  ** If prio > minPrio return thge space istance, otherwise null
  private Space? createPluginSpace(File file, Int minPrio)
  {
  // just use project with longest path that contains this instead of pthis junk ??
  // do i still need this space prio stuff ??
    Plugin? plugin
    Project? prj

    ProjectRegistry.projects.each|project, uri|
    {
      if(FileUtil.contains(uri.toFile, file))
      {
        p := Sys.cur.plugins[project.plugin.name]
        if(p.spacePriority(project) >= minPrio)
        {
          if(plugin == null || p.spacePriority(project) > plugin.spacePriority(project))
          {
            plugin = p
            prj = project
          }
        }
      }
    }
    return plugin?.createSpace(prj)
  }

  //////////////////////////////////////////////////////////////////////////
  // Marks (build errors/finds)
  //////////////////////////////////////////////////////////////////////////

  Item[] marks := Item[,]
  {
    set { &marks = it; &curMark = -1; curView?.onMarks(it) }
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
    if (curView == null || !curView.dirty) return true
      r := Dialog.openQuestion(this, "Save changes to $curView.file.name?",
      [Dialog.yes, Dialog.no, Dialog.cancel])
    if (r == Dialog.cancel) return false
      if (r == Dialog.yes) save
      return true
  }

  Void save()
  {
    if (curView == null) return
      /*if (curView.dirty)*/ curView.onSave
      curView.dirty = false
    updateStatus
  }

  internal Void updateStatus()
  {
    title := "Camembert"
    if (curView != null)
    {
      title += " $curView.file.name"
      if (curView.dirty)
        title += "*"
    }
    this.title = title
    this.statusBar.update
  }

  //////////////////////////////////////////////////////////////////////////
  // Eventing
  //////////////////////////////////////////////////////////////////////////

  internal Void trapKeyDown(Event event)
  {
    cmd := Sys.cur.commands.findByKey(event.key)
    if (cmd != null)
    {
      cmd.invoke(event)
    }
    if(event.keyChar >= '1'
      && event.keyChar<='9'
      && event.key.modifiers.toStr == Sys.cur.shortcuts.recentModifier)
    {
       Sys.cur.commands.recent.invoke(event)
    }
  }

  private Void doDrop(Obj data)
  {
    files := data as File[]
    if (files == null || files.isEmpty) return
      file := files.first
    goto(FileItem.makeFile(file))
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
      Sys.cur.log.err("Cannot load session: $sessionFile", e)

    // read bounds
    this.bounds = Rect(props["frame.bounds"] ?: "100,100,600,500")

    this.lastLicense = props["last.license"]

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
        Space space := loader.callList([this, spaceProps])
        spaces.add(space)
      }
      catch (Err e) Sys.cur.log.err("ERROR: Cannot load space $type", e)
      }

    // always insert IndexSpace
    if (spaces.first isnot IndexSpace)
      spaces.insert(0, IndexSpace(this))

    // save spaces
    this.spaces = spaces
  }

  internal Void saveSession()
  {
    props := Str:Str[:]
    props.ordered = true

    // frame state
    props["saved"] = DateTime.now.toStr
    if(lastLicense != null)
      props["last.license"] = lastLicense
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
      Sys.cur.log.err("Cannot save $sessionFile", e)
  }

  //////////////////////////////////////////////////////////////////////////
  // Private Fields
  //////////////////////////////////////////////////////////////////////////

  private File sessionFile := Sys.cur.optionsFile.parent + `session.props`
  private SpaceBar spaceBar
  private ContentPane spacePane
  private StatusBar statusBar
  private File:Pos filePosHis := [:]
}

