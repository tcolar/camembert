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
** Editor is the canvas used to display and edit syntax
** color coded text.
**
class Editor : Canvas
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** It-block constructor
  new make(|This|? f := null)
  {
    if (f != null) f(this)
    this.doubleBuffered = true
    this.viewport = Viewport(this)
    this.controller = Controller(this)
    this.doc = Doc(this)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Options defines alll the colors, styling, key bindings
  const EditorOptions options := EditorOptions()

  ** Syntax rules to use for color coding
  const SyntaxRules rules := SyntaxRules {}

  ** Is editor read only
  const Bool ro := false

//////////////////////////////////////////////////////////////////////////
// I/O
//////////////////////////////////////////////////////////////////////////

  ** Load from lines already parsed into memory
  Void loadLines(Str[] lines) { doc.load(lines) }

  ** Load the document from the given input stream
  Void load(InStream in) { loadLines(in.readAllLines) }

  ** Save the document to the given output stream
  Void save(OutStream out) { doc.save(out) }

//////////////////////////////////////////////////////////////////////////
// Document
//////////////////////////////////////////////////////////////////////////

  ** Number of columns
  Int colCount() { doc.colCount }

  ** Number of lines
  Int lineCount() { doc.lineCount }

  ** Get line string for given zero based line number
  Str line(Int lineNum) { doc.line(lineNum) }

  ** List of spans to highligh in the document
  Span[] highlights := Span[,]
  {
    set { &highlights = it; viewport.relayout }
  }

//////////////////////////////////////////////////////////////////////////
// Navigation
//////////////////////////////////////////////////////////////////////////

  ** Get current caret position
  Pos caret() { viewport.caret }

  ** Move caret and scroll to the given position
  ** and ensure editor is focused
  Void goto(Pos pos)
  {
    viewport.goto(pos, true)
    focus
  }

  ** Current selection or null for no selection
  Span? selection
  {
    get { viewport.getSelection }
    set { viewport.setSelection(it) }
  }

  ** Find the specified string in the document starting the
  ** search at the document offset and looking forward.
  ** Return null is not found.  Note we don't currently
  ** support searching across multiple lines.
  Pos? findNext(Str s, Pos? last, Bool matchCase) { doc.findNext(s, last, matchCase) }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  ** Trap handling of an input event, call
  ** consume if handled by a subclass
  @NoDoc virtual Void trapEvent(Event event) {}

  ** Paint current document state
  override Void onPaint(Graphics g) { viewport.onPaint(g) }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  @NoDoc Bool paintCaret    := true
  @NoDoc Bool paintLeftDiv  := false
  @NoDoc Bool paintRightDiv := false
  @NoDoc Bool paintShowCols := false

  internal Doc doc
  internal Viewport viewport
  internal Controller controller

}

