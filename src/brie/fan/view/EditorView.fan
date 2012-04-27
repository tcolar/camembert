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

**
** EditorView
**
class EditorView : View
{
  new make(App app, FileRes res) : super(app, res)
  {
    editor = Editor(app, res)
    editor.paintLeftDiv  = true
    editor.paintRightDiv = true
    editor.paintShowCols = true
    content = editor
  }

  Editor editor

  override Void onReady() { editor.focus }

  override Void onGoto(Mark mark)
  {
    editor.goto(mark)
  }

  override Void onMarks(Mark[] marks)
  {
    editor.repaint
  }
}

