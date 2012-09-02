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
  abstract Void execute(Editor editor)
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

  override Void execute(Editor editor)
  {
    doc := editor.doc
    end := doc.offsetToPos(doc.posToOffset(pos) + oldText.size)
    replaceText(editor, Span(pos, end), newText)
  }

  override Void undo(Editor editor)
  {
    doc := editor.doc
    end := doc.offsetToPos(doc.posToOffset(pos) + newText.size)
    replaceText(editor, Span(pos, end), oldText)
  }

  ** replace whatever is in the given span with the given text
  private Void replaceText(Editor editor, Span span, Str text)
  {
    newPos := editor.doc.modify(span, text)
    editor.viewport.goto(newPos)
  }
}
**************************************************************************
** BatchChange
**************************************************************************

const class BatchChange : Change
{
  new make(Change[] changes) { this.changes = changes }

  const Change[] changes

  override Void execute(Editor editor)
  {
    changes.each |c| { c.execute(editor) }
  }

  override Void undo(Editor editor)
  {
    changes.eachr |c| { c.undo(editor) }
  }
}


