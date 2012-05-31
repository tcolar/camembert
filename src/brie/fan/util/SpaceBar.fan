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
      if (e.isPopupTrigger) { onPopup(e, tab.space); return }
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
    Size(300, 30)
  }

  override Void onPaint(Graphics g)
  {
    w := size.w; h := size.h
    g.font = font
    g.brush = bgBar
    g.fillRect(0, 0, w, h)

    tabs.each |tab|
    {
      g.brush = tab.cur ? bgCur : bgTab
      g.fillRoundRect(tab.x, 4, tab.w, h-8, 12, 12)
      g.brush = fgTab
      g.drawRoundRect(tab.x, 4, tab.w, h-8, 12, 12)
      g.drawImage(tab.space.icon, tab.x+6, 8)
      g.brush = Color.black
      g.drawText(tab.space.dis, tab.x+24, 8)
    }
  }

  SpaceTab? posToTab(Point p)
  {
    tabs.find |t| { t.x <= p.x && p.x <= t.x+t.w }
  }


  private Void onPopup(Event e, Space s)
  {
    if (s is HomeSpace) return
    menu := Menu
    {
      MenuItem { text="Close"; onAction.add { frame.closeSpace(s) } },
    }
    menu.open(e.widget, e.pos)
  }

  static const Font font   := Desktop.sysFont
  static const Color bgBar := Theme.wallpaper
  static const Color bgTab := Color(0xee_ee_ee)
  static const Color bgCur := Color.green
  static const Color fgTab := Color(0x44_44_44)

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
    this.w = 6 + 20 + SpaceBar.font.width(space.dis) + 6
  }

  const Space space
  const Bool cur
  const Int x
  const Int w
}

