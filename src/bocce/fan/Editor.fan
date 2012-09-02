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
class Editor : Panel
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
    this.cursor = Cursor.text
    this.lineh = options.font.height
    this.colw  = options.font.width("w")
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

  ** Callback when the text is modified.
  once EventListeners onModify() { EventListeners() }

  ** Callback when the caret position is modified.
  once EventListeners onCaret() { EventListeners() }

//////////////////////////////////////////////////////////////////////////
// I/O
//////////////////////////////////////////////////////////////////////////

  ** Load from lines already parsed into memory
  Void loadLines(Str[] lines) { doc.load(lines) }

  ** Load the document from the given input stream
  Void load(InStream in) { loadLines(in.readAllLines) }

  ** Save the document to the given output stream
  Void save(OutStream out) { doc.save(out) }

  ** Remove text between span and/or insert new given text
  ** at that position.  Return new position of end of inserted text.
  Void modify(Span span, Str newText) { controller.modify(span, newText) }

  ** Get text for the given span
  Str textForSpan(Span span) { doc.textRange(span) }

//////////////////////////////////////////////////////////////////////////
// Document
//////////////////////////////////////////////////////////////////////////

  ** Number of columns
  override Int colCount() { doc.colCount }

  ** Number of lines
  override Int lineCount() { doc.lineCount }

  ** Height of each line
  override const Int lineh

  ** Width of each column
  override const Int colw

  ** Get line string for given zero based line number
  Str line(Int lineNum) { doc.line(lineNum) }

  ** List of spans to highligh in the document
  Span[] highlights := Span[,]
  {
    set { &highlights = it; repaint }
  }

  ** Position of document end
  Pos docEndPos() { doc.endPos }

//////////////////////////////////////////////////////////////////////////
// Navigation
//////////////////////////////////////////////////////////////////////////

  ** Get current caret position
  Pos caret() { viewport.caret }

  ** Move caret and scroll to the given position
  ** and ensure editor is focused
  Void goto(Pos pos)
  {
    viewport.goto(pos)
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

  override Void onPaintBackground(Graphics g) { viewport.onPaintBackground(g) }

  override Void onPaintLines(Graphics g, Range lines) { viewport.onPaintLines(g, lines) }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal Doc doc
  @NoDoc Viewport viewport
  @NoDoc Controller controller

}

