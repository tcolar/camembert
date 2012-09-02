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
    this.changes = Change[,]

    editor.onFocus.add |e|      { onFocus(e)      }
    editor.onBlur.add |e|       { onBlur(e)       }

    editor.onKeyDown.add |e|    { onKeyDown(e)    }
    editor.onKeyUp.add |e|      { onKeyUp(e)      }

    editor.onMouseDown.add |e|  { onMouseDown(e)  }
    editor.onMouseUp.add |e|    { onMouseUp(e)    }
    editor.onMouseMove.add |e|  { onMouseMove(e)  }
    editor.onMouseEnter.add |e| { onMouseMove(e)  }
  }

//////////////////////////////////////////////////////////////////////////
// Conveniences
//////////////////////////////////////////////////////////////////////////

  Doc doc() { editor.doc }

  Viewport viewport() { editor.viewport }

  EditorOptions options() { editor.options }

//////////////////////////////////////////////////////////////////////////
// Focus Eventing
//////////////////////////////////////////////////////////////////////////

  Void onFocus(Event event)
  {
    editor.trapEvent(event)
    if (event.consumed) return

    onAnimate
    caretVisible = true
    editor.repaint
  }

  Void onBlur(Event event)
  {
    editor.trapEvent(event)
    if (event.consumed) return

    navCol = null
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
    key := event.key
    navKey := key
    if (navKey.isShift) navKey = navKey - Key.shift

    // navigation
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
      case "Ctrl+C":     event.consume; onCopy; return
    }

    // everything else is editing functionality
    if (editor.ro) return

    // handle special modify keys
    switch (key.toStr)
    {
      case "Enter":      event.consume; onEnter; return
      case "Backspace":  event.consume; onBackspace; return
      case "Del":        event.consume; onDel(false); return
      case "Ctrl+Del":   event.consume; onDel(true); return
      case "Ctrl+D":     event.consume; onCutLine; return
      case "Ctrl+X":     event.consume; onCut; return
      case "Ctrl+V":     event.consume; onPaste; return
      case "Ctrl+Z":     event.consume; onUndo; return
      case "Tab":        event.consume; onTab(true); return
      case "Shift+Tab":  event.consume; onTab(false); return
    }

    // normal insert of character
    if (event.keyChar != null && event.keyChar >= ' ' &&
        !key.isCtrl && !key.isAlt && !key.isCommand)
    {
      event.consume
      insert(event.keyChar.toChar)
      return
    }

  }

  Void onKeyUp(Event event)
  {
    editor.trapEvent(event)
    if (event.consumed) return

    if (event.key == Key.shift) anchor = null
  }

  private Void goto(Event event, Pos newCaret)
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

    // if moving up/down then remember col position
    // to handle ragged lines
    oldCaret := viewport.caret
    if (oldCaret.line != newCaret.line)
    {
      if (navCol == null)
        navCol = oldCaret.col
      else
        newCaret = Pos(newCaret.line, navCol)
    }
    else
    {
      navCol = null
    }

    viewport.goto(newCaret)
    editor.selection = anchor == null ? null : Span(anchor, newCaret)
  }

  private Void insert(Str newText)
  {
    sel := editor.selection
    if (sel == null) sel = Span(editor.caret, editor.caret)
    endPos := modify(sel, newText)
    viewport.goto(endPos)
    editor.selection = null
  }

  private Void onCopy()
  {
    if (editor.selection == null) return
    Desktop.clipboard.setText(doc.textRange(editor.selection))
  }

  private Void onCut()
  {
    if (editor.selection == null) return
    onCopy
    delSelection
  }

  private Void onPaste()
  {
    text := Desktop.clipboard.getText
    if (text == null || text.isEmpty) return
    insert(text)
  }

  private Void onEnter()
  {
    // handle selection + enter as delete selection
    if (editor.selection != null) { delSelection; return }

    // find next place to indent
    caret := editor.caret
    line := doc.line(caret.line)
    col := 0
    while (col < line.size - 1 && line[col].isSpace) col++
    if (line.getSafe(caret.col) == '}') col -= editor.options.tabSpacing

    // insert newline and indent spaces
    newText := "\n" + Str.spaces(col)
    modify(Span(caret, caret), newText)
    viewport.goto(Pos(caret.line+1, col))
  }

  private Void onBackspace()
  {
    if (editor.selection != null) { delSelection; return }
    doc := editor.doc
    caret := editor.caret
    prev := caret.left(doc)
    modify(Span(prev, caret), "")
    viewport.goto(prev)
  }

  private Void onDel(Bool word)
  {
    if (editor.selection != null) { delSelection; return }
    doc := editor.doc
    caret := editor.caret
    next := word ? caret.endWord(doc) : caret.right(doc)
    modify(Span(caret, next), "")
  }

  private Void onCutLine()
  {
    if (editor.selection != null) { delSelection; return }
    doc := editor.doc
    caret := editor.caret
    start := Pos(caret.line, 0)
    end := caret.line >= doc.lineCount-1 ? doc.endPos : Pos(caret.line+1, 0)
    span := Span(start, end)
    text := doc.textRange(span)
    Desktop.clipboard.setText(text)
    x := modify(span, "")
    viewport.goto(x)
  }

  private Void delSelection()
  {
    sel := editor.selection
    modify(sel, "")
    editor.selection = null
    viewport.goto(sel.start)
  }

  private Void onTab(Bool indent)
  {
    // if batch indent/detent
    if (editor.selection != null) { onBatchTab(indent); return }

    // indent single line
    caret := editor.caret
    if (indent)
    {
      col := caret.col + 1
      while (col % options.tabSpacing != 0) col++
      spaces := Str.spaces(col - caret.col)
      x := modify(Span(caret, caret), spaces)
      viewport.goto(x)
    }
    else
    {
      col := caret.col - 1
      while (col % options.tabSpacing != 0) col--
      if (col < 0) col = 0
      if (col == caret.col) return
      x := modify(Span(Pos(caret.line, col), caret), "")
      viewport.goto(x)
    }
  }

  private Void onBatchTab(Bool indent)
  {
    changes := Change[,]
    doc := editor.doc
    sel := editor.selection
    endLine := sel.end.line
    if (endLine > sel.start.line && sel.end.col == 0) endLine--
    for (linei := sel.start.line; linei <= endLine; ++linei)
    {
      // find first non-space
      first := 0
      line := doc.line(linei)
      while (first < line.size && line[first].isSpace) first++

      pos := Pos(linei, 0)
      if (indent)
      {
        spaces := Str.spaces(options.tabSpacing)
        doc.modify(Span(pos, pos), spaces)
        changes.add(SimpleChange(pos, "", spaces))
      }
      else
      {
        if (first == 0) continue
        end := Pos(linei, first.min(2))
        changes.add(SimpleChange(pos, Str.spaces(end.col), ""))
        doc.modify(Span(pos, end), "")
      }
    }
    this.changes.push(BatchChange(changes))
  }

//////////////////////////////////////////////////////////////////////////
// Modification / Undo
//////////////////////////////////////////////////////////////////////////
  internal Pos modify(Span span, Str newText)
  {
    doc := editor.doc
    oldText := doc.textRange(span)
    pushChange(SimpleChange(span.start, oldText, newText))
    return doc.modify(span, newText)
  }

  private Void pushChange(SimpleChange c)
  {
    // if appending a single char to end of last
    // change then make it one big atomic undo change
    top := changes.peek as SimpleChange
    if (isAtomicUndo(top, c))
      changes[-1] = SimpleChange(top.pos, top.oldText, top.newText+c.newText)
    else
      changes.push(c)
  }

  private Bool isAtomicUndo(SimpleChange? a, SimpleChange b)
  {
    if (a == null) return false
    if (a.oldText.size > 0) return false
    if (b.newText.size > 1) return false
    if (a.pos.line != b.pos.line) return false
    return a.pos.col + a.newText.size == b.pos.col
  }

  private Void onUndo()
  {
    c := changes.pop
    if (c == null) return
    c.undo(editor)
  }

//////////////////////////////////////////////////////////////////////////
// Mouse Eventing
//////////////////////////////////////////////////////////////////////////

  Void onMouseDown(Event event)
  {
    isMouseDown = true
    navCol = null

    editor.trapEvent(event)
    if (event.consumed) return

    if (event.count == 2) { mouseSelectWord(event); return }
    if (event.count == 3) { mouseSelectLine(event); return }

    viewport.goto(viewport.pointToPos(event.pos))
    anchor = editor.caret
    editor.selection = null

    editor.trapEvent(event)
    if (event.consumed) return
  }

  Void onMouseUp(Event event)
  {
    isMouseDown = false

    editor.trapEvent(event)
    if (event.consumed) return

    anchor = null
    editor.repaint()
  }

  Void onMouseMove(Event event)
  {
    if (anchor != null && isMouseDown) { mouseSelectDrag(event); return }
  }

  private Void mouseSelectDrag(Event event)
  {
    pos := viewport.pointToPos(event.pos)
    editor.selection = Span(anchor, pos)
  }

  private Void mouseSelectWord(Event event)
  {
    pos := viewport.pointToPos(event.pos)
    doc := editor.doc
    start := pos.prevWord(doc)
    end := pos.nextWord(doc)
    editor.selection = Span(start, end)
    viewport.goto(end)
  }

  private Void mouseSelectLine(Event event)
  {
    pos := viewport.pointToPos(event.pos)
    line := editor.doc.line(pos.line)
    end := Pos(pos.line, line.size)
    editor.selection = Span(Pos(pos.line, 0), end)
    viewport.goto(end)
  }

//////////////////////////////////////////////////////////////////////////
// Animation
//////////////////////////////////////////////////////////////////////////

  Void onAnimate()
  {
    caretVisible = !caretVisible
    viewport.repaintLine(viewport.caret.line)
    if (editor.hasFocus) Desktop.callLater(500ms) |->| { onAnimate }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Editor editor
  private Pos? anchor          // if in selection mode
  private Bool isMouseDown     // is mouse currently down
  private Int? navCol          // to handle ragged col up/down
  private Change[] changes     // change stack
  Bool caretVisible            // is caret visible or blinking off
}

