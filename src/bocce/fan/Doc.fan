//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jul 08  Brian Frank  Creation
//

using gfx
using fwt
using syntax

**
** Doc is the line/char/text model for Editor
**
internal class Doc
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Editor editor)
  {
    lines.add(Line { it.offset=0; it.text="" })
    this.editor    = editor
    this.parser    = Parser(this)
    this.delimiter = options.lineDelimiter
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  Editor editor

  EditorOptions options() { editor.options }

  SyntaxRules rules() { editor.rules }

  Str text
  {
    get { return lines.join(delimiter) |Line line->Str| { return line.text } }
    set { modify(Span(homePos, endPos), it) }
  }

  Int charCount() { return size }

  Int colCount() { return maxCol }

  Int lineCount() { return lines.size }

  Str line(Int lineIndex) { return lines[lineIndex].text }

  Int offsetAtLine(Int lineIndex) { return lines[lineIndex].offset }

  const Str lineDelimiter := "\n"

  const Pos homePos := Pos(0, 0)

  Pos endPos() { Pos(lineCount-1, lines[lineCount-1].size) }

  ** Given offset into entire text, get zero based line number
  Int offsetToLine(Int offset)
  {
    // binary search by offset, returns '-insertationPoint-1'
    key := Line { it.offset = offset }
    line := lines.binarySearch(key) |Line a, Line b->Int| { return a.offset <=> b.offset }
    if (line < 0) line = -(line + 2)
    if (line >= lines.size) line = lines.size-1
    return line
  }

  ** Convert offset into entire text into line, col position
  Pos offsetToPos(Int offset)
  {
    line := offsetToLine(offset)
    return Pos(line, offset - lines[line].offset)
  }

  ** Convert line, col position to offset into entire text
  Int posToOffset(Pos pos)
  {
    lines[pos.line].offset + pos.col
  }

  ** Get the text at the given span
  Str textRange(Span span)
  {
    sLine := span.start.line; sCol := span.start.col.min(line(sLine).size)
    eLine := span.end.line;   eCol := span.end.col.min(line(eLine).size)
    if (sLine == eLine) return line(sLine)[sCol..<eCol]

    buf := StrBuf()
    buf.add(line(sLine)[sCol..-1]).add("\n")
    for (i:=sLine+1; i<eLine; ++i)
      buf.add(line(i)).add("\n")
    buf.add(line(eLine)[0..<eCol])
    return buf.toStr
  }

  ** Remove text between span and/or insert new given text
  ** at that position.  Return new position of end of inserted text.
  Pos modify(Span span, Str newText)
  {
    // compute the lines being replaced
    start := span.start
    end   := span.end
    startLineIndex := start.line
    endLineIndex   := end.line
    startLine      := lines[startLineIndex].text
    endLine        := lines[endLineIndex].text
    offsetInStart  := start.col
    offsetInEnd    := end.col

    // if inserting/deleting past end of start/end
    if (newText.size > 0)
    {
      if (start.col >= startLine.size) startLine = startLine + Str.spaces(start.col - startLine.size + 1)
      if (end.col >= endLine.size) endLine = endLine + Str.spaces(end.col - endLine.size + 1)
    }
    else
    {
      if (offsetInStart > startLine.size) offsetInStart = startLine.size
      if (offsetInEnd > endLine.size) offsetInEnd = endLine.size
    }

    // sample styles before insert
//    samplesBefore := [ lineStyling(endLineIndex+1), lineStyling(lines.size-1) ]

    // compute the new text of the lines being replaced
    prefix := startLine[0..<offsetInStart]
    suffix := ""; try { suffix = endLine[offsetInEnd..-1] } catch {}
    newLinesText  :=  prefix + newText + suffix

    // split new text into new lines
    newLines := Line[,] { capacity=32 }
    newLinesText.splitLines.each |Str s|
    {
      newLines.add(parser.parseLine(s))
    }

    // merge in new lines
    lines.removeRange(startLineIndex..endLineIndex)
    lines.insertAll(startLineIndex, newLines)

    // update total size, line offsets, and multi-line comments/strings
    updateLines(lines)

    // sample styles after insert
    /*
    samplesAfter := [ lineStyling(startLineIndex+newLines.size), lineStyling(lines.size-1) ]
    repaintToEnd := samplesBefore != samplesAfter
    */
    editor.repaint

    // fire modification event
    event := Event { id = EventId.modified; widget = editor }
    editor.onModify.fire(event)

    // return position of end of inserted text
    lastLineIndex := startLineIndex + newLines.size -1
    lastLine := lines[lastLineIndex]
    return Pos(lastLineIndex, lastLine.size - (endLine.size-offsetInEnd))
  }

  **
  ** Walk all the lines:
  **   - update offset
  **   - update total size
  **   - compute style override for block comments
  **   - compute style override for multiline strings
  **
  private Void updateLines(Line[] lines)
  {
    n := 0
    lastIndex := lines.size-1
    delimiterSize := delimiter.size
    commentLevel := 0
    commentMin := rules.blockCommentsNest ? 100 : 1
    inStr := false
    maxCol := 0

    // walk the lines
    Block? block := null
    lines.each |Line line, Int i|
    {
      // update offset and total running size
      line.offset = n
      n += line.text.size
      if (i != lastIndex) n += delimiterSize

      // update max column
      maxCol = maxCol.max(line.text.size)

      // update comment nesting count
      commentLevel = (commentLevel + line.commentNesting).max(0).min(commentMin)

      // if not inside a multi-line block, then the current line
      // decides if opening if a new multi-line block (or null);
      // otherwise this line either closes the current open block
      // or is inside the block
      if (block == null)
      {
        line.stylingOverride = null
        block = line.opens
      }
      else
      {
        Line? closes := line.closes(block)
        if (closes == null || commentLevel > 0)
        {
          // override this line as str/comment block
          line.stylingOverride = block.stylingOverride
        }
        else
        {
          // close the current block, and re-parse line appropriately
          line.stylingOverride = closes.styling
          block = closes.opens
        }
      }
    }

    // update total size
    this.size = n
    this.maxCol = maxCol
  }

  Obj[]? lineStyling(Int lineIndex)
  {
    try
    {
      // get configured styling
      line := lines[lineIndex]
      styling := line.stylingOverride ?: line.styling

      // apply bracket styling if current line is matched brackets
      if (lineIndex == bracketLine1 || lineIndex == bracketLine2)
      {
        styling = styling.dup
        lineLen := line.text.size
        if (lineIndex == bracketLine1) insertBracketMatch(styling, bracketCol1, lineLen)
        if (lineIndex == bracketLine2) insertBracketMatch(styling, bracketCol2, lineLen)
      }

      return styling
    }
    catch
    {
      return null
    }
  }

  **
  ** Insert a bracket match style run of one character
  ** at the specified offset.  There are four cases where
  ** "xxx" is run, and "^" is insertion point:
  **
  **     x      a) replace single char run
  **   xxx      b) insert at end
  **     xxx    c) move run to right one char, insert
  **   xxxxx    d) breaking middle of run
  **     ^
  **
  private Void insertBracketMatch(Obj[] styling, Int offset, Int lineLen)
  {
    // find insert point in styling list;
    i := 0; Int iOffset := 0; RichTextStyle iStyle := styling[1]
    for (; i<styling.size; i+=2)
    {
      if (styling[i] >= offset) break
      iStyle = styling[i+1]
    }
    iOffset = i<styling.size ? styling[i] : lineLen

    // compute remaining chars in run
    left := lineLen - offset - 1
    if (i+2<styling.size)
      left = ((Int)styling[i+2]) - offset - 1

    // a) if we are replacing a single char run
    if (offset == iOffset && left == 0)
    {
      styling[i+1] = options.bracketMatch
      return
    }

    // b) if end of run, insert only
    if (left == 0)
    {
      styling.insert(i, options.bracketMatch)
      styling.insert(i, offset)
      return
    }

    // c) if starting a run of more than one character
    if (offset == iOffset)
    {
      styling[i] = offset+1  // move to left one char
      styling.insert(i, options.bracketMatch)
      styling.insert(i, offset)
      return
    }

    // d) we are breaking the middle of run
    styling.insert(i, iStyle)
    styling.insert(i, offset+1)
    styling.insert(i, options.bracketMatch)
    styling.insert(i, offset)
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  **
  ** Load fresh document already parsed into lines.
  **
  internal Void load(Str[] strLines)
  {
    lines = Line[,] { capacity = strLines.size + 100 }
    strLines.each |Str str|
    {
      lines.add(parser.parseLine(str))
    }
    if (lines.isEmpty) lines.add(parser.parseLine(""))
    updateLines(lines)
  }

  **
  ** Save document to output stream (we assume charset
  ** is already configured).
  **
  internal Void save(OutStream out)
  {
    stripws := options.stripTrailingWhitespace
    delimiter := this.delimiter
    lastLine := lines.size-1
    lines.each |Line line, Int i|
    {
      text := line.text
      if (stripws) text = text.trimEnd
      out.print(text)
      if (i != lastLine || text.isEmpty) out.print(delimiter)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Pos? findNext(Str s, Pos? last, Bool matchCase)
  {
    linei := last == null ? 0 : last.line
    coli  := last == null ? 0 : (last.col + s.size).min(lines[linei].text.size)
    while (linei < lines.size)
    {
      line := lines[linei]
      r := matchCase ?
        line.text.index(s, coli) :
        line.text.indexIgnoreCase(s, coli)
      if (r != null) return Pos(linei, r)
      coli = 0 // after first line we always start at zero
      linei++
    }
    return null
  }

  **
  ** Find the specified string in the document starting the
  ** search at the document offset and looking backward.
  ** Return null is not found.  Note we don't currently
  ** support searching across multiple lines.
  **
  /*
  Int? findPrev(Str s, Int offset, Bool matchCase)
  {
    offset = offset.max(0).min(size)
    lineIndex := lineAtOffset(offset)
    offsetInLine := offset - lines[lineIndex].offset

    while (lineIndex >= 0)
    {
      line := lines[lineIndex]
      r := matchCase ?
        line.text.indexr(s, offsetInLine) :
        line.text.indexrIgnoreCase(s, offsetInLine)
      if (r != null) return line.offset+r
      offsetInLine = -1 // after first line we always start at end
      lineIndex--
    }

    return null
  }
  */

  **
  ** Attempt to find the matching bracket the specified
  ** offset.  If the bracket is an opening bracket then
  ** we search forward for the closing bracket taking into
  ** account nesting.  If a closing bracket we search backward.
  ** Return null if no match.
  **
  Pos? matchBracket(Pos pos)
  {
    // check if bracket at given position
    linei := pos.line
    col := pos.col
    Int? a := null
    try
      a = line(linei)[col]
    catch {}
    if (a == null) return null

    // check if bracket and its matching char
    b := bracketPairs[a]
    if (b == null) return null

    forward := a < b
    nesting := 0
    Str? line := line(linei)

    while (true)
    {
      if (line[col] == a) ++nesting
      else if (line[col] == b) --nesting
      if (nesting == 0) return Pos(linei, col)

      if (forward)
      {
        col++
        while (col >= line.size)
        {
          line = lines.getSafe(++linei)?.text
          if (line == null) return null
          col = 0
        }
      }
      else
      {
        col--
        while (col < 0)
        {
          line = lines.getSafe(--linei)?.text
          if (line == null) return null
          col = line.size - 1
        }
      }
    }
    return null
  }

  internal const static Int:Int bracketPairs
  static
  {
    m := Int:Int[:]
    m['{'] = '}'; m['}'] = '{'
    m['('] = ')'; m[')'] = '('
    m['['] = ']'; m[']'] = '['
    m['<'] = '>'; m['>'] = '<'
    bracketPairs = m
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  **
  ** Debug dump of the document.
  **
  Void dump(OutStream out := Env.cur.out)
  {
    out.printLine("")
    out.printLine("==== Doc.dump ===")
    out.printLine("size=$size")
    out.printLine("lines.size=$lines.size")
    out.printLine("delimiter=$delimiter.toCode")
    lines.each |Line line, Int i| { out.printLine("[${i.toStr.justr(3)} @ ${line.offset.toStr.justr(3)}] $line.text.toCode  $line.debug") }
    out.printLine("")
    out.flush
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Int size                  // total char count
  Int maxCol                // max column size
  Line[] lines := Line[,]   // lines
  Str delimiter             // line delimiter
  Parser parser             // to parse lines into styled segments

  Int caretLine             // current line for highlighting
  Int? bracketLine1         // matched bracket 1 line index
  Int? bracketLine2         // matched bracket 2 line index
  Int? bracketCol1          // matched bracket 1 offset in line
  Int? bracketCol2          // matched bracket 2 offset in line
}

**************************************************************************
** Line
**************************************************************************

**
** Line models one text line of a Doc
**
internal class Line
{
  ** Return 'text'.
  override Str toStr() { return text }

  ** Zero based offset from start of document (this
  ** field is managed by the Doc).
  Int offset { internal set; }

  ** Number of chars in line excluding newline
  Int size() { text.size }

  ** Text of line (without delimiter)
  Str text := ""

  ** Offset/RichTextStyle pairs
  Obj[]? styling

  ** Override when line is inside a block comment or multi-line str
  Obj[]? stylingOverride

  ** Opens n comments if > 0 or closes n comments if < 0
  virtual Int commentNesting() { return 0 }

  ** If this line opens a multi-line block (comment/str),
  ** then return a block handle, else null.
  virtual Block? opens() { return null }

  ** If this line closes the specified block, then return the new
  ** line which takes into account that this line is the closing line
  ** of a multi-line comment or string.
  virtual Line? closes(Block open) { return null }

  ** Debug information
  internal virtual Str debug() { return "" }
}

**************************************************************************
** FatLine
**************************************************************************

**
** FatLine subclasses "thin" lines to cache more parsed
** information.  We use a subclass to avoid the extra memory
** overhead on lines which don't need these extra fields.
**
internal class FatLine : Line
{
  ** Opens n comments if > 0 or closes n comments if < 0
  override Int commentNesting := 0

  ** If this line opens a multi-line block (comment/str),
  ** then return a block handle, else null.
  override Block? opens

  ** If this line closes the specified block, then return the new
  ** line which takes into account that this line is the closing line
  ** of a multi-line comment or string.
  override Line? closes(Block open)
  {
    if (closeBlocks == null) return null
    for (i:=0; i<closeBlocks.size; ++i)
    {
      newLine := closeBlocks[i].closes(this, open)
      if (newLine != null) return newLine
    }
    return null
  }

  ** List of blocks this line potentially closes
  ** if used after an opening block
  Block[]? closeBlocks

  ** Debug information
  internal override Str debug()
  {
    return "{$commentNesting, $opens, $closeBlocks}"
  }
}

**************************************************************************
** Block
**************************************************************************

**
** Blocks model multiple line syntax constructs: block comments
** and multi-line strings.
**
internal abstract class Block
{
  ** Which style override should be used inside the block?
  abstract Obj[]? stylingOverride()

  ** If this block marker can be used to close the specified
  ** open block, then return the new line taking into account
  ** that the cur line is closing a mult-line block comment
  ** or str.  Return null if this instance doesn't close open.
  abstract Line? closes(Line line, Block open)
}