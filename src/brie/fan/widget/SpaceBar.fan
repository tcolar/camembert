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
    if (s is HomeSpace) return
    menu := Menu
    {
      MenuItem { text="Close"; onAction.add { frame.closeSpace(s) } },
      MenuItem { text="Close Others"; onAction.add{
          frame.spaces.each {if(it != s) frame.closeSpace(it)}
        }},
      MenuItem { text="Close All"; onAction.add {
          frame.spaces.each {frame.closeSpace(it)}
        }},
    }
    menu.open(e.widget, e.pos)
  }

  Sys? sys := Service.find(Sys#) as Sys

  Font font   := sys.theme.font
  Color bgBar := sys.theme.bg
  Color bgTab := sys.theme.spacePillBg
  Color bgCur := sys.theme.selectedItem
  Color fg := sys.theme.fontColor

  private Frame frame
  private SpaceTab[] tabs := [,]

  Void updateSys(Sys sys)
  {
    this.sys = sys
    font   = sys.theme.font
    bgBar = sys.theme.bg
    bgTab = sys.theme.spacePillBg
    bgCur = sys.theme.selectedItem
    fg = sys.theme.fontColor
    repaint
  }
}

internal class SpaceTab
{
  new make(Space space, Bool cur, Int x)
  {
    this.space = space
    this.cur = cur
    this.x = x
    sys := Service.find(Sys#) as Sys
    this.w = 6 + 20 + sys.theme.font.width(space.dis) + 6
  }

  const Space space
  const Bool cur
  const Int x
  const Int w
}

