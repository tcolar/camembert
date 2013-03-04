// History:
//  Feb 28 13 tcolar Creation
//

using camembert
using gfx
using web

**
** RubyDocs : Provides help pane documentation for Ruby
**
const class RubyDocs : PluginDocs
{
  override const Image? icon := Image(`fan://camRubyPlugin/res/ruby.png`, false)

  ** name of the plugin responsible
  override Str pluginName() {this.typeof.pod.name}

  ** User friendly dsplay name
  override Str dis() {"Ruby"}

  ** Return a FileItem for the document matching the current source file (if known)
  ** Query wil be what's in the helPane serach box, ie "fwt::Combo#make" (not prefixed by plugin name)
  override FileItem? findSrc(Str query) {null} // TODO

  ** Return html for a given path
  ** Note, the query will be prefixed with the plugin name for example /fantom/fwt::Button
  override Str html(WebReq req, Str query, MatchKind matchKind)
  {
    // For Ruby we will make use of the "ri" utility
    config := PluginManager.cur.conf(dis) as BasicConfig
    if(config == null) return "Missing config"
    env := config.curEnv as RubyEnv
    if(env == null) return "Missing env"
    ri := env.riPath.toFile
    if( ! ri.exists) return "riPath is not set properly in the ruby env !"

    // ok, ri looks good, make use of it
    if(query.isEmpty)
      return index(ri)
    else return search(ri, query)
  }

  ** Return ruby index
  Str index(File ri)
  {
    // TODO: might want to lazyinit / cache ths if it turns out to be slowish
    results := "<h2>Ruby index</h2>"
    runRi(ri, ["-l"]).eachLine
    {
      if( ! it.contains("::"))
        results += "$it <br/>"
    }
    return results
  }

  Str search(File ri, Str query)
  {
    return "TODO"
  }

  private Buf runRi(File ri, Str[] args)
  {
    p := Process([ri.osPath].addAll(args))
    b := Buf()
    p.out = b.out
    p.run.join
    return b.flip
  }
}