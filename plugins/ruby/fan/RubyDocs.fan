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
    else
    {
      // with ruby a trailing '?' can be meaningful (part of id)
      if(req.uri.toStr.endsWith("?"))
        query += "?"
      return search(ri, query)
    }
  }

  ** Return ruby index
  Str index(File ri)
  {
    // TODO: might want to lazyinit / cache ths if it turns out to be slowish
    results := "<h2>Ruby index</h2>"
    runRi(ri, ["-l","-f","html"]).eachLine
    {
      if( ! it.contains("::"))
        results += "<a href='$it'>$it</a> <br/>"
    }
    return results
  }

  Str search(File ri, Str query)
  {
    results := ""
    lines := runRi(ri, ["-T", "-f", "html", query]).readAllLines
    if( ! lines.isEmpty && lines[0].startsWith(".$query not found"))
    {
      // "Not found" case ... actually gives us plain text, not HTML as requested
      results += "${lines[0]}<br/>"
      lines[1..-1].each
      {
        link := it.contains("::") ? it[it.index("::")+2 .. -1] : it
        results += "<a href='$link'>$it</a> <br/>"
      }
      return results
    }
    // "Result" page (html)
    lines.each
    {
      line := it.trim
      // Trying to create links for suspected identifiers(methods etc...)
      if(line.startsWith("<pre>") && line.endsWith("</pre>") && mightBeId(line[5 .. -7]))
      {
        id := line[5 .. -7]
        results += "<a href='$id'><pre>$id</pre></a>"
      }
      else
        results += it
    }
    return results
  }

  ** Check if str looks like it might be a ruby id(class, method, etc...)
  ** Allowing alphanums and _, ?, !, =
  ** This is unperfect but decent enough for this purpose (doc links)
  private Bool mightBeId(Str s)
  {
    return s.chars.eachWhile |Int c -> Int?|
    {
      if(c.isAlphaNum || c == '_' || c == '?' || c == '!' || c == '=')
        return null
      return c
    } == null
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