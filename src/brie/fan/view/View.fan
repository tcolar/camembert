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
** View is used to view/edit a file
**
abstract class View : ContentPane
{
  static View? makeBest(Frame frame, File file)
  {
    mime := file.mimeType ?: MimeType("text/plain")
    if (mime.mediaType == "text") return TextView(frame, file)
    if (mime.mediaType == "image") return ImageView(frame, file)
    return null
  }

  new make(Frame frame, File file)
  {
    this.frame = frame
    this.sys = frame.sys
    this.file = file
  }

  Frame frame { private set }

  const Sys sys

  const File file

  **
  ** If a space loads a view from a goto event, then this
  ** callback is made after the space has finished loading
  **
  virtual Void onGoto(Item item) {}

  **
  ** Callback to cleanup resources
  **
  virtual Void onUnload() {}

  **
  ** The dirty state indicates if unsaved changes have been
  ** made to the view.  Views should set dirty to true on
  ** modification.  Dirty is automatically cleared `onSave`.
  **
  Bool dirty := false
  {
    set
    {
      if (&dirty == it) return
      &dirty = it
      if (it) frame.updateStatus
    }
  }

  **
  ** Save current state
  **
  virtual Void onSave() {}
}

