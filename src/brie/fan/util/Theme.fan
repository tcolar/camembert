//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Apr 12  Brian Frank  Creation
//

using gfx
using bocce

**
** Theme constants
**
@Serializable
const class Theme
{
  @Transient
  const Str name := "default"
  
  ** Reload options
  static Theme load(Str name)
  {
    template := Env.cur.workDir + `etc/camenbert/template.fog`
    try
      if (template.exists) return template.readObj
    catch (Err e)
      echo("ERROR: Cannot load $template\n  $e")
    return Theme()
  }

  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  const Color wallpaper := Color.white
  const Color bg := Color.white
  const Color itemHeadingBg := Color(0xdd_dd_dd)
  
  const Image iconHome      := Image(`fan://camembert/res/home.png`)
  const Image iconFile      := Image(`fan://icons/x16/file.png`)
  const Image iconDir       := Image(`fan://icons/x16/folder.png`)
  const Image iconImage     := Image(`fan://icons/x16/fileImage.png`)
  const Image iconFan       := Image(`fan://icons/x16/fileFan.png`)
  const Image iconJava      := Image(`fan://icons/x16/fileJava.png`)
  const Image iconJs        := Image(`fan://icons/x16/fileJs.png`)
  const Image iconCs        := Image(`fan://icons/x16/fileCs.png`)
  const Image iconErr       := Image(`fan://icons/x16/err.png`)
  const Image iconOk        := Image(`fan://camembert/res/ok.png`)
  const Image iconIndexing  := Image(`fan://icons/x16/sync.png`)
  const Image iconSlideUp   := Image(`fan://camembert/res/slideUp.png`)
  const Image iconSlideDown := Image(`fan://camembert/res/slideDown.png`)
  const Image iconDirty     := Image(`fan://camembert/res/dirty.png`)
  const Image iconNotDirty  := Image(`fan://camembert/res/notDirty.png`)
  const Image iconPod       := Image(`fan://icons/x16/database.png`)
  const Image iconType      := Image(`fan://camembert/res/type.png`)
  const Image iconField     := Image(`fan://camembert/res/field.png`)
  const Image iconMethod    := Image(`fan://camembert/res/method.png`)
  const Image iconMark      := Image(`fan://icons/x16/tag.png`)

  static Image fileToIcon(File f)
  {
    Sys? sys := Service.find(Sys#) as Sys
    t := sys.theme

    if (f.isDir) return t.iconDir
    if (f.mimeType?.mediaType == "image") return t.iconImage
    if (f.ext == "fan")  return t.iconFan
    if (f.ext == "java") return t.iconJava
    if (f.ext == "js")   return t.iconJs
    if (f.ext == "cs")   return t.iconCs
    return t.iconFile
  }

}