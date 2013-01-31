// History:
//  Jan 24 13 tcolar Creation
//

using netColarUtils

**
** Fantom Options
**
@Serializable
const class FantomOptions
{
  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  ** List of path uri to automatically expand in the nav (Regex)
  ** The matches will be automatically expanded rather than collapsed
  @Setting
  const Str[] navExpandPatterns := ["fan/.*"]
}