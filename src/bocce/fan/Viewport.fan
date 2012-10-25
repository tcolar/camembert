//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using syntax

**
** Viewport
**
@NoDoc
class Viewport
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Editor editor)
  {
    this.editor = editor
  }

//////////////////////////////////////////////////////////////////////////
// Conveniences
//////////////////////////////////////////////////////////////////////////

  internal Doc doc() { editor.doc }

  EditorOptions options() { editor.options }

  Font font() { editor.options.font }

  Controller controller() { editor.controller }

//////////////////////////////////////////////////////////////////////////
// Positioning
//////////////////////////////////////////////////////////////////////////

  Pos pointToPos(Point pt)
  {
    Pos(pointToLine(pt), pointToCol(pt))
  }

  Int pointToLine(Point pt) { editor.yToLine(pt.y) }

  Int pointToCol(Point pt) { editor.xToCol(pt.x+3) }

  Int colToX(Int col) { editor.colToX(col) }

  Int lineToY(Int line) { editor.lineToY(line) }

  Int lineh() { editor.lineh }

  Int colw() { editor.colw }

//////////////////////////////////////////////////////////////////////////
// Caret
//////////////////////////////////////////////////////////////////////////

  Pos caret() { Pos(caretLine, caretCol) }

  Void pageUp()
  {
    view := editor.viewportLines
    page := (view.end - view.start - 4).max(10)
    caretLine -= page
    scrollToLine(view.start - page)
    updateCaret
  }

  Void pageDown()
  {
    view := editor.viewportLines
    page := (view.end - view.start - 4).max(10)
    caretLine += page
    scrollToLine(view.start + page)
    updateCaret
  }

  Void goto(Pos caret)
  {
    if (caretLine == caret.line && caretCol == caret.col) return

    caretLine = caret.line
    caretCol  = caret.col

    // check for bracket match
    brackets = null
    if (caretCol > 0)
    {
      before := Pos(caretLine, caretCol-1)
      match := doc.matchBracket(before)
      if (match != null) brackets = Span(before, match)
    }

    updateCaret
    editor.onCaret.fire(Event { id = EventId.caret; widget = editor })
  }

  private Void updateCaret()
  {
    checkCaret
    editor.repaint
  }

  private Void checkCaret()
  {
    // check caret needs adjusting
    if (caretLine >= editor.lineCount) caretLine = editor.lineCount - 1
    if (caretLine < 0) caretLine = 0
    if (caretCol < 0) caretCol = 0

    lineSize := doc.line(caretLine).size
    if (caretCol >= lineSize) caretCol = lineSize

    // check caret line is visible, if big jump then
    // center caret 1/3 down from top of viewport
    view := editor.viewportLines
    viewNum := view.end - view.start
    if (caretLine < view.start)
    {
      if (caretLine < view.start - 2)
        scrollToLine(caretLine - viewNum/3)
      else
        scrollToLine(caretLine)
    }
    if (caretLine >= view.end)
    {
      if (caretLine > view.end + 2)
        scrollToLine(caretLine - viewNum/3)
      else
        scrollToLine(caretLine - viewNum + 1)
    }

    // check caret col is visible
    colView := editor.viewportCols
    colViewNum := colView.end - colView.start
    if (caretCol < colView.start) scrollToCol(caretCol)
    if (caretCol >= colView.end) scrollToCol(caretCol - colViewNum + 1)
  }

  private Void scrollToLine(Int startLine) { editor.scrollToLine(startLine) }

  private Void scrollToCol(Int startCol) { editor.scrollToCol(startCol) }

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

  Span? getSelection() { selection }

  Void setSelection(Span? selection)
  {
    this.selection = selection
    editor.repaint
  }

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////

  Void repaintLine(Int line)
  {
    y := lineToY(line)
    editor.repaint(Rect(0, y, editor.size.w, lineh))
  }

  Void onPaintBackground(Graphics g)
  {
    g.brush = options.bg
    g.fillRect(0, 0, editor.size.w, editor.size.h)

    if (options.showCols.isEmpty) return

    oldPen := g.pen
    g.brush = options.showColColor
    g.pen   = options.showColPen
    options.showCols.each |col|
    {
      x := colToX(col)
      g.drawLine(x, 0, x, editor.size.h)
    }
    g.pen = oldPen
  }

  Void onPaintLines(Graphics g, Range range)
  {
    g.push
    g.font  = font
    g.brush = Color.black

    linex := 0
    liney := 0

    range.each |linei|
    {
      paintLine(g, linex, liney, linei)
      liney += lineh
    }

    g.pop
  }

  private Void paintLine(Graphics g, Int linex, Int liney, Int linei)
  {
    // skip if line not in clip bounds
    clip := g.clipBounds
    if (liney + lineh < clip.y || liney > clip.y + clip.h) return

    // if focus and current line highlight entire line
    focused := editor.hasFocus
    if (focused && linei == caretLine)
    {
      g.brush = options.bgCurLine
      g.fillRect(0, liney, 10_000, lineh)
    }

    // highlight spans in this line
    g.brush = options.highlight
    editor.highlights.each |span|
    {
      if (span.start.line != linei || span.end.line != linei) return
      x1 := linex + colw * span.start.col
      x2 := linex + colw * span.end.col
      if (span.start.col == 0 && span.end.col > 1000) x1 = 0
      g.fillRect(x1, liney, x2-x1, lineh)
    }

    // bracket match higlights
    if (brackets != null)
    {
      g.brush = options.highlight
      if (brackets.start.line == linei)
        g.fillRect(linex  + brackets.start.col*colw, liney, colw, lineh)
      if (brackets.end.line == linei)
        g.fillRect(linex  + brackets.end.col*colw, liney, colw, lineh)
    }

    // styled text (actual line content)
    linex0   := linex
    line     := doc.line(linei)
    styling  := doc.lineStyling(linei) ?: [0, RichTextStyle()]
    for (i := 0; i < styling.size; i += 2)
    {
      start := (Int)styling[i]
      style := (RichTextStyle)styling[i+1]
      end   := styling.getSafe(i+2) as Int ?: line.size
      text  := line[start..<end]
      textw := g.font.width(text)
      if (style.bg != null)
      {
          g.brush = style.bg
          g.fillRect(linex, liney, textw, lineh)
      }
      g.brush = style.fg
      g.drawText(text, linex, liney)

      linex += textw
    }

    // not the most efficient, but just overlay selected text
    if (selection != null && selection.containsLine(linei))
    {
      cs := selection.start.line == linei ? selection.start.col : 0
      ce := selection.end.line == linei ? selection.end.col : line.size
      if (ce >= line.size) ce = line.size
      textx := linex0 + cs*colw
      text  := ""; try text = line[cs..<ce]; catch {}
      textw := text.size * colw

      g.brush = options.selectBg
      g.fillRect(textx, liney, textw, lineh)
      g.brush = options.selectFg
      g.drawText(text, textx, liney)
    }

    // caret for line
    if (focused && linei == caretLine && controller.caretVisible)
    {
      caretx := linex0 + (caretCol * colw)
      g.brush = Color.black
      g.drawLine(caretx, liney, caretx, liney+lineh)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Editor editor          // parent
  private Int caretLine          // current line of caret
  private Int caretCol           // current col of caret
  private Span? brackets         // matched bracket
  private Span? selection        // current selection

}

