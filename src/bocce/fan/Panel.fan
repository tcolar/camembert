//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Jun 12  Brian Frank  Creation
//

using gfx
using fwt

**
** Panel is the fundamental scrollable pane used to contain
** an Editor and ItemLists
**
abstract class Panel : Canvas
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make()
  {
    this.doubleBuffered = true
    onMouseDown.add  |e| { mouseDown(e) }
    onMouseMove.add  |e| { mouseMove(e) }
    onMouseUp.add    |e| { mouseUp(e) }
    onMouseWheel.add |e| { mouseWheel(e) }
  }

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  ** Total number of lines
  abstract Int lineCount()

  ** Height of each line
  abstract Int lineh()

  ** Total number of columns
  abstract Int colCount()

  ** Width of each column
  abstract Int colw()

  ** Get inclusive range of lines current in viewport
  Range viewportLines()
  {
    startLine .. startLine.plus(visibleLines).min(lineCount-1)
  }

  ** Get inclusive range of columns current in viewport
  Range viewportCols()
  {
    startCol .. startCol.plus(visibleCols).min(colCount-1)
  }

  ** Scroll so given line is top of viewport
  Void scrollToLine(Int startLine)
  {
    this.startLine = startLine
    lastSize = Size.defVal
    repaint
  }

  ** Scroll so given column is top of viewport
  Void scrollToCol(Int startCol)
  {
    this.startCol = startCol
    lastSize = Size.defVal
    repaint
  }

  ** Point position to logical line
  Int yToLine(Int y) { startLine + (y-margin.top)/lineh }

  ** Point position to logical columns
  Int xToCol(Int x) { startLine + (x-margin.left)/colw}

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    return Size(200, 200)
  }

  private Void doLayout()
  {
    // compute easy stuff
    numLines := this.lineCount
    numCols := this.colCount
    this.visibleLines = (((size.h - margin.toSize.h) / lineh)).min(numLines)
    this.visibleCols  = (size.w - margin.toSize.w) / colw

    // check if startLine needs adjusting
    maxStartLine := (numLines - visibleLines).max(0)
    if (startLine >= maxStartLine) this.startLine = maxStartLine
    if (startLine >= numLines) startLine = numLines - 1
    if (visibleLines >= numLines) startLine = 0
    if (startLine < 0) startLine = 0

    // now we know end line
    this.endLine = startLine + visibleLines
    if (endLine >= numLines) endLine = numLines - 1

    // check if startCol needs adjusting
    maxStartCol := (numCols - visibleCols + 1).max(0)
    if (startCol >= maxStartCol) this.startCol = maxStartCol
    if (startCol < 0) startCol = 0

    // now we know end col
    this.endCol = startCol + visibleCols
    if (endCol >= numCols) endCol = numCols - 1

    // compute/limit size of vertical thumb
    if (visibleLines >= numLines) this.vthumb = null
    else
    {
      vthumb1 := (startLine.toFloat / numLines.toFloat * size.h).toInt
      vthumb2 := ((startLine + visibleLines).toFloat   / numLines.toFloat * size.h).toInt
      vthumbh := vthumb2 - vthumb1
      if (vthumbh < thumbMin) vthumbh = thumbMin
      if (vthumb1 + vthumbh >= size.h) vthumb1 = size.h - vthumbh - 1
      this.vthumb = Rect(size.w - vthumbw-1, vthumb1, vthumbw, vthumbh)
    }

    // compute/limit size of horizontal thumb
    if (visibleCols >= numCols) this.hthumb = null
    else
    {
      hthumb1 := (startCol.toFloat / numCols.toFloat * size.w).toInt
      hthumb2 := (endCol.toFloat   / numCols.toFloat * size.w).toInt
      hthumbw := hthumb2 - hthumb1
      if (hthumbw < thumbMin) hthumbw = thumbMin
      if (hthumb1 + hthumbw >= size.w) hthumb1 = size.w - hthumbw - 1
      this.hthumb = Rect(hthumb1, size.h - hthumbh, hthumbw, hthumbh)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////

  override final Void onPaint(Graphics g)
  {
    if (lastSize != this.size || lastLineCount != this.lineCount)
    {
      lastLineCount = lineCount
      lastSize = size
      doLayout
    }

    // wallpaper background
    g.antialias = true
    w := size.w; h := size.h
    g.brush = wallpaperColor
    g.fillRect(0, 0, w, h)

    // rounded background
    g.brush = viewportColor
    g.fillRoundRect(0, 0, w-1, h-1, 10, 10)

    // viewport
    if (lineCount > 0)
    {
      g.push
      g.translate(margin.left - startCol*colw, margin.top)
      onPaintLines(g, viewportLines)
      g.pop
    }

    // vertical scrollbar gutters
    if (vthumb != null)
    {
      g.brush = gutterColor
      g.fillRoundRect(vthumb.x, 0, vthumb.w, size.h-1, 10, 10)
      g.fillRect(vthumb.x, 0, 5, size.h-1)
      g.brush = gutterBorder
      g.drawLine(vthumb.x, 0, vthumb.x, size.h)
    }

    // horizontal scrollbar gutter
    if (hthumb != null)
    {
      g.brush = gutterColor
      g.fillRect(1, hthumb.y, size.w-2, hthumb.h)
      g.brush = gutterBorder
      g.drawLine(1, hthumb.y, size.w-2, hthumb.y)
    }

    // border corners
    g.brush = borderColor
    g.drawRoundRect(0, 0, w-1, h-1, 10, 10)

    // vertical thumb
    if (vthumb != null)
    {
      g.brush = thumbColor
      g.fillRoundRect(vthumb.x, vthumb.y, vthumb.w, vthumb.h, 10, 10)
    }

    // hozitonal thumb
    if (hthumb != null)
    {
      g.brush = thumbColor
      g.fillRoundRect(hthumb.x, hthumb.y, hthumb.w, hthumb.h, 10, 10)
    }
  }

  **
  ** Paint the viewport's given range of lines.  The viewport
  ** is already translated for scroll position so that 0,0 represents
  ** the top, left corner of current scroll line/col.
  **
  abstract Void onPaintLines(Graphics g, Range lines)

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  private Void mouseDown(Event e)
  {
    pos := e.pos
    if (vthumb != null && vthumb.contains(pos.x, pos.y))
    {
      e.consume
      vdrag = pos.y - vthumb.y
      return
    }
    if (hthumb != null && hthumb.contains(pos.x, pos.y))
    {
      e.consume
      hdrag = pos.x - hthumb.x
      return
    }
  }

  private Void mouseMove(Event e)
  {
    pos := e.pos
    if (vdrag != null)
    {
      e.consume
      thumby := pos.y - vdrag
      line := ((thumby.toFloat / size.h.toFloat) * lineCount.toFloat).toInt
      scrollToLine(line)
    }
    if (hdrag != null)
    {
      e.consume
      thumbx := pos.x - hdrag
      col := ((thumbx.toFloat / size.w.toFloat) * colCount.toFloat).toInt
      scrollToCol(col)
    }
  }

  private Void mouseUp(Event e)
  {
    if (vdrag != null) { e.consume; vdrag = null }
    if (hdrag != null) { e.consume; hdrag = null }
  }

  internal Void mouseWheel(Event e)
  {
    if (e.delta.y != 0)
    {
      e.consume
      scrollToLine(startLine + e.delta.y)
    }
  }


//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static const Color wallpaperColor := Desktop.sysBg
  static const Color viewportColor  := Color.white
  static const Color borderColor    := Color(0x88_88_88)
  static const Color gutterColor    := Color(0xee_ee_ee)
  static const Color gutterBorder   := Color(0xdd_dd_dd)
  static const Color thumbColor     := Color(0xbb_bb_bb)

  static const Insets margin := Insets(6, 6, 6, 6)
  static const Int vthumbw   := 9
  static const Int hthumbh   := 9
  static const Int thumbMin  := 30

  private Size lastSize := Size.defVal // check for layout
  private Int lastLineCount            // last number of lines
  private Int startLine                // line at top of viewport
  private Int endLine                  // line at bottom of viewport
  private Int startCol                 // column at left of viewport
  private Int endCol                   // column at right of viewport
  private Int visibleLines             // num viewable lines
  private Int visibleCols              // num viewable columns
  private Rect? vthumb                 // vertical thumb
  private Rect? hthumb                 // horizontal thumb
  private Int? vdrag                   // if drag in progress
  private Int? hdrag                   // if drag in progress
}