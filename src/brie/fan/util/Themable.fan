// History:
//  Feb 03 13 tcolar Creation
//

using fwt
using gfx

**
** Themable
**
mixin Themable
{
  abstract Void updateTheme()
}

class BgEdgePane : EdgePane
{
  new make(|This|? f:= null )
  {
    if(f!=null) f(this)
    t := Sys.cur.theme
    if(top == null) top = FillerPane(t.bg)
    if(bottom == null) bottom = FillerPane(t.bg)
    if(center == null) center = FillerPane(t.bg)
    if(left == null) left = FillerPane(t.bg)
  }
}

class BgLabel : Label, Themable
{
  new make(|This|? f)
  {
    if(f != null) f(this)
    updateTheme
  }

  override Void updateTheme()
  {
    t := Sys.cur.theme

    this.bg = t.bg
    this.fg = t.fontColor
    this.font = t.font
    repaint
  }
}

class FillerPane : BorderPane, Themable
{
  new make(Color bg)
  {
    updateTheme
  }

  override Void updateTheme()
  {
    t := Sys.cur.theme
    this.bg = t.bg
    repaint
  }
}