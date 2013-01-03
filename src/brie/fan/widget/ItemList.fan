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
using petanque

**
** ItemList
**
class ItemList : Panel
{
  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

  new make(Frame frame, Item[] items, Int width := 200)
  {
    this.frame = frame
    this.width = width
    update(items)
    onMouseUp.add |e| { doMouseUp(e) }
  }

  //////////////////////////////////////////////////////////////////////////
  // Config
  //////////////////////////////////////////////////////////////////////////

  Frame? frame { private set }

  Item[] items := [,]

  Font font := Sys.cur.theme.font

  Item? highlight { set { &highlight = it; repaint } }

//////////////////////////////////////////////////////////////////////////
// Panel
//////////////////////////////////////////////////////////////////////////

  override Int lineCount() { items.size }

  override Int lineh() { itemh }

  override Int colCount := 5 { private set }

  override const Int colw := font.width("m")

  private Int itemh() { font.height.max(18) }

  private Int width

//////////////////////////////////////////////////////////////////////////
// Items
//////////////////////////////////////////////////////////////////////////

  Void addItem(Item item)
  {
    update(this.items.rw.add(item))
    relayout
    repaint
  }

  Void update(Item[] newItems)
  {
    max := 5
    newItems.each |x| { max = x.dis.size.max(max) }
    this.items = newItems
    this.colCount = max + 2 // leave 2 for icon
    &highlight = null
    relayout
    repaint
  }

  Void clear() { update(Item[,]) }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    Size(width ,200)
  }

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////
  override Void onPaintLines(Graphics g, Range lines)
  {
    x := 0
    y := 0
    itemh := this.itemh

    items.eachRange(lines) |item|
    {
      paintItem(g, item, x, y)
      y += itemh
    }
  }

  private Void paintItem(Graphics g, Item item, Int x, Int y)
  {
    if (item === this.highlight)
    {
      g.brush = Sys.cur.theme.selectedItem
      g.fillRect(0, y, size.w, itemh)
    }
    x += item.indent*20
    g.brush = Sys.cur.theme.fontColor
    if (item.icon != null) g.drawImage(item.icon, x, y)
    g.drawText(item.dis, x+20, y)
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  private Item? yToItem(Int y) { items.getSafe(yToLine(y)) }

  private Void doMouseUp(Event event)
  {
    item := items.getSafe(yToLine(event.pos.y))
    if(item==null)
    {
      event.consume
      return
    }

    if (event.count == 1 && event.button == 1)
    {
      event.consume
      item.selected(frame)
      if(item.file != null && item.file.isDir)
      {
        toggleCollapse(item)
      }
      return
    }

    if (event.id === EventId.mouseUp && event.button == 3 && event.count == 1)
    {
      event.consume
      menu := item.popup(frame)
      if (menu != null)
      {
        menu.open(event.widget, event.pos)
      }
      return
    }
  }

  ** Collpase / expand a folder item
  Void toggleCollapse(Item item)
  {
    if(item.collapsed)
    {
      // expand (one level)
      Item[] newItems := [,]
      item.file.listFiles.each |File file|
      {
        newItems.add(Item(file){
          it.indent = 1
        })
      }
      item.file.listDirs.each |File file|
      {
        newItems.add(Item(file){
          it.dis = "${item.dis}$file.name/"
          it.collapsed = ! file.list.isEmpty
        })
      }
      Int index := items.eachWhile |that, index -> Int?| {if(item.file == that.file) return index; return null}

      items.insertAll(index == items.size ? -1 : index + 1, newItems)

      max := colCount
      newItems.each |x| { max = x.dis.size.max(max) }
      colCount = max + 2

      item.collapsed = false
      item.icon = Sys.cur.theme.iconFolderOpen
    }
    else
    {
      // collpase (all)
      items.dup.each
      {
        if(it.file!=item.file && it.file.pathStr.startsWith(item.file.pathStr))
          items.remove(it)
      }
      item.collapsed = true
      item.icon = Sys.cur.theme.iconFolderClosed
    }
    repaint
  }
}

