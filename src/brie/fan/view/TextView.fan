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
class TextView : View
{
  new make(Frame frame, File file) : super(frame, file)
  {
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
    editor = Editor
    {
      it.rules = rules
      it.options.bg = Sys.cur.theme.edBg
      it.options.font = Sys.cur.theme.edFont
      it.options.bgCurLine = Sys.cur.theme.edCurLineBg
      it.options.highlight = Sys.cur.theme.edSelectBg
      it.options.showCols = Sys.cur.theme.edCols
      it.options.showColColor = Sys.cur.theme.edColsColor
      it.options.bracket = Sys.cur.theme.edBracket
      it.options.bracketMatch = Sys.cur.theme.edBracketMatch
      it.options.comment = Sys.cur.theme.edComment
      it.options.keyword = Sys.cur.theme.edKeyword
      it.options.numLiteral = Sys.cur.theme.edNum
      it.options.strLiteral = Sys.cur.theme.edStr
      it.options.text = Sys.cur.theme.edText
      it.options.lineNumberColor = Sys.cur.theme.lineNumberColor
      it.options.caretColor = Sys.cur.theme.caretColor
      it.options.scrollFg  = Sys.cur.theme.scrollFg
      it.options.scrollBg  = Sys.cur.theme.scrollBg
      it.gutterColor =  Sys.cur.theme.scrollBg
      it.thumbColor = Sys.cur.theme.scrollFg
    }
    editor.onFocus.add |e| { onFocusCheckFileTime }
    editor.onModify.add |e| { this.dirty = true }
    editor.onCaret.add |e| { frame.updateStatus }
    editor.loadLines(lines)
    editor.onKeyDown.add |e|
    {
      if (!e.consumed) frame.trapKeyDown(e)
      if (!e.consumed) editorKeyDown(e)
    }

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

  ** Current selected string or empty
  override Str curSelection()
  {
    span := editor.selection
    if (span == null) return ""
    return editor.textForSpan(span)
  }

  override Pos curPos() { editor.caret }

  override Void onReady() { editor.focus }

  override Str curStatus()
  {
    pos := curPos
    return "$charset   ${pos.line+1}:${pos.col+1}"
  }


  override Void onGoto(Item item)
  {
    editor.selection = item.loc.span
    editor.goto(item.pos)
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

  private Void onFocusCheckFileTime ()
  {
    if (file.modified == fileTimeAtLoad) return
    fileTimeAtLoad = file.modified

    // prompt user to reload
    r := Dialog.openQuestion(editor.window,
          "Another application has updated file:
           $file.osPath
           Reload it?", Dialog.yesNo)
    if (r == Dialog.yes) frame.curSpace.refresh
  }

  private Void editorKeyDown(Event event)
  {
    if (editor.ro) return

    switch (event.key.toStr)
    {
      case Sys.cur.shortcuts.insertCommentSection : event.consume; insertSection
      case Sys.cur.shortcuts.toggleComment        : event.consume; toggleCommentBlock
    }
  }

  private Void toggleCommentBlock()
  {
    curLine := editor.caret.line
    lines := curLine..curLine
    sel := editor.selection
    if (sel != null)
    {
      if (sel.end.line > sel.start.line && sel.end.col == 0)
        lines = sel.start.line .. sel.end.line-1
      else
        lines = sel.start.line .. sel.end.line
    }
    lines.each |linei|
    {
      line := editor.line(linei)
      if (line.startsWith("// "))
        editor.modify(Span(linei, 0, linei, 3), "")
      else
        editor.modify(Pos(linei, 0).toSpan, "// ")
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

  const Charset charset := Charset.utf8
  private DateTime fileTimeAtLoad

}

