//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt
using bocce

**
** Mark is a pointer to a location to resource with
** its line and column.
**
const class Mark
{
  ** Constructor
  new make(Res? res, Int line, Int col, Int colEnd := col, Str text := "")
  {
    this.res    = res
    this.line   = line
    this.col    = col
    this.colEnd = colEnd
    this.text   = text
  }

  ** Resource for the mark or null for current resouce
  const Res? res

  ** Zero based line number
  const Int line

  ** Zero based column number
  const Int col

  ** Zero based ending column
  const Int colEnd

  ** Auxiliary text for the mark such as the text found
  ** or console line that defined the error location
  const Str text := ""

  ** Get line and column as Pos
  Pos pos() { Pos(line, col) }

  override Str toStr()
  {
    if (text.isEmpty) return "$res:$line:$col"
    return text
  }

  **
  ** Hash code is based on res, line, and col.
  **
  override Int hash()
  {
    hash := res == null ? 33 : res.hash
    hash = hash.xor(line.shiftl(21))
    hash = hash.xor(col.shiftl(11))
    return hash
  }

  **
  ** Equality is based on res uri, line, and col.
  **
  override Bool equals(Obj? that)
  {
    x := that as Mark
    if (x == null) return false
    return res == x.res && line == x.line && col == x.col
  }

  **
  ** Compare res, then lines, then columns
  **
  override Int compare(Obj that)
  {
    x := (Mark)that
    cmp := res <=> x.res
    if (cmp == 0) cmp = line <=> x.line
    if (cmp == 0) cmp = col <=> x.col
    return cmp
  }

}

