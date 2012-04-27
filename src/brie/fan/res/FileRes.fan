//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt

**
** FileRes
**
const class FileRes : Res
{
  new make(File file)
  {
    this.file = file.normalize
    this.uri  = file.uri
    this.dis  = file.name
    this.icon = fileToIcon(file)
  }

  const File file
  override const Uri uri
  override const Str dis
  override const Image icon

  override View makeView(App app) { EditorView(app, this) }

  static Image fileToIcon(File f)
  {
    if (f.isDir) return Image(`fan://icons/x16/folder.png`)

    mimeType := f.mimeType
    if (mimeType == null) return Image(`fan://icons/x16/file.png`)

    // look for explicit match based off ext
    try { return Image(`fan://icons/x16/file${f.ext.capitalize}.png`) }
    catch {}

    if (mimeType.mediaType == "text")
    {
      switch (mimeType.subType)
      {
        //case "html": return Image(`fan://icons/x16/fileHtml.png`)
        default:     return Image(`fan://icons/x16/file.png`)
      }
    }

    switch (mimeType.mediaType)
    {
      //case "audio": return Image(`fan://icons/x16/audio-x-generic.png`)
      case "image": return Image(`fan://icons/x16/fileImage.png`)
      //case "video": return Image(`fan://icons/x16/video-x-generic.png`)
      default:      return Image(`fan://icons/x16/file.png`)
    }
  }

}

