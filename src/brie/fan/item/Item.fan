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
using petanque

@Serializable
class Item
{
  Str dis
  Int indent := 0
  ItemLoc loc := ItemLoc{}
  Image? icon
  Str? spaceId {private set}
  Bool hidden := false

  new makeStr(Str dis) { this.dis = dis }

  new makeLoc(Int line, Int col, Span? span)
  {
    dis = ""
    loc = ItemLoc{it.line=line; it.col=col; it.span=span}
  }

  This setDis(Str dis) {this.dis = dis; return this}

  This setIcon(Image icon) {this.icon = icon; return this}

  This setLoc(ItemLoc loc) {this.loc = loc; return this}

  This setIndent(Int indent) {this.indent = indent; return this}

  This setSpace(Space? space)
  {
    if(space != null)
      this.spaceId = buildSpaceId(space); return this
  }

  // getters
  Space? space() {Sys.cur.frame.spaces.find{spaceId == buildSpaceId(it)}}

  Pos pos() { Pos(loc.line, loc.col) }

  private Str buildSpaceId(Space space) {return "$space.typeof $space?.root"}

  ** Called when item is selected (left clicked on)
  virtual Void selected(Frame frame) {}

  ** Called when item is right cliked on
  ** isRootItem is true if it's the first item in the list and a project
  virtual Menu? popup(Frame frame) {return null}
}

** Item location
@Serializable
const class ItemLoc
{
  const Int line := 0
  const Int col := 0
  const Span? span := null

  new make(|This|? f)
  {
    if(f != null) f(this)
  }

  override Str toStr() {"LOC: ${line}:${col} [$span]"}

}


