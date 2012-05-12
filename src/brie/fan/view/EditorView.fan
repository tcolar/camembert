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
using bocce

**
** EditorView
**
class EditorView : View
{
  new make(App app, FileRes res) : super(app, res)
  {
    this.file = res.file
    this.fileTimeAtLoad = file.modified

    // read document into memory, if we fail with the
    // configured charset, then fallback to ISO 8859-1
    // which will always "work" since it is byte based
    lines := readAllLines
    if (lines == null)
    {
      this.charset = Charset.fromStr("ISO-8859-1")
      lines = readAllLines
    }

    // get rules for ext or first line
    rules := SyntaxRules.loadForFile(file, lines.first)
    if (rules == null) rules = SyntaxRules {}

    // construct and load editor
    editor = Editor { it.rules = rules }
    editor.onFocus.add |e| { onFocusCheckFileTime }
    editor.onModify.add |e| { this.dirty = true }
    editor.onCaret.add |e| { app.status.refresh }
    editor.loadLines(lines)
    editor.onKeyDown.add |e|
    {
      if (!e.consumed) app.controller.onKeyDown(e)
      if (!e.consumed) editorKeyDown(e)
    }

    // hidden hooks
    editor->paintLeftDiv  = true
    editor->paintRightDiv = true
    editor->paintShowCols = true

    this.content = editor
  }

  private Str[]? readAllLines()
  {
    in := file.in { it.charset = this.charset }
    try
      return in.readAllLines
    catch
      return null
    finally
      in.close
  }

  Editor editor

  override Pos curPos() { editor.caret }

  override Void onReady()
  {
    editor.highlights = Span[,]
    editor.focus
  }

  override Void onSave()
  {
    out := file.out
    try
      editor.save(out)
    finally
      out.close
    fileTimeAtLoad = file.modified
  }

  override Void onGoto(Mark mark)
  {
    editor.goto(mark.pos, true)
    editor.focus
  }

  override Void onMarks(Mark[] marks)
  {
    editor.repaint
  }

  private Void onFocusCheckFileTime ()
  {
    if (file.modified == fileTimeAtLoad) return
    fileTimeAtLoad = file.modified

    // prompt user to reload
    r := Dialog.openQuestion(editor.window,
          "Another application has updated file:
           $file.osPath
           Reload it?", Dialog.yesNo)
    if (r == Dialog.yes) app.reload
  }


  private Void editorKeyDown(Event event)
  {
    if (editor.ro) return
    switch (event.key.toStr)
    {
      case "Ctrl+=": event.consume; insertSection
    }
  }

  private Void insertSection()
  {
    linei := editor.caret.line

    previ := linei-1
    while (previ > 0 && editor.line(previ).trim.isEmpty) previ--
    prev := editor.line(previ)

    nexti := linei
    while (nexti < editor.lineCount && editor.line(nexti).trim.isEmpty) nexti++

    char := prev.startsWith("}") ? "*" : "/"

    s := StrBuf()
    gotoi := linei+1
    if (previ == linei - 1) { s.add("\n"); gotoi++ }
    74.times { s.add(char) }
    s.add("\n").add(char).add(char).add(" ").add("\n")
    74.times { s.add(char) }
    s.add("\n")
    if (nexti == linei) s.add("\n")

    editor.modify(Pos(linei, 0).toSpan, s.toStr)
    editor.goto(Pos(gotoi, 3))
  }

  const File file
  const Charset charset := Charset.utf8
  private DateTime fileTimeAtLoad

}

