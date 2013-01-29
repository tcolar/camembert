// History:
//   12 1 12 - Thibaut Colar Creation

using web

**
** DocWebMod
** Serve plugin docs in HTML format (lightweight for embedding in camembert pane)
** Example: /sys::Str.upper
**
** Using a "real" server because SWT browser with IE did not like in memory or in file uri's
** Doesn't like "on the fly" redirects either
**
const class DocWebMod : WebMod
{

  override Void onGet()
  {
    text := req.uri.path.join("/")[1 .. -1]
    query := req.uri.query
    MatchKind matchKind := MatchKind.startsWith

    pName := req.uri.path.get(0) ?: ""
    plugin := Sys.cur.plugin(pName)
    if(plugin == null)
    {
      showDoc(res, "No such plugin: $pName")
      return
    }

    doc := plugin.docProvider
    if(doc == null)
    {
      // shouldn't happen, but juts in case
      showDoc(res, "The plugin $pName does not provide documentation.")
      return
    }

    if(query.containsKey("type"))
    {
      matchKind = MatchKind(query["type"])
    }

    try
    {
      showDoc(doc.html(text, matchKind))
    }
    catch(Err e)
    {
      showDoc(req, "<b>$e</b><br/><pre>$e.traceToStr</pre>")
    }
  }

  Void showDoc(Str html)
  {
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 200
    out := res.out
    out.print(html).close
  }
}


