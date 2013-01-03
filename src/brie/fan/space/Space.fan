//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 May 12  Brian Frank  Creation
//

using gfx
using fwt
using concurrent

**
** Work space
**
mixin Space
{
  ** Display name
  abstract Str dis()

  ** Icon
  abstract Image icon()

  ** Save this space session as a set of props.  All subclasses
  ** must also declare a static 'loadSession(Str:Str)' method.
  abstract Str:Str saveSession()

  ** Return active file for this space
  abstract File? curFile()

  ** Return the space root directory
  virtual File? root() {null}

  ** If this space can handle view of the given item, then return
  ** is match priority or zero if it cannot handle the item.
  abstract Int match(Item item)

  override Int compare(Obj obj)
  {
    that := (Space)obj
    if (this is ProjectSpace) return -1
    if (that is ProjectSpace) return 1
    if (this.typeof != that.typeof) return this.typeof.name <=> that.typeof.name
    return dis <=> that.dis
  }

  ** Main Ui compinent if this space
  abstract Widget ui

  ** Space view/editor if any
  abstract View? view

  ** Space nav (if any)
  abstract Nav? nav

  ** Find matches for the Goto command
  virtual Item[] findGotoMatches(Str text) {return [,]}

  ** refresh the current space (nav, view, etc..)
  virtual Void refresh()
  {
    nav?.refresh
    if(view != null)
    {
      view = View.makeBest(view.frame, view.file)
      pos := view.curPos
      item := Item{it.dis = pos.toStr; it.line = pos.line; it.col = pos.col}
      view.onGoto(item)
    }
    ui.repaint
  }

  ** Go to the given item. (in Editor & Nav)
  virtual Void goto(Frame frame, Item item)
  {
    file := item.file
    view = View.makeBest(frame, file)
    view.onGoto(item)
    ui.repaint
  }
}

