// History:
//  Jan 28 13 tcolar Creation
//

using gfx
using web

**
** PluginDoc
** Documentation provider associated with a plugin
**
const mixin PluginDoc
{
  ** An icon for that plugin / language documentation
  abstract Image? icon()

  ** Return html for a given path
  ** Todo: return a file to serve instead ??
  abstract Str html(WebReq req, Str query, MatchKind matchKind)

  ** name of the plugin responsible
  abstract Str pluginName()
}