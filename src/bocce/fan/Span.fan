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
** Span represents a span of text between two Pos
**
const class Span
{
  ** Construct with inclusive start and exclusive end.
  ** If end is before start they are automatically swizzled.
  new make(Pos start, Pos end)
  {
    if (start <= end)
    {
      this.start = start
      this.end = end
    }
    else
    {
      this.start = end
      this.end = start
    }
  }

  ** Construct with inclusive start and exclusive end
  new makeInts(Int startLine, Int startCol, Int endLine, Int endCol)
  {
    this.start = Pos(startLine, startCol)
    this.end = Pos(endLine, endCol)
  }

  ** Inclusive start position
  const Pos start

  ** Exclusive end position
  const Pos end

  ** Hash based on line and col
  override Int hash() { start.hash.shiftl(16).xor(end.hash) }

  ** Equality is based on start, end
  override Bool equals(Obj? that)
  {
    x := that as Span
    if (x == null) return false
    return this.start == x.start && this.end == x.end
  }

  ** Does this span contain specified line
  Bool containsLine(Int line)
  {
    start.line <= line && line <= end.line
  }

  ** Return zero based "line:col-line:col"
  override Str toStr() { "$start-$end" }

}