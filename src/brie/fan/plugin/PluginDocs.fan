// History:
//  Jan 28 13 tcolar Creation
//

using gfx
using web

**
** PluginDoc
** Documentation provider associated with a plugin
**
const mixin PluginDocs
{
  ** An icon for that plugin / language documentation
  abstract Image? icon()

  ** Return html for a given path
  ** Note, the query will be prefixed with the plugin name for example /fantom/fwt::Button
  abstract Str html(WebReq req, Str query, MatchKind matchKind)

  ** Return a FileItem for the document matching the current source file (if known)
  ** Query wil be what's in the helPane serach box, ie "fwt::Combo#make" (not prefixed by plugin name)
  virtual FileItem? findSrc(Str query) {null}

  ** name of the plugin responsible
  abstract Str pluginName()

  ** User friendly dsplay name
  virtual Str dis() {pluginName}
}