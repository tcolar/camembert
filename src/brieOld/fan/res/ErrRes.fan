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
** ErrRes
**
const class ErrRes : Res
{
  new make(Uri uri, Str msg, Err? cause := null)
  {
    this.uri   = uri
    this.dis   = "ERR: $uri.name"
    this.msg   = msg
    this.cause = cause
    this.icon  = Theme.iconErr
  }

  override const Uri uri
  override const Str dis
  override const Image icon
  const Str msg
  const Err? cause

  override View makeView(App app) { ErrView(app, this) }

}

