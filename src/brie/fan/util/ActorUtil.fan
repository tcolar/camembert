//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 12  Brian Frank  Creation
//

using concurrent

**
** ActorUtil
**
internal const class ActorUtil
{
  static const ActorPool pool := ActorPool()
}

**
** Generic message to use with Actors
**
internal const class Msg
{
  new make(Str id, Obj? a := null, Obj? b := null, Obj? c := null, Obj? d :=null)
  {
    this.id = id
    this.a  = a
    this.b  = b
    this.c  = c
    this.d  = d
  }

  const Str id
  const Obj? a
  const Obj? b
  const Obj? c
  const Obj? d
}