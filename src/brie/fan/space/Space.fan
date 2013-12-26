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
  ** Plugin responsibe for this space
  abstract Str? plugin

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
  ** File space returns 10
  abstract Int match(FileItem item)

  override Int compare(Obj obj)
  {
    that := (Space)obj
    if (this is IndexSpace) return -1
    if (that is IndexSpace) return 1
    if (this.typeof != that.typeof) return -1//this.typeof.name <=> that.typeof.name
    return root.normalize <=> that.root.normalize
  }

  ** Main Ui component if this space
  abstract Widget ui
  abstract View? view
  abstract Nav? nav

  ** Find matches for the Goto command
  virtual Item[] findGotoMatches(Str text) {return [,]}

  ** refresh the current space (nav, view, etc..)
  virtual Void refresh()
  {
    goto(null)
  }

  ** Go to the given item. (in Editor & Nav)
  ** If null, refresh current item
  abstract Void goto(FileItem? item)

  virtual FileItem? curFileItem()
  {
    if(view == null)
      return null
    fi := FileItem.makeFile(view.file)
    fi.setLoc(ItemLoc{col = view.curPos.col; line = view.curPos.line})
    return fi
  }

  // show or hide nav
  virtual Void showNav(Bool b){}
}

