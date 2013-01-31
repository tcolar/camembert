// History:
//  Jan 30 13 tcolar Creation
//

**
** MavenOptions
**
@Serializable
const class MavenOptions
{
  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  // No options yet
}