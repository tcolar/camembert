
using fwt
using gfx
using fandoc

// TODO: Use the index insead not "local" fan and Pod.list!
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

  new make(Frame frame)
  {
    try
    {
      // TODO: this can fail because of SWT / native browser incompatibilities
      browser = WebBrowser {}
      //throw(Err("test"))
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
      uri := e.data
      if(uri.toStr.contains("://"))
        browser.load(uri)
      else
        showPage(uri.toStr)
    }
    showPage("")
  }

  internal Void showSearch(Str text)
  {
    if(browser == null)
      return
    if(visible == false)
      show
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

  internal Void showPage(Str uri)
  {
    if(browser==null)
      return
    pageHistory.push(uri)
    try
        browser.loadStr(showDoc(uri))
    catch(Err e) {e.trace}
  }

  ** Search pods and types for items matching the query
  Str find(Str query)
  {
    if(browser==null)
      return ""
    pods := [,]
    types := [,]
    slots := [,]
    query = query.lower
    results := ""
    Pod.list.each
    {
      if(it.name.lower.contains(query)) {pods.add(it.name)}
        it.types.each
      {
        if(!it.isSynthetic && (it.name.lower.contains(query) || it.qname.lower.contains(query)))
        {
          types.add(it.qname)
        }
      }
    }
    pods.each {results+="<a href='${it}::index'>$it</a> <br/>"}
    types.each {results+="<a href='${it}'>$it</a> <br/>"}

    return results
  }

  ** Display doc for a qualified name: pod, type etc...
  Str showDoc(Str fqn)
  {
    if(browser==null)
      return ""
    if( fqn.isEmpty )
    {
      // home (pod list)
      Str pods := "<h2>Pod List</h2>"
      Pod.list.each
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
      pod := Pod.list.find |Pod p, bool| {p.name.lower == fqn.lower}
      if(pod == null) return "$fqn not found !";
        text := "<h2>$pod.name</h2>"
      text += pod.doc!=null ? docToHtml(pod.doc) : pod.meta["pod.summary"]
      text += "<hr/>"
      pod.types().each {if(!it.isSynthetic) {text += "<br/> <a href='$it.qname'>$it.name</a>"}}
      return text
    }
    else
    {
      // type
      // doing a manual find, because Pod.find causes a case issue with pods that have upper case letters
      Str[] parts := fqn.split(':')
      pod := Pod.list.find |Pod p, bool| {p.name.lower == parts[0].lower}
      type := Type.find("${pod?.name}::${parts[2]}", false)
      if(type == null) return "$fqn not found !";
        text := "<h2>$type.qname</h2>"
      text += docToHtml(type.doc)
      text += "<div style='background-color:#ccccff'><b>Inheritance</b></div>"
      type.inheritance.eachr{text += htmlType(it)+" - "}
      slots := type.slots.dup.sort |Slot slot1, Slot slot2 -> Int| {slot1.name.compare(slot2.name)}
      Str local := ""
      Str inherited := ""
      slots.each
      {
        if(!it.isSynthetic)
        {
          if(it.parent.qname == type.qname)
          {
            local += "<div style='background-color:#ffeedd'>"+htmlSig(it) + "</div>" + docToHtml(it.doc)
          }
          else
          {
            inherited += "<div style='background-color:#ffeedd'>["+htmlType(it.parent)+"] " + htmlSig(it) + + "</div>" +docToHtml(it.doc)
          }
        }
      }
      text += "<div style='background-color:#ccccff'><b>Local slots</b></div>$local <div style='background-color:#ccccff'><b>Inherited slots</b></div> $inherited"
      return text
    }
    return ""
  }

  ** Parse Fandoc into HTML
  internal Str docToHtml(Str? doc)
  {
    if(doc == null || doc.isEmpty) return "<br/>"
      buf := Buf()
    FandocParser.make.parseStr(doc).write(HtmlDocWriter(buf.out))
    return buf.flip.readAllStr
  }

  ** Beautified slot signature with links to types
  internal Str htmlSig(Slot slot)
  {
    Str sig := ""
    if(slot.isAbstract) sig += "abstract "
      if(slot.isConst) sig += "const "
      if(slot.isNative) sig += "native "
      if(slot.isOverride) sig += "override "
      if(slot.isPrivate) sig += "private "
      if(slot.isProtected) sig += "protected "
      if(slot.isStatic) sig += "static "
      if(slot.isVirtual) sig += "virtual "
      if(slot.isField)
    {
      f := slot as Field
      sig += htmlType(f.type)
      sig += " <b>$f.name </b>"
    }
    else if(slot.isMethod || slot.isCtor)
    {
      m := slot as Method
      if(slot.isCtor) sig += "new "
        sig += htmlType(m.returns)+" "
      sig += "<b>$m.name </b>"
      sig += "(";
      m.params.each{sig += htmlType(it.type) + (it.hasDefault?" <i>$it.name</i>":" $it.name") + ", "}
      sig += ")"
    }
    return sig
  }

  ** Type signature with link
  internal Str htmlType(Type type)
  {
    return "<a href='$type.qname'>$type.name</a>"
  }
}


