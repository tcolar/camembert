//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using concurrent

**************************************************************************
** Change
**************************************************************************

abstract const class Change
{
  abstract Void undo(Editor editor)
}

**************************************************************************
** SimpleChange
**************************************************************************

const class SimpleChange : Change
{
  new make(Pos pos, Str oldText, Str newText)
  {
    this.pos     = pos
    this.oldText = oldText
    this.newText = newText
  }

  const Pos pos
  const Str oldText
  const Str newText

  override Void undo(Editor editor)
  {
    doc := editor.doc
    start := pos
    end := doc.offsetToPos(doc.posToOffset(start) + newText.size)
    caret := doc.modify(Span(start, end), oldText)
    editor.viewport.goto(caret)
  }
}

**************************************************************************
** BatchChange
**************************************************************************

const class BatchChange : Change
{
  new make(Change[] changes) { this.changes = changes }
  const Change[] changes

  override Void undo(Editor editor)
  {
    changes.eachr |c| { c.undo(editor) }
  }
}


