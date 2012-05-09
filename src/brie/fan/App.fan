//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt
using concurrent

**
** App is the top-most frame that manages it all
**
class App
{
  new make(Options options)
  {
    this.options    = options
    this.index      = Index(options.indexDirs)
    this.res        = FileRes(`/skyspark/src/skyspark/fan/Filter.fan`.toFile)
    this.view       = res.makeView(this)
    this.nav        = Nav(this, res)
    this.console    = Console(this)
    this.controller = AppController(this)
    this.window     = Window
    {
      title   = "Brie"
      icon    = Image(`fan://icons/x32/blueprints.png`)
      bounds  = Rect(70, 0, 1800, 1080)
      content = Label { text = "initializing..." }
      onKeyDown.add |e| { controller.onKeyDown(e) }
      it->onDrop = |data| { controller.onDrop(data) }  // use back-door hook for file drop
    }
    load(res)
  }

  Void reload() { load(res) }

  Void goto(Mark mark)
  {
    // check if we need to reload file
    if (mark.res != null && mark.res != res)
      load(mark.res)

    // goto specific line, col
    Desktop.callAsync |->| { view.onGoto(mark) }
  }

  Void load(Res res)
  {
    if (!confirmClose) return
    try
    {
      this.res     = res
      this.nav     = Nav(this, res)
      this.view    = res.makeView(this)
      this.console = Console(this)

      window.content = AppPane(this)
      window.relayout
      window.title = "Brie $res.uri"
    }
    catch (Err e)
    {
      load(ErrRes(res.uri, "Cannot load resource", e.trace))
    }
  }

  private Bool confirmClose()
  {
    if (!view.dirty) return true
    r := Dialog.openQuestion(window, "Save changes to $res.dis?",
      [Dialog.yes, Dialog.no, Dialog.cancel])
    if (r == Dialog.cancel) return false
    if (r == Dialog.yes) save
    return true
  }

  Void save()
  {
    if (view.dirty) view.onSave
    view.dirty = false
    window.title = "Brie $res.uri"
  }

  Void build()
  {
    save
    console.run("b")
  }

  Mark[] marks := Mark[,]
  {
    set { &marks = it; &curMark = -1; view.onMarks(it) }
  }

  internal Int curMark
  {
    set
    {
      if (it >= marks.size) it = marks.size - 1
      if (it < 0) it = 0
      &curMark = it
      console.onCurMark(marks[it])
      if (!marks.isEmpty) goto(marks[it])
    }
  }

  Window window { private set }
  Options options { private set }
  View view { private set }
  Res res { private set }
  Index index { private set }
  Nav nav { private set }
  Console console { private set }
  internal AppController controller { private set }
}

internal class AppPane : Pane
{
  new make(App app)
  {
    this.app = app
    add(app.nav)
    add(app.view)
    add(app.console)
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    Size(500, 500)
  }

  override Void onLayout()
  {
    w := size.w
    h := size.h

    navw := 500.min(w/3)
    conw := (w - navw)/2

    navx := 0
    conx := w - conw
    viewx := navw
    vieww := w - navw - conw

    app.nav.bounds      = Rect(navx,  0, navw,  h)
    app.view.bounds     = Rect(viewx, 0, vieww, h)
    app.console.bounds  = Rect(conx,  0, conw,  h)
  }

  App app
}

internal class AppController
{
  new make(App app) { this.app = app }

  App app

  Void onKeyDown(Event event)
  {
    switch (event.key.toStr)
    {
      case "Ctrl+R":    event.consume; app.reload; return
      case "Ctrl+S":    event.consume; app.save; return
      case "F8":        event.consume; app.curMark = app.curMark + 1; return
      case "Shift+F8":  event.consume; app.curMark = app.curMark - 1; return
      case "F9":        event.consume; app.build; return
      case "Esc":       event.consume; app.console.ready; return
    }
    // echo(":: $event")
  }

  Void onViewDirty()
  {
    app.window.title = app.window.title + "*"
  }

  Void onDrop(Obj data)
  {
    files := data as File[]
    if (files == null || files.isEmpty) return
    file := files.first
    app.load(FileRes(file))
  }
}

