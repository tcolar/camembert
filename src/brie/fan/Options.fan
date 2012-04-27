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
** Options
**
const class Options
{
  ** Default constructor with it-block
  new make(|This|? f := null) { if (f != null) f(this) }

//////////////////////////////////////////////////////////////////////////
// Crawler
//////////////////////////////////////////////////////////////////////////

  ** Directories to crawl looking for for pod, file navigation
  const Uri[] indexDirs := [,]

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

  ** Default char encoding to use when load/saving
  ** text files.  Defaults to utf8.
  const Charset charset := Charset.utf8

//////////////////////////////////////////////////////////////////////////
// Syntax Styling
//////////////////////////////////////////////////////////////////////////

  const Color bg                    := Color.white
  const Font font                   := Desktop.sysFontMonospace
  const Color highlightCurLine      := Color(0xf0_f0_f0)
  const Color highlightMark         := Color(0xff_ff_66)
  const Int[] showCols              := [2,79]
  const RichTextStyle text          := RichTextStyle { fg = Color(0x00_00_00) }
  const RichTextStyle bracket       := RichTextStyle { fg = Color(0xff_00_00) }
  const RichTextStyle bracketMatch  := RichTextStyle { fg = Color(0xff_00_00); it.bg=Color(0xff_ff_00); }
  const RichTextStyle keyword       := RichTextStyle { fg = Color(0x00_00_ff) }
  const RichTextStyle literal       := RichTextStyle { fg = Color(0x00_77_77) }
  const RichTextStyle comment       := RichTextStyle { fg = Color(0x00_77_00) }

}

