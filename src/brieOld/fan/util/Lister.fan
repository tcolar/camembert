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
using bocce

**
** Lister re-uses Editor to show/select from list of strings
**
class Lister : Editor
{

  new make(Obj[] items, Str str := items.join("\n"))
    : super(null)
  {
    this.items = items
    this.paintCaret = false
    this.ro = true
    this.cursor = Cursor.defVal
    load(str.in)
  }

  once EventListeners onAction() { EventListeners() }

  Obj[] items

  Void addItem(Obj item)
  {
    str := item.toStr
    if (!items.isEmpty) str = "\n$str"
    items.add(item)
    modify(docEndPos.toSpan, str)
  }

  override Void trapEvent(Event event)
  {
    // letters are quick match
    if (event.id === EventId.keyDown && (event.keyChar ?: ' ').isAlpha)
    {
      event.consume
      quickMatch += event.keyChar.lower.toChar
      doQuickMatch()
      return
    }

    // these events clear quick match
    if (event.id == EventId.focus ||
        event.id == EventId.blur ||
        event.id === EventId.keyDown ||
        event.id === EventId.mouseDown)
    {
      quickMatch = ""
      clearQuickMatchHighlight
    }

    if (event.id === EventId.keyDown)
    {
      if (event.key.toStr == "Enter") { event.consume; doAction; return }
    }
    else if (event.id === EventId.mouseDown)
    {
      if (event.count >= 2) { event.consume; doAction; return }
    }
  }

  private Void doAction()
  {
    index := caret.line
    item := items.getSafe(index)
    if (item == null) return
    event := Event
    {
      it.id     = EventId.action
      it.widget = this
      it.index  = index
      it.data   = item
    }
    onAction.fire(event)
  }

  private Void doQuickMatch()
  {
    clearQuickMatchHighlight
    checkLine := |Int linei->Bool|
    {
      line := line(linei).lower
      if (!line.trim.startsWith(quickMatch)) return false
      col := line.lower.index(quickMatch)
      quickMatchHighlight = Span(linei, col, linei, col+quickMatch.size)
      highlights = highlights.add(quickMatchHighlight)
      goto(Pos(linei, 0))
      return true
    }

    // check forward, then back
    startLine := caret.line
    for (linei := startLine; linei < lineCount; ++linei)
      if (checkLine(linei)) return
    for (linei := startLine; linei >= 0; --linei)
      if (checkLine(linei)) return
  }

  private Void clearQuickMatchHighlight()
  {
    if (quickMatchHighlight == null) return
    highlights = highlights.dup { it.remove(quickMatchHighlight) }
    quickMatchHighlight = null
  }

  Str quickMatch := ""
  Span? quickMatchHighlight
}

