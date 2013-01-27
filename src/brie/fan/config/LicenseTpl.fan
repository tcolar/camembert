// History:
//  Jan 23 13 tcolar Creation
//

using netColarUtils

**
** Licence templates (global)
**
@Serializable
const class LicenseTpl
{
  ** can be use to sort licenses - lower shows first
  const Int order := 10

  ** name for this license
  const Str name

  ** License text
  const Str text

  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }
}