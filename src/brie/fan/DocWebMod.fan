// History:
//   12 1 12 - Thibaut Colar Creation

using web
using fandoc
using compilerDoc

**
** DocWebMod
** Serve fandocs in HTML format (lightweight for embedding in camembert pane)
** Example: /sys::Str.upper
**
** Using a "real" server because SWT browser with IE did not like in memory or in file uri's
**
const class DocWebMod : WebMod
{

  override Void onGet()
  {
    Sys sys := (Sys) Service.find(Sys#)
    text := req.uri.toStr[1..-1]
    try
    {
      if(text.isEmpty)
        showDoc(req, podList(sys))
      else if(text.contains("::"))
      {
        showDoc(req, itemDoc(sys, text))
      }
      else
        showDoc(req, find(sys, text))
    }
    catch(Err e)
    {
      showDoc(req, "$e")
    }
  }

  Void showDoc(WebReq req, Str html)
  {
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 200
    out := res.out
    out.print(html).close
  }

  ** List all pods
  Str podList(Sys sys)
  {
    Str pods := "<h2>Pod List</h2>"
    sys.index.pods.each
    {
      pods+="<a href='/${it.name}::pod-doc'>$it.name</a> <br/>"
    }
    return pods
  }

  ** Get doc for an item(pod, type etc..)
  private Str itemDoc(Sys sys, Str fqn)
  {
    if(fqn.contains("::index")) fqn = fqn[0 ..< fqn.index("::")]
      if(fqn.contains("::pod-doc")) fqn = fqn[0 ..< fqn.index("::")]
      if(! fqn.contains("::"))
    {
      // pod
      info := sys.index.matchPods(fqn.lower, MatchKind.exact).first
      if(info == null)
        return "$fqn not found !"
      text := "<h2>$info.name</h2>"
      text += readPodDoc(sys, info.podFile)
      text += "<hr/>"
      info.types.each {text += "<br/> <a href='/$it.qname'>$it.name</a>"}
      return text
    }
    else
    {
      info := sys.index.matchTypes(fqn.lower, MatchKind.exact).first
      if(info == null)
        return "$fqn not found !"
      text := "<h2>$info.qname</h2>"
      text += readTypeDoc(sys, info.pod.podFile, info.name)
      return text
    }
  }

  ** Search pods, types, slots for items matching the query
  ** And returns a search result page
  private Str find(Sys sys, Str query, MatchKind kind := MatchKind.startsWith, Bool inclSlots := false)
  {
    index := sys.index

    results := "<h2>Pods:</h2>"
    index.matchPods(query, kind).each
    {
      results+="<a href='/${it.name}::index'>$it</a> <br/>"
    }
    results += "<h2>Types:</h2>"
    index.matchTypes(query, kind).each
    {
      results+="<a href='/${it.qname}'>$it.qname</a> <br/>"
    }
    if(! inclSlots)
    {
      results += "<h2>Slots:</h2>"
      index.matchSlots(query, kind).each
      {
        results+="<a href='/${it.type.qname}#$it.name'>$it.qname</a> <br/>"
      }
    }

    return results
  }

  ** Parse Fandoc into HTML
  private Str docToHtml(DocFandoc? doc)
  {
    if(doc == null || doc.text.isEmpty) return "<br/>"
      buf := Buf()
    FandocParser.make.parseStr(doc.text).write(writer(req.uri.toStr, buf.out))
    return buf.flip.readAllStr
  }

  ** Read doc of a pod
  private Str readPodDoc(Sys sys, File podFile)
  {
    result := "Failed to read pod doc !"
    try
    {
      doc := DocPod(podFile)
      if(doc.podDoc != null)
        result = docToHtml(doc.podDoc.doc)
      else
       result = doc.summary
    }
    catch(Err e) {sys.log.err("Failed reading pod doc for $podFile.osPath", e)}
    return result
  }

  ** Read doc of a type
  private Str readTypeDoc(Sys sys, File podFile, Str typeName)
  {
    result := "Failed to read pod doc !"
    try
    {
      doc := DocPod(podFile)

      DocType? type := doc.type(typeName, false)

      Str summary := type?.doc != null ? docToHtml(type.doc) : doc.summary

      result = summary
      if(type!=null)
      {
        result+="<hr/>Slots: "
        type.slots.each
        {
          result += "<a href='/${type.qname}#${it.name}'>$it.name</a>, "
        }
        result += "<hr/><div style='background-color:#ccccff'><b>Inheritance</b></div>"
        type.base.eachr{result += htmlType(it)+" - "}
        result += "<div style='background-color:#ccccff'><b>Local slots</b></div>"
        type.slots.each
        {
          result += "<div style='background-color:#ffeedd'><a name='$it.name'></a>"+htmlSig(it) + "</div>" + docToHtml(it.doc)
        }
      }
    }
    catch(Err e) {sys.log.err("Failed reading pod doc for $podFile.osPath", e)}

    return result
  }

  ** Beautified slot signature with links to types
  private Str htmlSig(DocSlot slot)
  {
    flags := slot.flags
    Str sig := DocFlags.toSlotDis(flags)
    if(slot is DocField)
    {
      field := slot as DocField
      sig += htmlType(field.type)
      sig += " <b>$slot.name </b>"
    }
    else if(slot is DocMethod)
    {
      method := slot as DocMethod
      sig += " " + htmlType(method.returns)
      sig += " <b>$method.name</b>"
      sig += "(";
      method.params.each{sig += htmlType(it.type) + (it.def != null ?" <i>${it.name}:=${it.def}</i>":" $it.name") + ", "}
      sig += ")"
    }
    return sig
  }

  ** Type signature with link
  private Str htmlType(DocTypeRef type)
  {
    return "<a href='/$type.qname'>$type.dis</a> "
  }

  ** Html writer that deals with fixing the links to our server format
  ** /pod::type#slot
  internal HtmlDocWriter writer(Str curUri, OutStream out)
  {
    HtmlDocWriter writer := HtmlDocWriter(out)
    writer.onLink = |Link? link|
    {
      uri := link.uri
      if( ! uri.contains("::"))
      {
        // make relative links absolute
        if(curUri.contains("::"))
          uri = curUri[1 .. curUri.index("::")+2]
      }
      uri = uri.replace(".", "#") // slots are mapped into anchors
      uri = "/$uri" // always start with the slash
      link.uri = uri;
    }
    return writer
  }
}


