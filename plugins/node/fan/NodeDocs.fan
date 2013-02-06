// History:
//  Feb 05 13 tcolar Creation
//

using gfx
using util
using camembert
using web
using concurrent

**
** NodeDocProvider
** Provide standard Node docs (bundled)
**
const class NodeDocs : PluginDocs
{
  const AtomicRef _docs := AtomicRef()

  new make()
  {
    // Aynchronously building the doc index
    Actor(ActorPool(), |Obj? obj -> Obj?|
    {
      try
      {
        Str:Obj? theDocs := JsonInStream(((File)`fan://camNodePlugin/res/node.json`.get).in).readJson
        // TODO: persists the scanned version instead of doing this at each start
        _docs.val = scan(theDocs)
      }
      catch(Err e)
      {
        Sys.log.err("Failed loading Node.js docs !", e)
      }
      return null
    }).send("run")
  }

  override const Image? icon := Image(`fan://camNodePlugin/res/node.png`, false)

  ** name of the plugin responsible
  override Str pluginName() {this.typeof.pod.name}

  ** User friendly dsplay name
  override Str dis() {"Node.js"}

  ** Return a FileItem for the document matching the current source file (if known)
  ** Query wil be what's in the helPane serach box, ie "fwt::Combo#make" (not prefixed by plugin name)
  override FileItem? findSrc(Str query) {null}

  ** Return html for a given path
  ** Note, the query will be prefixed with the plugin name for example /fantom/fwt::Button
  override Str html(WebReq req, Str query, MatchKind matchKind)
  {
    docs := ([Uri:NodeDoc]?) _docs.val

    if(docs == null)
      return "Docs not ready yet."

    return show(docs, query)
  }

  Str show(Uri:NodeDoc docs, Str query)
  {
    uri := query.lower.trim.toUri
    doc := docs[uri]

    html := StrBuf()

    if(query.trim.isEmpty)
    {
      // index
      html.add("<h2>Node.js Documentation</h2>")
      children(docs, uri).sort.each
      {
        child := docs[it]
        html.add(link(it, child.dis)+"<br/>")
      }
      return html.toStr
    }

    if(doc == null)
    {
      html.add("<h2>Search results:</h2>")
      docs.keys.sort.each
      {
        if(it.path[-1].lower.contains(uri.toStr.lower))
        {
          html.add(link(it, it.toStr)+"<br/>")
        }
      }
      return html.toStr
    }

    html.add("<h2>$doc.dis</h2>")
    html.add(doc.desc)

    NodeDoc[] kids := [,]
    NodeDoc[] classes := [,]

    children(docs, uri).sort.each
    {
      kid := docs[it]
      if(kid.type == "class")
        classes.add(kid)
      else
        kids.add(kid)
    }

    html.add("<hr/>")
    kids.each |child|
    {
      html.add("<a href='#$child.name'>$child.name</a> ")
    }
    html.add("<hr/>")

    if( ! classes.isEmpty)
    {
      html.add("<div class='bg1'>Classes:</div>")
      classes.each |child|
      {
        html.add(link(`$uri/$child.name`, child.name)+"<br/>")
      }
      html.add("<hr/>")
    }

    kids.each |child|
    {
      html.add("<a name='$child.name'><div class='bg1'>$child.dis</div>")
      html.add("</a>$child.desc")
    }

    return html.toStr
  }

  Uri:NodeDoc scan(Obj? obj, Str path := "")
  {
    Uri:NodeDoc docs := [:]
    if(obj == null) return docs
    if(obj is Map)
    {
      map := (obj as Str:Obj?)
      nm := map["name"]?.toStr
      if(nm != null)
      {
        doc := NodeDoc(map)
        docs["$path$doc.name".lower.toUri] = doc
        path += "$nm/"
      }
      asMap(obj).each
      {
        docs.setAll(scan(it, path))
      }
    }
    else if(obj is List)
    {
      asList(obj).each
      {
        docs.setAll(scan(it, path))
      }
    }
    return docs.toImmutable
  }

  Str notFound() {return "Not found !"}

  Str link(Uri to, Str nm)
  {
    return "<a href='/camNodePlugin/$to/'>$nm</a>"
  }

  static Str:Obj? asMap(Obj? data)
  {
    return (Str:Obj?) data
  }

  static [Str:Obj?][]? asList(Obj? data)
  {
    return ([Str:Obj?][]?) data
  }

  static Uri[] children(Uri:NodeDoc docs, Uri item)
  {
    sw := item.path.isEmpty ? "" : item.pathStr+"/"
    return docs.keys.findAll {it.path.size == item.path.size + 1 && it.pathStr.startsWith(sw)}
  }
}

** Node documentation "tree"
@Serializable
const class NodeDoc
{
  const Str name := ""
  const Str dis := ""
  const Str desc := ""
  const Str type := ""

  new make(Str:Obj? map)
  {
    name = map["name"]?.toStr ?: ""
    desc = map["desc"]?.toStr ?: ""
    dis  = map["textRaw"]?.toStr ?: ""
    type = map["type"]?.toStr ?: ""
  }
}

