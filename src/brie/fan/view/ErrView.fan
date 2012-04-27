//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt

**
** ErrView
**
class ErrView : View
{
  new make(App app, ErrRes res) : super(app, res)
  {
    content := GridPane
    {
      numCols = 1
      halignPane = Halign.center
      valignPane = Valign.center
      vgap = 0
      Label
      {
        image  = res.icon
        font   = Font("bold 12pt Dialog")
        text   = "ERROR: $res.msg"
      },
      InsetPane
      {
        insets = Insets(0, 0, 0, 20)
        Label
        {
          font = Font("bold 10pt Dialog")
          text = res.uri.toStr
        },
      },
    }

    if (res.cause != null)
    {
      trace := Label { text=res.cause.traceToStr; font=Font("10pt Courier") }
      content.add(InsetPane { it.insets=Insets(0,0,0,20); it.content=trace })
    }

    this.content = content
  }
}

