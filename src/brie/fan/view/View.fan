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
** View is a plugin designed to view or edit a Res.
**
abstract class View : ContentPane
{

  **
  ** All views must take app, res
  **
  new make(App app, Res res)
  {
    this.app = app
    this.res = res
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the top level app
  **
  App app { private set }

  **
  ** Current resource loaded into this view.
  **
  const Res res

  **
  ** Get the command history for undo/redo.
  **
  CommandStack commandStack := CommandStack()

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
      if (it) app.controller.onViewDirty
    }
  }

  **
  ** Take focus and be ready to work!
  **
  virtual Void onReady() {}

  **
  ** Save current state
  **
  virtual Void onSave() {}

  **
  ** Goto specific mark line/col within this document
  **
  virtual Void onGoto(Mark mark) {}

  **
  ** Callback when the mark sets is updated by console command
  **
  virtual Void onMarks(Mark[] marks) {}

}