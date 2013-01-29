// History:
//  Jan 28 13 tcolar Creation
//

using gfx

**
** DocProvider
** Documentation provider associated with a plugin
**
const mixin DocProvider
{
  ** An icon for that plugin / language documentation
  abstract Image icon := null

  ** Return html for a given path
  ** Todo: return a file to serve instead ??
  abstract Str html(Str query, MatchKind matchKind)

}