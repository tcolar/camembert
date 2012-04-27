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

**
** Lister re-uses Editor to show/select from list of strings
**
class Lister : Editor
{

  new make(Obj[] items, Str str := items.join("\n"))
    : super(null, FileRes(StrFile(`items.txt`, str)))
  {
    this.items = items
    this.paintCaret = false
  }

  once EventListeners onAction() { EventListeners() }

  Obj[] items

  internal Void doAction()
  {
    index := viewport.caret.y
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

