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
** StatusBar
**
internal class StatusBar : ContentPane
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Frame frame)
  {
    this.frame = frame
    this.sys = frame.sys

    // console label
    this.console = Label
    {
      text="Console"
      it.onMouseDown.add |e| { if (e.button == 1) onConsoleToggle }
      it.onMouseUp.add |e| { if (e.isPopupTrigger) onConsolePopup(e) }
    }

    // index
    this.index = Label
    {
      it.text="Index"
      it.onMouseUp.add |e| { if (e.isPopupTrigger) onIndexPopup(e) }
    }

    // file label
    this.file = Label
    {
      it.text="File"
      it.halign = Halign.left
      it.onMouseDown.add |e| { if (e.button == 1) frame.save }
      it.onMouseUp.add |e| { if (e.isPopupTrigger) onFilePopup(e) }
    }

    // put it all together
    this.content = InsetPane(4, 5, 0, 5)
    {
      it.content = EdgePane
      {
        it.left = GridPane
        {
          numCols = 3
          hgap = 15
          console,
          index,
          InsetPane(0, 20, 0, 0)
        }
        it.center = file
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Updates
//////////////////////////////////////////////////////////////////////////

  Void update()
  {
    // console up/down
    console.image = consoleOpen ? Theme.iconSlideDown : Theme.iconSlideUp

    // indexing
    index.image = sys.index.isIndexing ? Theme.iconIndexing : Theme.iconOk

    // view file
    view := frame.view
    if (view != null)
    {
      file.text = view.file.name
      file.image = view.dirty ? Theme.iconDirty : Theme.iconNotDirty
    }
    else
    {
      file.text = ""
      file.image = null
    }

    // relayout
    file.relayout
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  Void onConsoleToggle()  { consoleOpen = !consoleOpen }

  Void onConsolePopup(Event event)
  {
    menu := Menu
    {
      MenuItem { text="Open Console";  onAction.add |e| { consoleOpen=true } },
      MenuItem { text="Close Console"; onAction.add |e| { consoleOpen=false } },
    }
    menu.open(console, event.pos)
  }

Bool consoleOpen { set { &consoleOpen = it; update } }

  Void onIndexPopup(Event event)
  {
    menu := Menu
    {
      MenuItem { text="Reindex All"; onAction.add |e| { sys.index.reindexAll } },
    }
    menu.open(index, event.pos)
  }

  Void onFilePopup(Event event)
  {
    view := frame.view
    if (view == null) return
    menu := Menu
    {
      MenuItem { text="Save";  it.enabled = view.dirty; onAction.add |e| { frame.save } },
    }
    menu.open(file, event.pos)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Frame frame
  private Sys sys
  private Label index
  private Label console
  private Label file
}

