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
using bocce

**
** ItemList
**
class ItemList : Panel
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Frame frame, Item[] items)
  {
    this.frame = frame
    this.items = items.ro
    onMouseUp.add |e| { doMouseUp(e) }
  }

//////////////////////////////////////////////////////////////////////////
// Config
//////////////////////////////////////////////////////////////////////////

  Frame? frame { private set }

  Item[] items { private set  }

  const Font font := Desktop.sysFontMonospace

  const Insets insets := Insets(5, 5, 5, 5)

  Item? highlight { set { &highlight = it; repaint } }

//////////////////////////////////////////////////////////////////////////
// Panel
//////////////////////////////////////////////////////////////////////////

  override Int numLines() { items.size }

  override Int lineh() { itemh }

  private Int itemh() { font.height.max(18) }

//////////////////////////////////////////////////////////////////////////
// Items
//////////////////////////////////////////////////////////////////////////

  Void addItem(Item item)
  {
    this.items = this.items.rw.add(item).ro
    relayout
    repaint
  }

  Void update(Item[] item)
  {
    this.items = item.ro
    &highlight = null
    relayout
    repaint
  }

  Void clear()
  {
    this.items = Item[,].ro
    &highlight = null
    relayout
    repaint
  }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    w := 0
    h := 0
    itemh := this.itemh
    items.each |item|
    {
      h += itemh
      w  = w.max(20 + font.width(item.dis))
    }
    w += insets.left + insets.right
    h += insets.top + insets.bottom
    return Size(250,h)
  }

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////

  override Void onPaintViewport(Graphics g, Int w, Int h)
  {
    x := insets.left
    y := insets.top
    itemh := this.itemh

    g.font = font
    items.eachRange(viewportLines) |item|
    {
      paintItem(g, item, x, y, w, itemh)
      y += itemh
    }
  }

  private Void paintItem(Graphics g, Item item, Int x, Int y, Int w, Int h)
  {
    /*
    if (item.header)
    {
      g.brush = Theme.itemHeadingBg
      if (item === items.first)
        g.fillRect(0, 0, size.w, y+h-2)
      else
        g.fillRect(0, y, size.w, h-2)
    }
    */

    if (item === this.highlight)
    {
      g.brush = Color.yellow
      g.fillRect(0, y, size.w, h-2)
    }
    x += item.indent*20
    g.brush = Color.black
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
    if (event.count == 1 && event.button == 1)
    {
      event.consume
      if (item != null) frame.goto(item)
      return
    }

    if (event.isPopupTrigger)
    {
      event.consume
      menu := item?.popup(frame)
      if (menu != null) menu.open(event.widget, event.pos)
      return
    }
  }

}

