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

    caret := editor.caret
    doc := editor.doc
    key := event.key
    switch (key.toStr)
    {
      case "Up":         event.consume; goto(caret.up(doc)); return
      case "Down":       event.consume; goto(caret.down(doc)); return
      case "Left":       event.consume; goto(caret.left(doc)); return
      case "Right":      event.consume; goto(caret.right(doc)); return
      case "Home":       event.consume; goto(caret.home(doc)); return
      case "End":        event.consume; goto(caret.end(doc)); return
      case "PageUp":     event.consume; viewport.pageUp; return
      case "PageDown":   event.consume; viewport.pageDown; return
      case "Ctrl+Left":  event.consume; goto(caret.prevWord(doc)); return
      case "Ctrl+Right": event.consume; goto(caret.nextWord(doc)); return
      case "Ctrl+Home":  event.consume; goto(doc.homePos); return
      case "Ctrl+End":   event.consume; goto(doc.endPos); return
    }

    // everything else is editing functionality
    if (editor.ro) return

    switch (key.toStr)
    {
      case "Enter":      event.consume; onEnter; return
      case "Backspace":  event.consume; onBackspace; return
      case "Del":        event.consume; onDel; return
    }

    if (event.keyChar != null && event.keyChar >= ' ')
    {
      event.consume
      doc.modify(caret, caret, event.keyChar.toChar)
      goto(caret.right(doc))
    }
  }

  private Void goto(Pos caret)
  {
    viewport.goto(caret, false)
  }

  private Void onEnter()
  {
    // insert newline
    caret := editor.caret
    editor.doc.modify(caret, caret, "\n")

    // find next place to indent
    line := doc.line(caret.line)
    col := 0
    while (col < line.size && line[col].isSpace) col++
    if (line.getSafe(col) == '{') col += editor.options.tabSpacing
    goto(Pos(caret.line+1, col))
  }

  private Void onBackspace()
  {
    caret := editor.caret
    prev := caret
    editor.doc.modify(caret, caret, "\n")
  }

  private Void onDel()
  {
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

    viewport.caretToPoint(event.pos)

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

