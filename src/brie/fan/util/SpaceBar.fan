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
internal class SpaceBar : ContentPane
{
  new make(Frame frame) { this.frame = frame }

  Void onLoad()
  {
    spaces := frame.spaces
    grid := GridPane { numCols = spaces.size }
    spaces.each |space|
    {
      button := Button
      {
        dis := space.dis
        if (space === frame.curSpace) dis = "[$dis]"
        it.text = dis
        it.image = space.icon
        it.onAction.add |e| { frame.select(space) }
        it.onMouseUp.add |e| { if (e.isPopupTrigger) onPopup(e, space) }
      }
      grid.add(button)
    }
    content = InsetPane(2) { grid, }
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

  private Frame frame
}

