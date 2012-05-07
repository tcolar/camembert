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
    load(str.in)
  }

  once EventListeners onAction() { EventListeners() }

  Obj[] items

  override Void trapEvent(Event event)
  {
    if (event.id === EventId.keyDown)
    {
      if (event.key.toStr == "Enter") doAction
    }
    else if (event.id === EventId.mouseDown)
    {
      if (event.count >= 2) doAction
    }
  }

  internal Void doAction()
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

}

