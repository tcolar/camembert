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
** Res models the resource currently being viewed/edited
**
abstract const class Res
{
  **
  ** Uri which uniquely identifies document.
  **
  abstract Uri uri()

  **
  ** Display name of the document.
  **
  abstract Str dis()

  **
  ** Get a 16x16 icon for the resource.
  **
  virtual Image icon() { Theme.iconFile }

  **
  ** Return `dis`.
  **
  override Str toStr() { dis }

  **
  ** Construct view to edit this resource
  **
  abstract View makeView(App app)

  **
  ** Hash code is based on uri
  **
  override Int hash() { uri.hash }

  **
  ** Equality is based on uri
  **
  override Bool equals(Obj? that)
  {
    if (that isnot Res) return false
    return this.uri == ((Res)that).uri
  }

  **
  ** Compare by uri
  **
  override Int compare(Obj that)
  {
    uri <=> ((Res)that).uri
  }

}

