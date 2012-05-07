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
const class Pos
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

  ** Return zero based "line:col"
  override Str toStr() { "$line:$col" }

}