
using fwt
using gfx
using fandoc
using compilerDoc

// TODO: when in axon file/prj search axon libs only ?

** Sidebar to search / display fandocs
class HelpPane : ContentPane
{
  WebBrowser? browser
  Str[] pageHistory := [,]
  Text? search
  private Frame frame
  private Sys sys

  ** Unfortunately need to write html to a file rather than just in memory due to swt / IE bug
  File file := File.createTemp("fan",".html").deleteOnExit

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
        text=""
        prefCols = 15
        onAction.add |Event e|
        {
          render(search.text)
        }
      }
      top = GridPane
      {
        numCols = 3
        Button{image = gfx::Image(`fan://icons/x16/arrowLeft.png`);
        onAction.add |Event e|
          {
            if( ! pageHistory.isEmpty) pageHistory.pop()
            if( ! pageHistory.isEmpty)
            {
              render(pageHistory.pop())
            }
          }
        },
        Button{image = gfx::Image(`fan://camembert/res/home.png`, false);
        onAction.add |Event e| {render("")}},
        search,
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
    render("")
  }

  Void updateSys(Sys newSys)
  {
    sys = newSys
  }

  private Void hide()
  {
    this.visible = false
    parent.relayout
    if( ! frame.recentPane.visible)
    {
      parent.visible = false
      parent.parent.relayout
    }
  }

  Void indexUpdated()
  {
    if(search.text.isEmpty)
      render("")
  }

  Void toggle()
  {
    if(visible)
      hide
    else
      show
  }

  private Void show()
  {
    this.visible = true
    parent.relayout
    if(parent.visible == false)
    {
      parent.visible = true
      parent.parent.relayout
    }
  }

  ** Intercept hyperlinks so we can generate proper doc on the fly
  internal Void onHyperlink(Event e)
  {
    uri := e.data.toStr
    echo("HL: $uri")
    if(uri.contains("#goto:"))
    {
      // goto: special link to open a given type source file in the editor
      // maybe support directly to a slot later (matchSlot)
      info := sys.index.matchTypes(uri[uri.index("#goto:") + 6 .. -1], MatchKind.exact).first
      if(info != null)
        try{frame.goto(Item(info))}catch(Err err){}
      e.data = null
      return
    }
    if(uri.contains("://"))
      return // standard web link, let browser handle it

    render(uri)
    e.data = null
  }

  ** Render a page for the given input text
  ** such as "complier" -> search for items with names matching "compiler"
  ** or "sys::Str" -> a type
  ** or "sys::pod-doc" -> pod doc of sys
  ** and so on
  ** empty text returns the full pod list
  internal Void render(Str text)
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
    text = text.trim

    search.text = text.trim

    pageHistory.push(text)

    if(text.isEmpty)
      loadDoc(podList, "")
    else if(text.contains("::"))
    {
      Str? anchor
      if(text.contains("."))
      {
        anchor = text[text.index(".")+1 .. -1]
        text = text[0 ..< text.index(".")] // remove slot
      }
      loadDoc(itemDoc(text), anchor == null ? "" : "#$anchor")
    }
    else
      loadDoc(find(text), "")
  }

  ** Write to a file and then loads it in browser
  ** as on windows/IE loadStr did not work properly
  internal Void loadDoc(Str doc, Str anchor)
  {
    doc = "<html><body>$doc</body></html>"
    file.create.open.print(doc).flush.close
    dest := `${file.uri}$anchor`
echo("dest: $dest")
    browser.load(dest)
  }

  ** List all pods
  Str podList()
  {
    Str pods := "<h2>Pod List</h2>"
    sys.index.pods.each
    {
      pods+="<a href='${it.name}::pod-doc'>$it.name</a> <br/>"
    }
    return pods
  }

  ** Get doc for an item(pod, type etc..)
  private Str itemDoc(Str fqn)
  {
    echo("itemDoc: $fqn")
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
  }

  ** Search pods, types, slots for items matching the query
  ** And returns a search result page
  private Str find(Str query, MatchKind kind := MatchKind.startsWith, Bool inclSlots := false)
  {
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

  ** Parse Fandoc into HTML
  private Str docToHtml(DocFandoc? doc)
  {
    if(doc == null || doc.text.isEmpty) return "<br/>"
      buf := Buf()
    FandocParser.make.parseStr(doc.text).write(HtmlDocWriter(buf.out))
    return buf.flip.readAllStr
  }

  ** Read doc of a pod
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

  ** Read doc of a type
  private Str readTypeDoc(File podFile, Str typeName)
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
          result += "<a href='$it.qname'>$it.name</a>, "
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


