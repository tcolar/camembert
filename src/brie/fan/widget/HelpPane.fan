
using fwt
using gfx
using fandoc
using compilerDoc

// TODO: allow opening url's (ie: any website / docs)
// TODO: searc either pods or slots if first letter is upper/lower case & provide checkboxes to search either or both
// TODO: Provides links on types to open them in editor
// TODO: Fix ist/map to show proper type rather than just List/Map
// TODO: less pink ;)
// TODO: when in axon file/prj search axon libs only ?

** Sidebar to search / display fandocs
class HelpPane : ContentPane
{
  WebBrowser? browser
  Str[] pageHistory := [,]
  Text? search
  private Frame frame
  private Sys sys

  new make(Frame frame)
  {
    this.frame = frame
    sys = frame.sys
    try
    {
      // This can fail because of SWT / native browser incompatibilities
      browser = WebBrowser {}
    }catch(Err e)
    {
      content = Label{ text = "WebBrowser failed to load !" }
      e.trace
      return
    }

    content = EdgePane
    {
      search = Text
      {
        text="";
        prefCols = 10;
        onAction.add |Event e|
        {
          showSearch(search.text)
        }
      }
      top = GridPane
      {
        numCols = 4
        Button{image = gfx::Image(`fan://icons/x16/arrowLeft.png`); onAction.add |Event e|
          {
            if( ! pageHistory.isEmpty) pageHistory.pop()
              if( ! pageHistory.isEmpty)
            {
              showPage(pageHistory.pop())
            }
          }
        },
        Button{image = gfx::Image(`fan://camembert/res/home.png`, false); onAction.add |Event e| { showPage("") }},
        search,
        Button
        {
          text="close";
          onAction.add |Event e|
          {
            hide
          }
        },
      }
      center = BorderPane
      {
        it.border  = Border("1,1,0,0 $Desktop.sysNormShadow")
        it.content = browser
      }
    }
    browser.onHyperlink.add |Event e|
    {
      onHyperlink(e)
    }
    showPage("")
  }

  Void updateSys(Sys newSys)
  {
    sys = newSys
  }

  internal Void onHyperlink(Event e)
  {
    uri := e.data.toStr
    if(uri.contains("#goto:"))
    {
      // maybe support directly to a slot later (matchSlot)
      info := sys.index.matchTypes(uri[uri.index("#goto:") + 6 .. -1], MatchKind.exact).first
      if(info != null)
      try{frame.goto(Item(info))}catch(Err err){}
      e.data = null
    }
    if( ! uri.contains("://"))
    {
      showPage(uri)
      e.data = null
    }
  }

  internal Void showSearch(Str text)
  {
    if(browser == null)
      return
    if(visible == false)
      show
    if(text.contains("://"))
    {
      browser.load(text.toUri)
      return
    }
    search.text = text
    pageHistory.clear
    browser.loadStr(find(search.text))
  }

  private Void hide()
  {
    this.visible = false
    parent.relayout
  }

  private Void show()
  {
    this.visible = true
    parent.relayout
  }

  private Void showPage(Str uri)
  {
    if(browser==null)
      return
    pageHistory.push(uri)
    try
      browser.loadStr(showDoc(uri))
    catch(Err e) {e.trace}
  }

  ** Search pods and types for items matching the query
  private Str find(Str query, MatchKind kind := MatchKind.startsWith, Bool inclSlots := false)
  {
    echo("find: $query")
    index := sys.index

    results := "<h2>Pods:</h2>"
    index.matchPods(query, kind).each
    {
      results+="<a href='${it.name}::index'>$it</a> <br/>"
    }
    results += "<h2>Types:</h2>"
    index.matchTypes(query, kind).each
    {
      results+="<a href='${it.qname}'>$it.qname</a> <br/>"
    }
    if(! inclSlots)
    {
      results += "<h2>Slots:</h2>"
      index.matchSlots(query, kind).each
      {
        results+="<a href='${it.type.qname}'>$it.qname</a> <br/>"
      }
    }

    return results
  }

  ** Display doc for a qualified name: pod, type etc...
  private Str showDoc(Str fqn)
  {
    if( fqn.isEmpty )
    {
      // home (pod list)
      Str pods := "<h2>Pod List</h2>"
      sys.index.pods.each
      {
        pods+="<a href='${it.name}::pod-doc'>$it.name</a> <br/>"
      }
      return pods
    }
    if(fqn.contains("#"))
    {
      fqn = fqn[0 ..< fqn.index("#")] // remove anchor
    }
    if(fqn.contains("::index")) fqn = fqn[0 ..< fqn.index("::")]
      if(fqn.contains("::pod-doc")) fqn = fqn[0 ..< fqn.index("::")]
      if(! fqn.contains("::"))
    {
      // pod
      info := sys.index.matchPods(fqn.lower, MatchKind.exact).first
      if(info == null)
        return "$fqn not found !"
      text := "<h2>$info.name</h2>"
      text += readPodDoc(info.podFile)
      text += "<hr/>"
      info.types.each {text += "<br/> <a href='$it.qname'>$it.name</a>"}
      return text
    }
    else
    {
      info := sys.index.matchTypes(fqn.lower, MatchKind.exact).first
      if(info == null)
        return "$fqn not found !"
      text := "<h2>$info.qname</h2>"
      if(info.toFile != null)
      {
        link := anchor("#goto:$info.qname")
        text += "<a href='$link'>Click here to open in editor</a></a><br/><br/>"
      }
      text += readTypeDoc(info.pod.podFile, info.name)
      return text
    }
    return ""
  }

  ** Parse Fandoc into HTML
  private Str docToHtml(DocFandoc? doc)
  {
    if(doc == null || doc.text.isEmpty) return "<br/>"
      buf := Buf()
    FandocParser.make.parseStr(doc.text).write(HtmlDocWriter(buf.out))
    return buf.flip.readAllStr
  }

  private Str readPodDoc(File podFile)
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

  private Str readTypeDoc(File podFile, Str typeName)
  {
    result := "Failed to read pod doc !"
    try
    {
      doc := DocPod(podFile)

      DocType? type := doc.type(typeName, false)

      if(type?.doc != null)
        result = docToHtml(type.doc)
      else
        result = doc.summary

      if(type!=null)
      {
        result += "<div style='background-color:#ccccff'><b>Inheritance</b></div>"
        type.base.eachr{result += htmlType(it)+" - "}
        result += "<div style='background-color:#ccccff'><b>Local slots</b></div>"
        type.slots.each
        {
          result += "<div style='background-color:#ffeedd'>"+htmlSig(it) + "</div>" + docToHtml(it.doc)
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
      sig += htmlType(method.returns)+" "
      sig += " <b>$method.name </b>"
      sig += "(";
      method.params.each{sig += htmlType(it.type) + (it.def != null ?" <i>${it.name}:=${it.def}</i>":" $it.name") + ", "}
      sig += ")"
    }
    return sig
  }

  ** Type signature with link
  private Str htmlType(DocTypeRef type)
  {
    return "<a href='$type.qname'>$type.dis</a> "
  }

  Str anchor(Str anchor)
  {
    uri := pageHistory.peek?.toStr ?: ""
    if(uri.contains("#"))
     uri = uri[0 ..< uri.indexr("#")]
    return uri + anchor
  }
}


