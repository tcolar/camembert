//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using petanque

**
** View is used to view/edit a file
**
abstract class View : ContentPane
{
  static View? makeBest(Frame frame, File? file)
  {
    mime := file.mimeType ?: MimeType("text/plain")
    if(file == null) return null
    if (mime.mediaType == "text") return TextView(frame, file)
    if (mime.mediaType == "image") return ImageView(frame, file)
    return null
  }

  new make(Frame frame, File file)
  {
    this.frame = frame
    this.file = file
  }

  Frame frame { private set }

  const File file

  ** Current caret position of view
  virtual Pos curPos() { Pos(0, 0) }

  ** Current status string for status bar
  virtual Str curStatus() { "" }

  ** Current selected string or empty
  virtual Str curSelection() { "" }

  ** If a space loads a view from a goto event, then this
  ** callback is made after the space has finished loading
  virtual Void onGoto(Item item) {}

  ** Callback to cleanup resources
  virtual Void onUnload() {}

  ** The dirty state indicates if unsaved changes have been
  ** made to the view.  Views should set dirty to true on
  ** modification.  Dirty is automatically cleared `onSave`.
  Bool dirty := false
  {
    set
    {
      if (&dirty == it) return
      &dirty = it
      if (it) frame.updateStatus
    }
  }

  ** Focus and ready for editing
  virtual Void onReady() {}

  ** Save current state
  virtual Void onSave() {}

  ** Highlight marks
  virtual Void onMarks(Item[] marks) {}
}

