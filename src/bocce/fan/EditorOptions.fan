//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt

**
** EditorOptions defines options for text normalization,
** theme and syntax styling, and key bindings
**
const class EditorOptions
{
  ** Default constructor with it-block
  new make(|This|? f := null) { if (f != null) f(this) }

//////////////////////////////////////////////////////////////////////////
// Editor
//////////////////////////////////////////////////////////////////////////

  ** Default line end delimiter to use when saving text files.
  ** Note that loading text files will accept any combination
  ** of "\n", "\r", or "\r\n" - but that if the doc is saved
  ** then this line ending is applied.  Default is "\n".
  const Str lineDelimiter := "\n"

  ** If true, then trailing whitespace on each text
  ** line is strip on save.  Default is true.
  const Bool stripTrailingWhitespace := true

  ** Number of spaces to use for a tab.  Default is 2.
  const Int tabSpacing := 2

  ** If true, then all tabs to converted to space characters
  ** based on the configured `tabSpacing`.  The default is true.
  const Bool convertTabsToSpaces := true

//////////////////////////////////////////////////////////////////////////
// Syntax Styling
//////////////////////////////////////////////////////////////////////////

  const Color bg                    := Color.white
  const Font font                   := Desktop.sysFontMonospace
  const Color bgCurLine             := Color(0xee_ee_ee) // Color(0xE6FFDA)
  const Color highlight             := Color(0xff_ff_66)
  const Color div                   := Color(0xdd_dd_dd)
  const Color caretColor            := Color.black
  const Color scrollFg              := Color(0x70_40_40_40, true)
  const Color scrollBg              := Color(0x70_c0_c0_c0, true)
  const Color selectBg              := Desktop.sysListSelBg
  const Color selectFg              := Desktop.sysListSelFg
  const Int[] showCols              := [2,79]
  const Color showColColor          := Color(0xdd_dd_dd)
  const Color lineNumberColor       := Color(0xaa_aa_aa)
  const Pen showColPen              := Pen { width = 1; dash = [1,3] }
  const RichTextStyle text          := RichTextStyle { fg = Color(0x00_00_00) }
  const RichTextStyle bracket       := RichTextStyle { fg = Color(0xff_00_00) }
  const RichTextStyle bracketMatch  := RichTextStyle { fg = Color(0xff_00_00); it.bg=Color(0xff_ff_00); }
  const RichTextStyle keyword       := RichTextStyle { fg = Color(0x00_00_ff) }
  const RichTextStyle numLiteral    := RichTextStyle { fg = Color(0x00_77_77) }
  const RichTextStyle strLiteral    := RichTextStyle { fg = Color(0x00_77_77) }
  const RichTextStyle comment       := RichTextStyle { fg = Color(0x00_77_00) }
}

