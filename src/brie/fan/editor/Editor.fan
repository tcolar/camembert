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

**
** Editor
**
class Editor : Canvas
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(App? app, FileRes res)
  {
    this.app = app
    this.res = res
    this.file = res.file
    this.doubleBuffered = true

    // read document into memory, if we fail with the
    // configured charset, then fallback to ISO 8859-1
    // which will always "work" since it is byte based
    lines := readAllLines
    if (lines == null)
    {
      this.charset = Charset.fromStr("ISO-8859-1")
      lines = readAllLines
    }

    // save this time away to check on focus events
    this.fileTimeAtLoad = file.modified

    // figure out what syntax file to use
    // based on file extension and shebang
    this.rules = SyntaxRules.loadForFile(file, lines.first)
    if (rules == null) this.rules = SyntaxRules {}

    // load document
    this.doc = Doc(this)
    doc.load(lines)

    // create viewport
    this.viewport = Viewport(this)

    // map input events to controller
    this.controller = Controller(this)
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

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  ** Goto zero based line number and column number
  Void goto(Mark mark)
  {
    viewport.goto(mark.line, mark.col)
    focus
  }


  Void markLine(Int? line)
  {
    this.markLineIndex = line
    if (line != null) viewport.goto(line, 0)
    repaint
  }

//////////////////////////////////////////////////////////////////////////
// Paint
//////////////////////////////////////////////////////////////////////////

  override Void onPaint(Graphics g)
  {
    viewport.onPaint(g)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  App? app
  const Options options := Options()
  const FileRes res
  const File file
  const DateTime fileTimeAtLoad
  const Charset charset := options.charset
  const SyntaxRules? rules
  const Bool multiLine := true
  Doc doc { private set }
  internal Viewport viewport { private set }
  internal Controller controller { private set }
  internal Bool paintCaret := true
  internal Bool paintLeftDiv := false
  internal Bool paintRightDiv := false
  internal Bool paintShowCols := false
  internal Int? markLineIndex

}

