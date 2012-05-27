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
** HomeSpace
**
@Serializable
const class HomeSpace : Space
{
  new make(Sys sys) : super(sys) {}

  override Str dis() { "home" }
  override Image icon() { Theme.iconHome }

  override Str:Str saveSession()
  {
    Str:Str[:]
  }

  static Space loadSession(Sys sys, Str:Str props)
  {
    make(sys)
  }

  override Bool goto(Item item) { false }

  override Widget onLoad(Frame frame)
  {
    Label { text = "Home Space!" }
  }
}

