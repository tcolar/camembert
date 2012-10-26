//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using petanque

**
** TextView
**
class ImageView : View
{
  new make(Frame frame, File file) : super(frame, file)
  {
    sys := Service.find(Sys#) as Sys
    image = Image.makeFile(file)
    details := EdgePane
    {
      it.top = InsetPane(6)
      {
        GridPane
        {
          numCols = 2
          Label { text="Size"; font=sys.theme.font.toBold },
          Label { text="${this.image.size.w}px x ${this.image.size.h}px" },
        },
      }
      it.bottom = BorderPane
      {
        it.border = Border("1,0,1,0 $Desktop.sysNormShadow,#000,$Desktop.sysHighlightShadow")
      }
    }
    content = EdgePane
    {
      center = ImageViewWidget(image)
      bottom = details
    }
  }

  override Void onUnload()
  {
    image?.dispose
  }

  Image? image
}

internal class ImageViewWidget : Canvas
{
  new make(Image image) { this.image = image }
  override Void onPaint(Graphics g)
  {
    g.brush = ((Sys)Service.find(Sys#)).theme.bg
    g.fillRect(0, 0, size.w, size.h)
    g.drawImage(image, 8, 8)
  }
  Image image
}

