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
@Serializable
const abstract class Space
{
  new make(Sys sys) { this.sys = sys }

  ** System services
  const Sys sys

  ** Display name
  abstract Str dis()

  ** Icon
  abstract Image icon()

  ** Save this space session as a set of props.  All subclasses
  ** must also declare a static 'loadSession(Sys, Str:Str)' method.
  abstract Str:Str saveSession()

  ** Return active file for this space
  abstract File? curFile()

  ** Return active pod for this space
  abstract PodInfo? curPod()

  ** Return the space root directory
  virtual File? root() {null}

  ** Current type being view/edited
  virtual TypeInfo? curType() { null }

  ** If this space can handle view of the given item, then return
  ** is match priority or zero if it cannot handle the item.
  abstract Int match(Item item)

  ** Construct new space state to goto the given item.
  abstract This goto(Item item)

  ** Load the space and return its content widget
  abstract Widget onLoad(Frame frame)

  override Int compare(Obj obj)
  {
    that := (Space)obj
    if (this is HomeSpace) return -1
    if (that is HomeSpace) return 1
    if (this.typeof != that.typeof) return this.typeof.name <=> that.typeof.name
    return dis <=> that.dis
  }

  ** called when space is closed
  virtual Void onUnload() {}
}

