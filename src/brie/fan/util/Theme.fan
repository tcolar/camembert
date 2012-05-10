//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Apr 12  Brian Frank  Creation
//

using gfx

**
** Theme constants
**
const class Theme
{
  const static Image iconFile     := Image(`fan://icons/x16/file.png`)
  const static Image iconDir      := Image(`fan://icons/x16/folder.png`)
  const static Image iconErr      := Image(`fan://icons/x16/err.png`)
  const static Image iconIndexing := Image(`fan://icons/x16/sync.png`)

  const static Color bg       := Color(0xff_ff_ff)
  const static Color div      := Color(0xdd_dd_dd)
  const static Color status   := Color(0x44_44_44)
  const static Color scrollFg := Color(0x70_40_40_40, true)
  const static Color scrollBg := Color(0x70_c0_c0_c0, true)

  const static Color showCol  := div
  const static Pen showColPen := Pen { width = 1; dash = [1,3] }
}