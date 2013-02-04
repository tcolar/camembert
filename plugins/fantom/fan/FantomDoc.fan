// History:
//  Jan 28 13 tcolar Creation
//

using gfx
using fandoc
using compilerDoc
using web
using camembert

**
** FantomDoc
** Documentation provider for fantom
**
const class FantomDoc : PluginDoc
{
  const FantomPlugin plugin

  new make(FantomPlugin plugin)
  {
    this.plugin = plugin
    this.pluginName = this.typeof.pod.name
  }

  static const gfx::Image fanIcon  := gfx::Image(`fan://icons/x16/database.png`, false)

  override const gfx::Image? icon := fanIcon

  override const Str pluginName

  override const Str dis := "Fantom"

  override FileItem? findSrc(Str query)
  {
    // TODO: we could match more precisely (slot)
    if(query.contains("#"))
      query = query[0 ..< query.index("#")]
    info := FantomPlugin.cur.index.matchTypes(query, MatchKind.exact).first
    if(info.toFile == null || ! info.toFile.exists)
      return null
    return info != null ? FantomItem(info) : null
  }

  override Str html(WebReq req, Str query, MatchKind matchKind)
  {
    if(query.isEmpty)
      return podList
    else if(query == "axon-home")
      return axonLibs // TODO: -> to axon plugin
    else if(query.contains("ext-"))
      return axonDocs(req, query)// TODO: -> to axon plugin
    else if(query.contains("::"))
    {
      return itemDoc(req, query)
    }
    else
      return find(query, matchKind)
  }

  ** List all pods except axon library pods
  Str podList()
  {
    Str pods := "<h2>Pod List</h2>"
    plugin.index.pods.each
    {
      if( ! it.isAxonPod || it.name=="skyspark" || it.name=="proj")
      {
        pods+="<a href='/${pluginName}/${it.name}::pod-doc'>$it.name</a> <br/>"
      }
    }
    return pods
  }

  ** List axon libraries / extensions
  Str axonLibs()
  {
    Str html := "<h2>Axon libraries</h2>"
    Str[] pods := [,]
    // axon libraries writen in Fantom
    plugin.index.pods.each |pod|
    {
      if(pod.isAxonPod)
        pods.add(pod.name)
    }
    // axon extensions (trio sources)
    plugin.index.trioInfo.keys.each |pod|
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
      return "/${pluginName}/ext-${podName}/"
    return "/${pluginName}/ext-${podName[0..-4]}/"
  }

  ** Axon extensions/libs docs
  private Str axonDocs(WebReq req, Str text)
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

    pod := plugin.index.matchPods(podName.lower, MatchKind.exact).first
    if(pod == null)
      return "$podName not found !"
    trioInfo := plugin.index.trioInfo[podName]

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
      html += readAxonTypeDoc(req, pod, trioInfo)
      return html
    }
    else if(item == "tags")
    {
      html := "<h2>$podName Tags :</h2>"
      // fantom funcs
      trioInfo.tags.each
      {
        html += "<div class='bg1'><a name='$it.name'></a><b>${it.name}</b>"
                    + "</div><div class='bg2'>$it.kind</div>"
                    + docStrToHtml(req, it.doc, true)
      }
      return html
    }
    else if(item == "src")
    {
      html := "<h2>$podName Axon src :</h2>"
      trioInfo.funcs.each
      {
        html += "<div class='bg1'><a name='$it.name'></a><b>${it.name}</b></div>"
             + "<pre>$it.src</pre>"
      }
      return html
    }

    return "TBD"
  }

  ** Get doc for an item(pod, type etc..)
  private Str itemDoc(WebReq req, Str fqn)
  {
    if(fqn.contains("::index")) fqn = fqn[0 ..< fqn.index("::")]
      if(fqn.contains("::pod-doc")) fqn = fqn[0 ..< fqn.index("::")]
      if(! fqn.contains("::"))
    {
      // pod
      info := plugin.index.matchPods(fqn.lower, MatchKind.exact).first
      if(info == null)
        return "$fqn not found !"
      text := "<h2>$info.name</h2>"
      info.types.each {text += "<a href='/${pluginName}/$it.qname'>$it.name</a>, "}
      text += "<hr/>"
      text += readPodDoc(req, info.podFile)
      return text
    }
    else
    {
      info := plugin.index.matchTypes(fqn.lower, MatchKind.exact).first
      if(info == null)
        return "$fqn not found !"
      text := "<h2>$info.qname</h2>"
      text += readTypeDoc(req, info.pod.podFile, info.name)
      return text
    }
  }

  ** Search pods, types, slots for items matching the query
  ** And returns a search result page
  private Str find(Str query, MatchKind kind := MatchKind.startsWith, Bool inclSlots := true)
  {
    index := plugin.index

    pods := index.matchPods(query, kind)
    results := ""
    if(! pods.isEmpty)
    {
      results += "<h2>Pods:</h2>"
      pods.each
      {
        results+="<a href='/${pluginName}/${it.name}::index'>$it</a> <br/>"
      }
    }
    types := index.matchTypes(query, kind)
    if(! types.isEmpty)
    {
      results += "<h2>Types:</h2>"
      types.each
      {
        results+="<a href='/${pluginName}/${it.qname}'>$it.qname</a> <br/>"
      }
    }
    if(inclSlots)
    {
      slots := index.matchSlots(query, kind).findAll{ ! type.isAxonLib}
      if(! slots.isEmpty)
      {
        results += "<h2>Slots:</h2>"
        slots.each
        {
          results+="<a href='/${pluginName}/${it.type.qname}#$it.name'>$it.qname</a> <br/>"
        }
      }
    }
    funcs := index.matchFuncs(query, kind)
    slots := index.matchSlots(query, kind).findAll{ type.isAxonLib}
    if( ! funcs.isEmpty || ! slots.isEmpty)
    {
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
  private Str docToHtml(WebReq req, DocFandoc? doc, Bool forAxon := false)
  {
    return docStrToHtml(req, doc.text, forAxon)
  }

  private Str docStrToHtml(WebReq req, Str? doc, Bool forAxon := false)
  {
    if(doc == null || doc.isEmpty) return "<br/>"
      buf := Buf()
    writer := forAxon ?
        axonWriter(req.uri.toStr, buf.out)
        : writer(req.uri.toStr, buf.out)
    FandocParser.make.parseStr(doc).write(writer)
    return buf.flip.readAllStr
  }

  ** Read doc of a pod
  private Str readPodDoc(WebReq req, File podFile)
  {
    result := "Failed to read pod doc !"
    try
    {
      doc := DocPod(podFile)
      if(doc.podDoc != null)
        result = docToHtml(req, doc.podDoc.doc)
      else
       result = doc.summary
    }
    catch(Err e) {Sys.log.err("Failed reading pod doc for $podFile.osPath", e)}
    return result
  }

  ** Read doc of a type
  private Str readTypeDoc(WebReq req, File podFile, Str typeName)
  {
    result := "Failed to read pod doc !"
    try
    {
      doc := DocPod(podFile)

      DocType? type := doc.type(typeName, false)

      Str summary := type?.doc != null ? docToHtml(req, type.doc) : doc.summary

      result = summary
      if(type!=null)
      {
        result+="<hr/>Slots: "
        type.slots.each
        {
          result += "<a href='#${it.name}'>$it.name</a>, "
        }
        result += "<hr/><div class='bg1'><b>Inheritance</b></div>"
        type.base.eachr{result += htmlType(it)+" - "}
        result += "<div class='bg1'><b>Local slots</b></div>"
        type.slots.each
        {
          result += "<div  class='bg2'><a name='$it.name'></a>"
                  +htmlSig(it) + "</div>"
                  + docToHtml(req, it.doc)
        }
      }
    }
    catch(Err e) {Sys.log.err("Failed reading pod doc for $podFile.osPath", e)}

    return result
  }

  ** Read doc of a type
  private Str readAxonTypeDoc(WebReq req, PodInfo pod, TrioInfo? info)
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
            result += "<div  class='bg2'><a name='$it.name'></a>"
                    +htmlSig(it) + "</div>"
                    + docToHtml(req, it.doc, true)
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
          result += "<div class='bg2'><a name='$it.name'></a>"
                  +it.sig+ "</div>"
                  + docStrToHtml(req, it.doc, true)
        }
      }
    }
    catch(Err e) {Sys.log.err("Failed reading Axon docs for $pod.name", e)}

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
    return "<a href='/${pluginName}/$type.qname'>$type.dis</a> "
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
        uri = "/${pluginName}/$uri" // always start with the slash otherwise

      uri = uri.replace(".", "#") // slots are mapped into anchors
      link.uri = uri;
    }
    return writer
  }

  ** Axon docs behave differently
  internal HtmlDocWriter axonWriter(Str curUri, OutStream out)
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

      infos := plugin.index.trioInfo.vals
      // lookup fantom axon func
      slot := plugin.index.matchSlots(uri, MatchKind.exact).find
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