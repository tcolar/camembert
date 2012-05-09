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
internal class Viewport
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Editor editor)
  {
    this.editor     = editor
    this.size       = Size.defVal
    this.vthumb     = Rect.defVal
    this.hthumb     = Rect.defVal
    this.highlights = Int:Span[][:]
  }

//////////////////////////////////////////////////////////////////////////
// Conveniences
//////////////////////////////////////////////////////////////////////////

  Doc doc() { editor.doc }

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

  Int pointToLine(Point pt)
  {
    y := pt.y - margin.top
    line := startLine + y / lineh
    if (line < startLine) return startLine
    if (line > endLine) return endLine
    return line
  }

  Int pointToCol(Point pt)
  {
    x := pt.x - margin.left
    col := startCol + (x + 3) / colw
    if (col < startCol) return startCol
    if (col > endCol) return endCol
    return col
  }

//////////////////////////////////////////////////////////////////////////
// Caret
//////////////////////////////////////////////////////////////////////////

  Pos caret() { Pos(caretLine, caretCol) }

  Void pageUp()   { page := visibleLines - 4; caretLine -= page; startLine -= page; updateCaret(true) }
  Void pageDown() { page := visibleLines - 4; caretLine += page; startLine += page; updateCaret(true) }

  Void goto(Pos caret, Bool jump := false)
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

    if (jump) startLine = caret.line - visibleLines/3
    updateCaret
    editor.onCaret.fire(Event { id = EventId.caret; widget = editor })
  }

  private Void updateCaret(Bool vhover := false)
  {
    checkCaret
    if (vhover) vbarHover
    relayout
  }

  private Void checkCaret()
  {
    // check caret needs adjusting
    if (caretLine >= docLines) caretLine = docLines-1
    if (caretLine < 0) caretLine = 0
    if (caretCol < 0) caretCol = 0
    if (caretCol >= docCols) caretCol = docCols

    // check caret line is visible
    if (caretLine < startLine) startLine = caretLine
    if (caretLine >= startLine + visibleLines) startLine = caretLine - visibleLines + 1

    // check caret col is visible
    if (caretCol < startCol) startCol = caretCol
    if (caretCol >= startCol + visibleCols) startCol = caretCol - visibleCols + 1
  }

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
// Scrolling
//////////////////////////////////////////////////////////////////////////

  Int? vthumbDragStart(Point pt)
  {
    if (!vthumb.contains(pt.x, pt.y)) return null
    return pt.y - vthumb.y
  }

  Void vthumbDrag(Int start, Point pt)
  {
    thumby := pt.y - start
    startLine = ((thumby.toFloat / size.h.toFloat) * docLines.toFloat).toInt
    vbarHover
    relayout
  }

  Int? hthumbDragStart(Point pt)
  {
    if (!hthumb.contains(pt.x, pt.y)) return null
    vbarHovering = null
    return pt.x - hthumb.x
  }

  Void hthumbDrag(Int start, Point pt)
  {
    thumbx := pt.x - start
    startCol = ((thumbx.toFloat / size.w.toFloat) * docCols.toFloat).toInt
    relayout
  }

  Void vscroll(Int delta)
  {
    startLine = (startLine + delta).max(0)
    vbarHover
    relayout
  }

  private Void vbarHover()
  {
    vbarHovering = Duration.now + barHover
    Desktop.callLater(barHover) |->|
    {
      if (Duration.now < vbarHovering) return
      vbarHovering = null
      editor.repaint
    }
  }

//////////////////////////////////////////////////////////////////////////
// Relayout
//////////////////////////////////////////////////////////////////////////

  Void relayout()
  {
    this.size = Size.defVal
    editor.repaint
  }

  Void checkLayout()
  {
    if (editor.size != this.size || doc.lineCount != this.docLines)
      onRelayout
  }

  Void onRelayout()
  {
    this.size         = editor.size
    this.lineh        = font.height
    this.colw         = font.width("m")
    this.docLines     = doc.lineCount
    this.docCols      = doc.colCount
    this.visibleLines = (((size.h-margin.toSize.h) / lineh)).min(docLines)
    this.visibleCols  = (((size.w-margin.toSize.w) / colw)).min(docCols)

    // check if startLine needs adjusting
    maxStartLine := (docLines - visibleLines + 1).max(0)
    if (startLine >= maxStartLine) this.startLine = maxStartLine
    if (startLine >= docLines) startLine = docLines - 1
    if (visibleLines >= docLines) startLine = 0
    if (startLine < 0) startLine = 0

    // now we know end line
    this.endLine = startLine + visibleLines
    if (endLine >= docLines) endLine = docLines - 1

    // check if startCol needs adjusting
    maxStartCol := (docCols - visibleCols + 1).max(0)
    if (startCol >= maxStartCol) this.startCol = maxStartCol
    if (startCol < 0) startCol = 0

    // now we know end col
    this.endCol = startCol + visibleCols
    if (endCol >= docCols) endCol = docCols - 1

    // compute/limit size of vertical thumb
    vthumb1 := (startLine.toFloat / docLines.toFloat * size.h).toInt
    vthumb2 := (endLine.toFloat   / docLines.toFloat * size.h).toInt
    vthumbh := vthumb2 - vthumb1
    if (vthumbh < thumbMin) vthumbh = thumbMin
    if (vthumb1 + vthumbh > size.h) vthumb1 = size.h - vthumbh
    this.vthumb = Rect(size.w - thumbSize, vthumb1, thumbSize, vthumbh)

    // compute/limit size of horizontal thumb
    hthumb1 := (startCol.toFloat / docCols.toFloat * size.w).toInt
    hthumb2 := (endCol.toFloat   / docCols.toFloat * size.w).toInt
    hthumbw := hthumb2 - hthumb1
    if (hthumbw < thumbMin) hthumbw = thumbMin
    if (hthumb1 + hthumbw > size.w) hthumb1 = size.w - hthumbw
    this.hthumb = Rect(hthumb1, size.h - thumbSize, hthumbw, thumbSize)

    // compute visible highlights
    highlights.clear
    editor.highlights.each |span|
    {
      // for now skip multi-line highlights
      if (span.start.line != span.end.line) return
      line := span.start.line
      if (startLine <= line && line <= endLine)
      {
        x := highlights[line]
        if (x == null) highlights[line] = [span]
        else x.add(span)
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////

  Void onPaint(Graphics g)
  {
    checkLayout
    paintBackground(g)
    paintShowCols(g)
    paintLines(g)
    paintDivs(g)
    paintScroll(g)
  }

  private Void paintBackground(Graphics g)
  {
    g.brush = options.bg
    g.fillRect(0, 0, size.w, size.h)
  }

  private Void paintLines(Graphics g)
  {
    g.push
    g.font  = font
    g.brush = Color.black

    if (startCol > 0) g.translate(-startCol*colw, 0)

    linex := margin.left
    liney := margin.top

    (startLine..endLine).each |linei|
    {
      paintLine(g, linex, liney, linei)
      liney += lineh
    }

    g.pop
  }

  private Void paintLine(Graphics g, Int linex, Int liney, Int linei)
  {
    // if focus and current line highlight entire line
    focused := editor.controller.focused
    if (focused && linei == caretLine)
    {
      g.brush = options.bgCurLine
      g.fillRect(0, liney, 10_000, lineh)
    }

    // highlight spans in this line
    highlights := this.highlights[linei]
    if (highlights != null)
    {
      g.brush = options.highlight
      highlights.each |span|
      {
        x1 := linex + colw * span.start.col
        x2 := linex + colw * span.end.col
        if (span.start.col == 0 && span.end.col > 1000) x1 = 0
        g.fillRect(x1, liney, x2-x1, lineh)
      }
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
    if (focused && linei == caretLine && editor.paintCaret)
    {
      caretx := linex0 + (caretCol * colw)
      g.brush = Color.black
      g.drawLine(caretx, liney, caretx, liney+lineh)
    }
  }

  private Void paintDivs(Graphics g)
  {
    g.brush = options.div
    if (editor.paintLeftDiv)
    {
      g.drawLine(0, 0, 0, size.h)
      g.drawLine(1, 0, 1, size.h)
    }

    if (editor.paintRightDiv)
    {
      g.drawLine(size.w-1, 0, size.w-1, size.h)
      g.drawLine(size.w-2, 0, size.w-2, size.h)
    }
  }

  private Void paintShowCols(Graphics g)
  {
    if (!editor.paintShowCols || options.showCols.isEmpty) return

    oldPen := g.pen
    g.brush = options.showColColor
    g.pen   = options.showColPen
    options.showCols.each |col|
    {
      x := margin.left + colw*col
      g.drawLine(x, 0, x, size.h)
    }
    g.pen = oldPen
  }

  private Void paintScroll(Graphics g)
  {
    // vertical thumb
    if (controller.vbarVisible || vbarHovering != null)
    {
      g.brush = options.scrollBg
      g.fillRect(vthumb.x, 0, vthumb.w, size.h)
      g.brush = options.scrollFg
      g.fillRoundRect(vthumb.x, vthumb.y, vthumb.w, vthumb.h, 8, 8)
    }

    // horizontal thumb
    if (controller.hbarVisible)
    {
      g.brush = options.scrollBg
      g.fillRect(0, hthumb.y, size.w, hthumb.h)
      g.brush = options.scrollFg
      g.fillRoundRect(hthumb.x, hthumb.y, hthumb.w, hthumb.h, 8, 8)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static const Insets margin     := Insets(10, 0, 2, 10)
  static const Int thumbSize     := 10
  static const Int thumbMin      := 30
  static const Duration barHover := 1500ms

  private Editor editor          // parent
  private Size size              // last relayout size
  private Int lineh              // height of each line
  private Int colw               // fudged column width
  private Int docLines           // number of lines in doc
  private Int docCols            // number of columns in doc
  private Int visibleLines       // number of visible lines in viewport
  private Int visibleCols        // number of visible cols in viewport
  private Int caretLine          // current line of caret
  private Int caretCol           // current col of caret
  private Int startLine          // index of top visible line
  private Int endLine            // index of bottom visible line
  private Int startCol           // index of left visible col
  private Int endCol             // index of right visible col
  private Rect vthumb            // bounds for vertical thumb
  private Rect hthumb            // bounds for horizontal thumb
  private Duration? vbarHovering // temp display of vertical scroll
  private Int:Span[] highlights  // visible highlights
  private Span? brackets         // matched bracket
  private Span? selection        // current selection

}

