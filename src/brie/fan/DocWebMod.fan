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
** Doesn't like "on the fly" redirects either
**
** TODO: This whole thing became a bit fugly ...
**
const class DocWebMod : WebMod
{

  override Void onGet()
  {
    Sys sys := (Sys) Service.find(Sys#)
    text := req.uri.pathStr[1..-1]
    query := req.uri.query
    MatchKind matchKind := MatchKind.startsWith
    if(query.containsKey("type"))
    {
      matchKind = MatchKind(query["type"])
    }

    try
    {
      if(text.isEmpty)
        showDoc(req, podList(sys))
      else if(text == "axon-home")
        showDoc(req, axonLibs(sys))
      else if(text.contains("ext-"))
        showDoc(req, axonDocs(sys, text))
      else if(text.contains("::"))
      {
        showDoc(req, itemDoc(sys, text))
      }
      else
        showDoc(req, find(sys, text, matchKind))
    }
    catch(Err e)
    {
      showDoc(req, "<b>$e</b><br/><pre>$e.traceToStr</pre>")
    }
  }

  Void showDoc(WebReq req, Str html)
  {
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 200
    out := res.out
    out.print(html).close
  }

  ** List all pods except axon library pods
  Str podList(Sys sys)
  {
    Str pods := "<h2>Pod List</h2>"
    sys.index.pods.each
    {
      if( ! it.isAxonPod || it.name=="skyspark" || it.name=="proj")
      {
        pods+="<a href='/${it.name}::pod-doc'>$it.name</a> <br/>"
      }
    }
    return pods
  }

  ** List axon libraries / extensions
  Str axonLibs(Sys sys)
  {
    Str html := "<h2>Axon libraries</h2>"
    Str[] pods := [,]
    // axon libraries writen in Fantom
    sys.index.pods.each |pod|
    {
      if(pod.isAxonPod)
        pods.add(pod.name)
    }
    // axon extensions (trio sources)
    sys.index.trioInfo.keys.each |pod|
    {
      if(!pods.contains(pod))
        pods.add(pod)
    }
    pods.sort.each |pod|
    {
      link := toExtLink(pod)
      html += "<a href='${link}index'>$pod</a><br/>"
    }
    return html
  }

  private Str toExtLink(Str podName)
  {
    if(! podName.endsWith("Ext"))
      return "/ext-${podName}/"
    return "/ext-${podName[0..-4]}/"
  }

  ** Axon extensions/libs docs
  private Str axonDocs(Sys sys, Str text)
  {
    podName := text[0 ..< text.index("/")]
    if(podName.startsWith("ext-"))
    {
      if(podName=="ext-skyspark" || podName=="ext-proj")
        podName = podName[4 .. -1]
      else
        podName = "${podName[4 .. -1]}Ext"
    }

    item := text[text.index("/")+1 .. -1]

    pod := sys.index.matchPods(podName.lower, MatchKind.exact).first
    if(pod == null)
      return "$podName not found !"
    trioInfo := sys.index.trioInfo[podName]

    if(item == "index")
    {
      html := "<h2>$podName - Index</h2><h3><b>Functions:</b></h3>"
      // Axon libs functions
      pod.types.findAll{isAxonLib}.each |type|
      {
        type.slots.each
        {
          html += "<a href='funcs#${it.name}'>$it.name</a><br/>"
        }
      }
      if(trioInfo != null)
      {
        // axon extensions (trio sources)
        trioInfo.funcs.vals.sort.each
        {
          html += "<a href='funcs#${it.name}'>$it.name</a><br/>"
        }
        // tags
        html += "<h3><b>Tags:</b></h3>"
        trioInfo.tags.vals.sort.each
        {
          html += "<a href='tags#${it.name}'>$it.name</a><br/>"
        }
      }
      return html
    }
    else if(item == "funcs")
    {
      html := "<h2>$podName Funtions :</h2>"
      // fantom funcs
      html += readAxonTypeDoc(sys, pod, trioInfo)
      return html
    }
    else if(item == "tags")
    {
      html := "<h2>$podName Tags :</h2>"
      // fantom funcs
      trioInfo.tags.each
      {
        html += "<div style='background-color:#ffeedd'><a name='$it.name'></a><b>${it.name}</b>"
                    + "</div><div style='background-color:#ddffdd'>$it.kind</div>"
                    + docStrToHtml(sys, it.doc, true)
      }
      return html
    }
    else if(item == "src")
    {
      html := "<h2>$podName Axon src :</h2>"
      trioInfo.funcs.each
      {
        html += "<div style='background-color:#ffeedd'><a name='$it.name'></a><b>${it.name}</b></div>"
             + "<pre>$it.src</pre>"
      }
      return html
    }

    return "TBD"
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
      info.types.each {text += "<a href='/$it.qname'>$it.name</a>, "}
      text += "<hr/>"
      text += readPodDoc(sys, info.podFile)
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
  private Str find(Sys sys, Str query, MatchKind kind := MatchKind.startsWith, Bool inclSlots := true)
  {
    index := sys.index

    pods := index.matchPods(query, kind)
    results := ""
    if(! pods.isEmpty)
    {
      results += "<h2>Pods:</h2>"
      pods.each
      {
        results+="<a href='/${it.name}::index'>$it</a> <br/>"
      }
    }
    types := index.matchTypes(query, kind)
    if(! types.isEmpty)
    {
      results += "<h2>Types:</h2>"
      types.each
      {
        results+="<a href='/${it.qname}'>$it.qname</a> <br/>"
      }
    }
    if(inclSlots)
    { // TODO: not show axon funcs
      slots := index.matchSlots(query, kind).findAll{ ! type.isAxonLib}
      if(! slots.isEmpty)
      {
        results += "<h2>Slots:</h2>"
        slots.each
        {
          results+="<a href='/${it.type.qname}#$it.name'>$it.qname</a> <br/>"
        }
      }
    }
    funcs := index.matchFuncs(query, kind)
    slots := index.matchSlots(query, kind).findAll{ type.isAxonLib}
    if( ! funcs.isEmpty || ! slots.isEmpty)
    {
      // TODO: add fantom axon funcs
      results += "<h2>Funcs:</h2>"
      slots.each |slot|
      {
        link := toExtLink(slot.type.pod.name)+"funcs#$slot.name"
        results+="<a href='$link'>$slot.qname</a><br/>"
      }
      funcs.each |func|
      {
        link := toExtLink(func.pod)+"funcs#$func.name"
        results+="<a href='$link'>$func.pod::$func.name</a><br/>"
      }
    }
    tags := index.matchTags(query, kind)
    if( ! tags.isEmpty)
    {
      results += "<h2>Tags:</h2>"
      tags.each |tag|
      {
        link := toExtLink(tag.pod)+"tags#$tag.name"
        results+="<a href='$link'>$tag.pod::$tag.name</a><br/>"
      }
    }

    return results
  }

  ** Parse Fandoc into HTML
  private Str docToHtml(Sys sys, DocFandoc? doc, Bool forAxon := false)
  {
    return docStrToHtml(sys, doc.text, forAxon)
  }

  private Str docStrToHtml(Sys sys, Str? doc, Bool forAxon := false)
  {
    if(doc == null || doc.isEmpty) return "<br/>"
      buf := Buf()
    writer := forAxon ?
        axonWriter(sys, req.uri.toStr, buf.out)
        : writer(req.uri.toStr, buf.out)
    FandocParser.make.parseStr(doc).write(writer)
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
        result = docToHtml(sys, doc.podDoc.doc)
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

      Str summary := type?.doc != null ? docToHtml(sys, type.doc) : doc.summary

      result = summary
      if(type!=null)
      {
        result+="<hr/>Slots: "
        type.slots.each
        {
          result += "<a href='#${it.name}'>$it.name</a>, "
        }
        result += "<hr/><div style='background-color:#ccccff'><b>Inheritance</b></div>"
        type.base.eachr{result += htmlType(it)+" - "}
        result += "<div style='background-color:#ccccff'><b>Local slots</b></div>"
        type.slots.each
        {
          result += "<div style='background-color:#ffeedd'><a name='$it.name'></a>"
                  +htmlSig(it) + "</div>"
                  + docToHtml(sys,it.doc)
        }
      }
    }
    catch(Err e) {sys.log.err("Failed reading pod doc for $podFile.osPath", e)}

    return result
  }

  ** Read doc of a type
  private Str readAxonTypeDoc(Sys sys, PodInfo pod, TrioInfo? info)
  {
    result := ""
    try
    {
      doc := DocPod(pod.podFile)

      libs := pod.types.findAll{it.isAxonLib}

      libs.each |lib|
      {
        DocType? type := doc.type(lib.name, false)

        if(type!=null)
        {
          type.slots.each
          {
            result += "<div style='background-color:#ffeedd'><a name='$it.name'></a>"
                    +htmlSig(it) + "</div>"
                    + docToHtml(sys, it.doc, true)
          }
        }
      }
      if(info != null)
      {
        if( ! info.funcs.isEmpty)
        {
          link := toExtLink(pod.name)+"src"
          result += "<a href='$link'><b>View Sources</b></a><br/><br/>"
        }
        info.funcs.each
        {
          result += "<div style='background-color:#ffeedd'><a name='$it.name'></a>"
                  +it.sig+ "</div>"
                  + docStrToHtml(sys, it.doc, true)
        }
      }
    }
    catch(Err e) {sys.log.err("Failed reading Axon docs for $pod.name", e)}

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
      sig += " "+ htmlType(field.type)
      sig += " <b>$slot.name </b>"
    }
    else if(slot is DocMethod)
    {
      method := slot as DocMethod
      sig += " " + htmlType(method.returns)
      sig += " <b>$method.name</b>"
      sig += "(";
      method.params.each
      {
        sig += htmlType(it.type)
          + (it.def != null ?" <i>${it.name}:=${it.def}</i>":" $it.name") + ", "
      }
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
      if( ! uri.contains("::")) // relative links
      {
        if(uri.contains(".") && curUri.contains("::")) // to type in pod
           uri = curUri[1 ..< curUri.index("::") + 2] + uri
        else
          uri = "#$uri" // to slot in type
      }
      else
        uri = "/$uri" // always start with the slash otherwise

      uri = uri.replace(".", "#") // slots are mapped into anchors
      link.uri = uri;
    }
    return writer
  }

  ** Axon docs behave differently
  internal HtmlDocWriter axonWriter(Sys sys, Str curUri, OutStream out)
  {
    HtmlDocWriter writer := HtmlDocWriter(out)
    writer.onLink = |Link? link|
    {
      uri := link.uri
      if(uri.startsWith("#")) return

      uri = uri.replace(".", "#")

      if(uri.startsWith("/")) return
      if(uri.contains("::"))
      {
        //if(uri.startWith("docskyspark::")) -> meh
        link.uri = "/$uri"
        return
      }

     /* ok : ... "relative" link
      with axon "relative" links could refer to a tab or function anywhere in the system
      so look it up and make it an absoulte link
      assume that tags/func names are unique across skyspark ... gotta be.*/

      infos := sys.index.trioInfo.vals
      // lookup fantom axon func
      slot := sys.index.matchSlots(uri, MatchKind.exact).find
      {
        it.type.isAxonLib
      }
      if(slot != null)
      {
        link.uri = toExtLink(slot.type.pod.name)+"funcs#$uri"
        return
      }
      // lookup trio func
      info := infos.find {it.funcs.containsKey(uri)}
      if(info != null)
      {
        link.uri = toExtLink(info.pod)+"funcs#$uri"
        return
      }
      // lookup trio tag
      info = infos.find {it.tags.containsKey(uri)}
      if(info != null)
      {
        link.uri = toExtLink(info.pod)+"tags#$uri"
        return
      }
    }
    return writer
  }
}


