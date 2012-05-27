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

  ** Load the space and return its content widget
  abstract Widget onLoad(Frame frame)

  ** If this space can goto the given item, then update the
  ** application and return true.  If this space cannot handle
  ** the given item, return false.
  abstract Bool goto(Item item)

}

