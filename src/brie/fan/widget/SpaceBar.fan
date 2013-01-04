//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 May 12  Brian Frank  Creation
//

using gfx
using fwt

**
** SpaceBar
**
internal class SpaceBar : Canvas
{
  new make(Frame frame)
  {
    this.frame = frame

    onMouseUp.add |e|
    {
      e.consume
      tab := posToTab(e.pos)
      if (tab == null) return
        if (e.id === EventId.mouseUp && e.button == 3 && e.count == 1)
          { onPopup(e, tab.space); return }
        if (e.button == 1) { frame.select(tab.space); return }
      }
  }

  Void onLoad()
  {
    spaces := frame.spaces
    curSpace := frame.curSpace
    x := 4
    tabs = spaces.map |s|
    {
      tab := SpaceTab(s, s === curSpace, x)
      x += tab.w + 4
      return tab
    }
    repaint
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    Size(300, 32)
  }

  override Void onPaint(Graphics g)
  {
    w := size.w; h := size.h
    g.push
    g.antialias = true
    g.font = font
    g.brush = bgBar
    g.fillRect(0, 0, w, h)

    tabs.each |tab|
    {
      g.brush = tab.cur ? bgCur : bgTab
      g.fillRoundRect(tab.x, 4, tab.w, h-11, 12, 12)
      g.brush = fg
      g.drawRoundRect(tab.x, 4, tab.w, h-11, 12, 12)
      g.drawImage(tab.space.icon, tab.x+6, 7)
      g.drawText(tab.space.dis, tab.x+24, 7)
    }
    g.pop
  }

  SpaceTab? posToTab(Point p)
  {
    tabs.find |t| { t.x <= p.x && p.x <= t.x+t.w }
  }


  private Void onPopup(Event e, Space s)
  {
    if (s is IndexSpace) return
    menu := Menu
    {
      MenuItem { text="Close"; onAction.add { frame.closeSpace(s) } },
      MenuItem { text="Close Others"; onAction.add{
          frame.spaces.each {if(it != s) this.frame.closeSpace(it)}
        }},
      MenuItem { text="Close All"; onAction.add {
          frame.spaces.each {this.frame.closeSpace(it)}
        }},
    }
    menu.open(e.widget, e.pos)
  }

  Font font   := Sys.cur.theme.font
  Color bgBar := Sys.cur.theme.bg
  Color bgTab := Sys.cur.theme.spacePillBg
  Color bgCur := Sys.cur.theme.selectedItem
  Color fg := Sys.cur.theme.fontColor

  private Frame frame
  private SpaceTab[] tabs := [,]
}

internal class SpaceTab
{
  new make(Space space, Bool cur, Int x)
  {
    this.space = space
    this.cur = cur
    this.x = x
    this.w = 6 + 20 + Sys.cur.theme.font.width(space.dis) + 6
  }

  Space space
  const Bool cur
  const Int x
  const Int w
}

