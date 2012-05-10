//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 May 12  Brian Frank  Creation
//

using gfx
using fwt
using compiler

**
** StatusBar
**
class StatusBar : Canvas
{
  new make(App app)
  {
    this.app = app
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    Size(100, 25)
  }

  Void refresh() { repaint }

  override Void onPaint(Graphics g)
  {
    // background
    w := size.w; h := size.h
    g.brush = Theme.bg
    g.fillRect(0, 0, w, h)

    // div at top
    g.brush = Theme.div
    g.drawLine(0, 0, w, 0)
    g.drawLine(0, 1, w, 1)

    // indexing
    if (app.index.isIndexing)
      g.drawImage(Theme.iconIndexing, 8, 2+(h-18)/2)

    // editor line:col charset
    g.font = app.options.font
    g.brush = Theme.status
    editor := app.view as EditorView
    if (editor != null)
    {
      caret := editor.editor.caret
      text := "" + (caret.line+1) + ":" + (caret.col+1) + "    " + editor.charset
      g.drawText(text, w-g.font.width(text)-20, 5)
    }
  }

  App app
}


