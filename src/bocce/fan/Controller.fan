//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using concurrent

**
** Controller
**
internal class Controller
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Editor editor)
  {
    this.editor = editor

    editor.onFocus.add |e|      { onFocus(e)      }
    editor.onBlur.add |e|       { onBlur(e)       }

    editor.onKeyDown.add |e|    { onKeyDown(e)    }

    editor.onMouseDown.add |e|  { onMouseDown(e)  }
    editor.onMouseUp.add |e|    { onMouseUp(e)    }
    editor.onMouseMove.add |e|  { onMouseMove(e)  }
    editor.onMouseEnter.add |e| { onMouseMove(e)  }
    editor.onMouseExit.add |e|  { onMouseExit(e)  }
    editor.onMouseWheel.add |e| { onMouseWheel(e) }
  }

//////////////////////////////////////////////////////////////////////////
// Conveniences
//////////////////////////////////////////////////////////////////////////

  Doc doc() { editor.doc }

  Viewport viewport() { editor.viewport }

//////////////////////////////////////////////////////////////////////////
// Focus Eventing
//////////////////////////////////////////////////////////////////////////

  Void onFocus(Event event)
  {
    focused = true
    editor.repaint
  }

  Void onBlur(Event event)
  {
    focused = false
    vbarVisible = false
    editor.repaint
  }

//////////////////////////////////////////////////////////////////////////
// Key Eventing
//////////////////////////////////////////////////////////////////////////

  Void onKeyDown(Event event)
  {
    editor.trapEvent(event)
    if (event.consumed) return

    key := event.key
    switch (key.toStr)
    {
      case "Up":         event.consume; viewport.up; return
      case "Down":       event.consume; viewport.down; return
      case "Left":       event.consume; viewport.left; return
      case "Right":      event.consume; viewport.right; return
      case "Home":       event.consume; viewport.home; return
      case "End":        event.consume; viewport.end; return
      case "PageUp":     event.consume; viewport.pageUp; return
      case "PageDown":   event.consume; viewport.pageDown; return
      case "Ctrl+Left":  event.consume; viewport.prevWord; return
      case "Ctrl+Right": event.consume; viewport.nextWord; return
      case "Ctrl+Home":  event.consume; viewport.docHome; return
      case "Ctrl+End":   event.consume; viewport.docEnd; return
    }
  }

//////////////////////////////////////////////////////////////////////////
// Mouse Eventing
//////////////////////////////////////////////////////////////////////////

  Void onMouseDown(Event event)
  {
    if (vbarVisible)
    {
      vthumbDrag = viewport.vthumbDragStart(event.pos)
      if (vthumbDrag != null) return
    }

    if (hbarVisible)
    {
      hthumbDrag = viewport.hthumbDragStart(event.pos)
      if (hthumbDrag != null) return
    }

    viewport.caretTo(event.pos)

    editor.trapEvent(event)
    if (event.consumed) return
  }

  Void onMouseUp(Event event)
  {
    vthumbDrag = null
    hthumbDrag = null
    editor.repaint()
  }

  Void onMouseExit(Event event)
  {
    hbarVisible = false
    vbarVisible = false
    editor.repaint()
  }

  Void onMouseMove(Event event)
  {
    if (vthumbDrag != null) { viewport.vthumbDrag(vthumbDrag, event.pos); return }
    if (hthumbDrag != null) { viewport.hthumbDrag(hthumbDrag, event.pos); return }

    size := editor.size
    vbar := event.pos.x > size.w - 40
    if (vbar != vbarVisible) { vbarVisible = vbar; editor.repaint; return }
    hbar := event.pos.y > size.h - 40
    if (hbar != hbarVisible) { hbarVisible = hbar; editor.repaint; return }
  }

  Void onMouseWheel(Event event)
  {
    if (event.delta.y != 0) editor.viewport.vscroll(event.delta.y)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Editor editor
  private Int? vthumbDrag      // if dragging vertical thumb
  private Int? hthumbDrag      // if dragging horizontal thumb
  Bool vbarVisible             // is vertical scroll visible
  Bool hbarVisible             // is horizontal scroll visible
  Bool focused                 // are we currently focused
}

