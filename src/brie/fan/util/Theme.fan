//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Apr 12  Brian Frank  Creation
//

using gfx
using netColarUtils
using fwt

**
** Theme constants
**
@Serializable
const class Theme
{
  @Setting{help = ["Default font : for anyhting but the editor"]}
  const Font font           := bestFont(9)

  @Setting{help = ["Default font color : for anyhting but the editor"]}
  const Color fontColor     := Color.black

  @Setting{help = ["Background color : for anyhting but the editor"]}
  const Color bg            := Color.white

  @Setting{help = ["Background of space 'pills'"]}
  const Color spacePillBg   := Color(0xEE_EE_EE)

  @Setting{help = ["Background of selected items"]}
  const Color selectedItem := Color(0x99_ff_99)

  @Setting{help = ["Font used in editor pane'"]}
  const Font edFont     := bestFont(11)

  @Setting{help = ["Editor pane background color'"]}
  const Color edBg      := Color.white

  @Setting{help = ["Editor pane background behind current line'"]}
  const Color edCurLineBg:= Color(0xEE_EE_EE)

  @Setting{help = ["Background Color for text selection in Editor'"]}
  const Color edSelectBg:= Color.yellow

  @Setting{help = ["Where to show color indicators (lines in the editor background)"]}
  const Int[] edCols   :=  [2, 79]

  @Setting{help = ["Color for the color indicators"]}
  const Color edColsColor:= Color(0xDD_DD_DD)

  @Setting{help = ["Default color of text in the editor"]}
  const RichTextStyle edText          := RichTextStyle { fg = Color(0x00_00_00) }

  @Setting{help = ["brackets in editor"]}
  const RichTextStyle edBracket       := RichTextStyle { fg = Color(0xff_00_00) }

  @Setting{help = ["brackets match in editor"]}
  const RichTextStyle edBracketMatch  := RichTextStyle { fg = Color(0xff_00_00); it.bg=Color(0xff_ff_00); }

  @Setting{help = ["keywords in editors"]}
  const RichTextStyle edKeyword       := RichTextStyle { fg = Color(0x00_00_ff) }

  @Setting{help = ["Numbers in editor"]}
  const RichTextStyle edNum    := RichTextStyle { fg = Color(0x77_00_77) }

  @Setting{help = ["Strings in editor"]}
  const RichTextStyle edStr    := RichTextStyle { fg = Color(0x00_77_77) }

  @Setting{help = ["Comments in editor"]}
  const RichTextStyle edComment       := RichTextStyle { fg = Color(0x00_77_00) }

  @Setting{help = ["Color of line number addicator"]}
  const Color lineNumberColor         := Color(0xaa_aa_aa)

  @Setting{help = ["Color of the caret"]}
  const Color caretColor              := Color(0x00_00_00)

  @Setting{help = ["Color of the scrollbar bg"]}
  const Color scrollBg                := Color(0xdd_dd_dd)

  @Setting{help = ["Color of the scrollbar handle"]}
  const Color scrollFg                := Color(0xbb_bb_bb)

  @Setting{help = ["Color for help docs bg 1"]}
  const Color helpBg1                 := Color(0xaa_ff_aa)

  @Setting{help = ["Color for help docs bg 1"]}
  const Color helpBg2                 := Color(0xaa_aa_ff)

  // not making those settings for now ...
  const Image iconHome      := Image(`fan://camembert/res/home.png`)
  const Image iconFile      := Image(`fan://icons/x16/file.png`)
  const Image iconDir       := Image(`fan://icons/x16/folder.png`)
  const Image iconImage     := Image(`fan://icons/x16/fileImage.png`)
  const Image iconFan       := Image(`fan://icons/x16/fileFan.png`)
  const Image iconJava      := Image(`fan://icons/x16/fileJava.png`)
  const Image iconJs        := Image(`fan://icons/x16/fileJs.png`)
  const Image iconPython    := Image(`fan://camembert/res/filePython.png`)
  const Image iconRuby      := Image(`fan://camembert/res/fileRuby.png`)
  const Image iconCs        := Image(`fan://icons/x16/fileCs.png`)
  const Image iconErr       := Image(`fan://icons/x16/err.png`)
  const Image iconOk        := Image(`fan://camembert/res/ok.png`)
  const Image iconIndexing  := Image(`fan://icons/x16/sync.png`)
  const Image iconSlideUp   := Image(`fan://camembert/res/slideUp.png`)
  const Image iconSlideDown := Image(`fan://camembert/res/slideDown.png`)
  const Image iconFolderClosed := Image(`fan://camembert/res/folderClosed.png`)
  const Image iconFolderOpen := Image(`fan://camembert/res/folderOpen.png`)
  const Image iconDirty     := Image(`fan://camembert/res/dirty.png`)
  const Image iconNotDirty  := Image(`fan://camembert/res/notDirty.png`)
  const Image iconPod       := Image(`fan://icons/x16/database.png`)
  const Image iconPodGroup  := Image(`fan://camembert/res/podGroup.png`)
  const Image iconType      := Image(`fan://camembert/res/type.png`)
  const Image iconField     := Image(`fan://camembert/res/field.png`)
  const Image iconMethod    := Image(`fan://camembert/res/method.png`)
  const Image iconMark      := Image(`fan://icons/x16/tag.png`)

  // End Option fields

  static Image fileToIcon(File f)
  {
    icon := PluginManager.cur.iconForFile(f)
    if(icon != null) return icon

    t := Sys.cur.theme

    if (f.isDir) return t.iconFolderOpen
    if (f.mimeType?.mediaType == "image") return t.iconImage
    if (f.ext == "fan")  return t.iconFan
    if (f.ext == "java") return t.iconJava
    if (f.ext == "js")   return t.iconJs
    if (f.ext == "py")   return t.iconPython
    if (f.ext == "rb")   return t.iconRuby
    if (f.ext == "cs")   return t.iconCs

    return t.iconFile
  }

  const Str name := "default"

  ** Reload theme
  static Theme load(File file)
  {
    return (Theme) JsonSettings.load(file, Theme#)
  }

  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  ** Best programming fonts(IMO) available standard for the current OS
  static Font bestFont(Int? size)
  {
    Font? font
    sz := size == null ? "" : "${size}pt "
    bf := bestFontName
    // fallback to whatever java/SWT uses as the default
    return Font("$sz $bf", false) ?: Desktop.sysFont.toSize(size)
  }

  static Str bestFontName()
  {
    Font? font
    if(Env.cur.os == "win32")
      // "Consolas" is better but apparently consolas is not there by default on all winblows versions
      return "Courier New"
    else if(Env.cur.os == "macosx")
      return "Menlo"
    else if(Env.cur.os == "linux")
      return "DejaVu Sans Mono"
    // fallback to whatever java/SWT uses as the default
    return Desktop.sysFont.toStr
  }
}