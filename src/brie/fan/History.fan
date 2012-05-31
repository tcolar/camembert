//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 08  Brian Frank  Creation
//   31 May 11  Brian Frank  Repurpose for Brie
//

using gfx
using fwt

**
** History maintains the most recent navigation history
** of the entire application.
**
class History
{

  **
  ** Log navigation to the specified resource
  ** into the history.  Return this.
  **
  This push(Item item)
  {
    // remove any item that matches space + file
    dup := items.findIndex |x|
    {
      item.space.typeof == x.space.typeof &&
      item.file == x.file
    }
    if (dup != null) items.removeAt(dup)

    // keep size below max
    while (items.size >= max) items.removeAt(-1)

    // push into most recent position
    items.insert(0, item)
    return this
  }

  **
  ** The first item is the most recent navigation and the last
  ** item is the oldest navigation.
  **
  Item[] items := [,] { private set }

  private Int max := 40
}

**************************************************************************
** HistoryPicker
**************************************************************************

class HistoryPicker : EdgePane
{
  new make(Item[] items, |Item, Event| onAction)
  {
    model := HistoryPickerModel(items)
    center = Table
    {
      it.headerVisible = false
      it.model = model
      it.onAction.add |Event e|
      {
        onAction(model.items[e.index], e)
      }
      it.onKeyDown.add |Event e|
      {
        code := e.keyChar
        if (code >= 97 && code <= 122) code -= 32
        code -= 65
        if (code >= 0 && code < 26 && code < model.numRows)
          onAction(model.items[code], e)
      }
    }
  }
}

internal class HistoryPickerModel : TableModel
{
  new make(Item[] items) { this.items = items }

  override Int numCols() { return 3 }
  override Int numRows() { return items.size }
  override Int? prefWidth(Int col)
  {
    switch (col)
    {
      case 0: return 40
      case 1: return 250
      default: return null
    }
  }
  override Image? image(Int col, Int row) { col==1 ? (items[row].icon ?: def) : null}
  override Font? font(Int col, Int row) { col==0 ? accFont : null }
  override Color? fg(Int col, Int row)  { col==0 ? accColor : null }
  override Str text(Int col, Int row)
  {
    switch (col)
    {
      case 0:  return (row < 26) ? (row+65).toChar : ""
      case 1:  return items[row].dis
      case 2:  return items[row].space.dis
      default: return ""
    }
  }
  Item[] items
  Image def := Theme.iconFile
  Font accFont := Desktop.sysFont.toSize(Desktop.sysFont.size-1)
  Color accColor := Color("#666")
}

