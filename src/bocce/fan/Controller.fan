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

    // shift may indicate selection so don't include
    // that in navigation checks
    navKey := event.key
    if (navKey.isShift) navKey = navKey - Key.shift

    switch (navKey.toStr)
    {
      case "Up":         goto(event, caret.up(doc)); return
      case "Down":       goto(event, caret.down(doc)); return
      case "Left":       goto(event, caret.left(doc)); return
      case "Right":      goto(event, caret.right(doc)); return
      case "Home":       goto(event, caret.home(doc)); return
      case "End":        goto(event, caret.end(doc)); return
      case "Ctrl+Left":  goto(event, caret.prevWord(doc)); return
      case "Ctrl+Right": goto(event, caret.nextWord(doc)); return
      case "Ctrl+Home":  goto(event, doc.homePos); return
      case "Ctrl+End":   goto(event, doc.endPos); return
      case "PageUp":     event.consume; viewport.pageUp; return
      case "PageDown":   event.consume; viewport.pageDown; return
    }

    // everything else is editing functionality
    if (editor.ro) return

    // handle special modify keys
    switch (event.key.toStr)
    {
      case "Enter":      event.consume; onEnter; return
      case "Backspace":  event.consume; onBackspace; return
      case "Del":        event.consume; onDel; return
    }

    if (event.keyChar != null && event.keyChar >= ' ')
    {
      sel := editor.selection
      if (sel != null)
      {
        doc.modify(sel.start, sel.end, event.keyChar.toChar)
        viewport.goto(sel.start.right(doc))
      }
      else
      {
        doc.modify(caret, caret, event.keyChar.toChar)
        viewport.goto(caret.right(doc))
      }
      editor.selection = null
    }
  }

  private Void goto(Event event, Pos caret)
  {
    event.consume
    if (event.key != null && event.key.isShift)
    {
      if (anchor == null) anchor = editor.caret
    }
    else
    {
      anchor = null
    }
    viewport.goto(caret)
    editor.selection = anchor == null ? null : Span(anchor, caret)
  }

  private Void onEnter()
  {
    // insert newline
    caret := editor.caret
    sel := editor.selection
    if (sel != null)
      editor.doc.modify(sel.start, sel.end, "\n")
    else
      editor.doc.modify(caret, caret, "\n")
    editor.selection = null

    // find next place to indent
    line := doc.line(caret.line)
    col := 0
    while (col < line.size && line[col].isSpace) col++
    if (line.getSafe(col) == '{') col += editor.options.tabSpacing
    viewport.goto(Pos(caret.line+1, col))
  }

  private Void onBackspace()
  {
    if (editor.selection != null) { delSelection; return }
    doc := editor.doc
    caret := editor.caret
    prev := caret.left(doc)
    doc.modify(prev, caret, "")
    viewport.goto(prev)
  }

  private Void onDel()
  {
    if (editor.selection != null) { delSelection; return }
    doc := editor.doc
    caret := editor.caret
    next := caret.right(doc)
    doc.modify(caret, next, "")
  }

  private Void delSelection()
  {
    sel := editor.selection
    doc.modify(sel.start, sel.end, "")
    editor.selection = null
    viewport.goto(sel.start)
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
    editor.selection = null

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
  Pos? anchor                  // if in selection mode
}

