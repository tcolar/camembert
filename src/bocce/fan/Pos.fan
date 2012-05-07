//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 08  Brian Frank  Creation
//

using fwt
using syntax

**
** Position in the document as zero based line and column number
**
const final class Pos
{
  ** Construct with zero based line and column
  new make(Int line, Int col)
  {
    this.line = line
    this.col  = col
  }

  ** Zero based line number
  const Int line

  ** Zero based column number
  const Int col

  ** Hash based on line and col
  override Int hash() { line.shiftl(8).xor(col) }

  ** Equality is based on line and col
  override Bool equals(Obj? that)
  {
    x := that as Pos
    if (x == null) return false
    return this.line == x.line && this.col == x.col
  }

  ** Compare by line, then col
  override Int compare(Obj that)
  {
    x := (Pos)that
    if (this.line < x.line) return -1
    if (this.line > x.line) return 1
    return this.col <=> x.col
  }

  ** Return zero based "line:col"
  override Str toStr() { "$line:$col" }

//////////////////////////////////////////////////////////////////////////
// Navigation
//////////////////////////////////////////////////////////////////////////

  internal Pos up(Doc doc)
  {
    if (line == 0) return this
    return Pos(line-1, col)
  }

  internal Pos down(Doc doc)
  {
    if (line >= doc.lineCount-1) return this
    return Pos(line+1, col)
  }

  internal Pos left(Doc doc)
  {
    if (col > 0) return Pos(line, col-1)
    if (line == 0) return this
    return Pos(line-1, doc.lines[line-1].size)
  }

  internal Pos right(Doc doc)
  {
    if (col <= doc.lines[line].size-1) return Pos(line, col+1)
    if (line >= doc.lineCount-1) return this
    return Pos(line+1, 0)
  }

  internal Pos home(Doc doc)
  {
    line := doc.line(this.line)
    nonws := 0
    while (nonws < line.size && line[nonws].isSpace) nonws++
    c := this.col <= nonws ? 0 : nonws
    return Pos(this.line, c)
  }

  internal Pos end(Doc doc)
  {
    Pos(line, doc.line(line).size)
  }

  internal Pos prevWord(Doc doc)
  {
    c := this.col
    if (c <= 0) return left(doc)
    line := doc.line(this.line)
    if (c >= line.size) c = line.size
    while (c > 0 && !isWord(line[c-1])) --c
    while (c > 0 && isWord(line[c-1])) --c
    return Pos(this.line, c)
  }

  internal Pos nextWord(Doc doc)
  {
    c := this.col
    line := doc.line(this.line)
    if (c >= line.size) return right(doc)
    while (c < line.size && !isWord(line[c])) ++c
    while (c < line.size && isWord(line[c])) ++c
    return Pos(this.line, c)
  }

  internal Pos endWord(Doc doc)
  {
    c := this.col
    line := doc.line(this.line)
    if (c >= line.size) return right(doc)

    // in space, then delete up to next non-space
    if (line[c].isSpace)
    {
      while (c < line.size && line[c].isSpace) ++c
    }

    // if in word then delete up to next non-word + spaces,
    // of in non-word then up to next word + spaces
    else
    {
      if (isWord(line[c]))
        while (c < line.size && isWord(line[c])) ++c
      else
        while (c < line.size && !isWord(line[c])) ++c
      while (c < line.size && line[c].isSpace) ++c
    }

    return Pos(this.line, c)
  }

  private static Bool isWord(Int char) { char.isAlphaNum || char == '_' }

}