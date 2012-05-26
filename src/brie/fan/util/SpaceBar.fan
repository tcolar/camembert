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
        text = space.dis
        image = space.icon
        onAction.add |event| { frame.select(space) }
      }
      grid.add(button)
    }
    content = InsetPane(2) { grid, }
  }
  private Frame frame
}

