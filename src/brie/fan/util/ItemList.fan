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

**
** ItemList
**
class ItemList : Canvas
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Frame frame, Item[] items)
  {
    this.frame = frame
    this.doubleBuffered = true
    this.items = items.ro
    onMouseUp.add |e| { doMouseUp(e) }
  }

//////////////////////////////////////////////////////////////////////////
// Config
//////////////////////////////////////////////////////////////////////////

  Frame frame { private set }

  Item[] items { private set  }

  const Font font := Desktop.sysFontMonospace

  const Insets insets := Insets(10, 10, 10, 10)

//////////////////////////////////////////////////////////////////////////
// Items
//////////////////////////////////////////////////////////////////////////

  Void addItem(Item item)
  {
    this.items = this.items.rw.add(item).ro
    relayout
    repaint
  }

  Void clear()
  {
    this.items = Item[,].ro
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

  override Void onPaint(Graphics g)
  {
    x := insets.left
    y := insets.top
    w := size.w
    h := size.h
    itemh := this.itemh

    g.brush = Theme.bg
    g.fillRect(0, 0, w, h)

    g.font = font
    items.each |item|
    {
      paintItem(g, item, x, y, w, itemh)
      y += itemh
    }
  }

  private Void paintItem(Graphics g, Item item, Int x, Int y, Int w, Int h)
  {
    if (item.isHeading)
    {
      g.brush = Theme.itemHeadingBg
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

  private Int itemh() { font.height.max(18) }

  private Int yToIndex(Int y) { (y - insets.top) / itemh }

  private Item? yToItem(Int y) { items.getSafe(yToIndex(y)) }

  private Void doMouseUp(Event event)
  {
    if (event.count == 1 && event.button == 1)
    {
      event.consume
      fireAction(yToIndex(event.pos.y))
      return
    }
  }

  private Void fireAction(Int index)
  {
    item := items.getSafe(index)
    if (item == null) return
    frame.goto(item)
  }

}

