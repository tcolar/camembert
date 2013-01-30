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

    // console label
    this.console = Label
    {
      text="Console"
      it.onMouseDown.add |e| { if (e.button == 1) onConsoleToggle }
      it.onMouseUp.add |e| { if (e.id === EventId.mouseUp && e.button == 3 && e.count == 1) onConsolePopup(e) }
    }

    // index
    this.index = Label
    {
      it.text="Index"
    }

    // projects
    this.projects = Label
    {
      it.text="Projects"
    }
    // file label
    this.file = Label
    {
      it.text="File"
      it.halign = Halign.left
      it.onMouseDown.add |e| { if (e.button == 1) frame.save }
    }

    // view (line/col status, etc)
    this.view = Label
    {
      it.text = "View"
      it.halign = Halign.right
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
          projects,
          index,
          InsetPane(0, 20, 0, 0)
        }
        it.center = file
        it.right = ConstraintPane { minw = 150; view, }
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Updates
//////////////////////////////////////////////////////////////////////////

  Void update()
  {
    // console up/down
    console.image = frame.console.isOpen ? Sys.cur.theme.iconSlideDown : Sys.cur.theme.iconSlideUp

    // project scanning
    index.image = Sys.cur.prjReg.isScanning.val ? Sys.cur.theme.iconIndexing : Sys.cur.theme.iconOk

    // view file
    v := frame.curView
    if (v != null)
    {
      file.text = FileUtil.pathDis(v.file)
      file.image = v.dirty ? Sys.cur.theme.iconDirty : Sys.cur.theme.iconNotDirty
      view.text = v.curStatus
    }
    else
    {
      file.text = ""
      file.image = null
      view.text = ""
    }

    // relayout
    file.relayout
    view.relayout
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  Void onConsoleToggle()  { frame.console.toggle  }

  Void onConsolePopup(Event event)
  {
    menu := Menu
    {
      MenuItem
      {
        it.text = "Open Console"
        it.onAction.add |e| { frame.console.open }
      },
      MenuItem
      {
        it.text = "Close Console"
        it.accelerator = Sys.cur.commands.consoleToggle.key
        it.onAction.add |e| { frame.console.close }
      },
      MenuItem
      {
        it.text = "Kill"
        it.enabled = frame.console.isBusy
        it.onAction.add |e| { frame.console.kill }
      },
    }
    menu.open(console, event.pos)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Frame frame
  private Label index
  private Label projects
  private Label console
  private Label file
  private Label view
}

