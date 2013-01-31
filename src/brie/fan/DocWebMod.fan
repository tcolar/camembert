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
    try
    {
      if(req.uri.path.size == 0)
      {
        index
        return
      }

/*      if(req.uri.path[1] == "icon")
      {
        icon
        return
      }*/

      text := req.uri.path[1 .. -1].join("/")
      query := req.uri.query
      MatchKind matchKind := MatchKind.startsWith

      pName := req.uri.path.getSafe(0) ?: ""
      plugin := Sys.cur.plugins[pName]
      if(plugin == null)
      {
        showDoc("No such plugin: $pName !")
        return
      }

      doc := plugin.docProvider
      if(doc == null)
      {
        // shouldn't happen, but juts in case
        showDoc("The plugin $pName does not provide documentation.")
        return
      }

      if(query.containsKey("type"))
      {
        matchKind = MatchKind(query["type"])
      }

      showDoc(doc.html(req, text, matchKind))
    }
    catch(Err e)
    {
      showDoc("<b>$e</b><br/><pre>$e.traceToStr</pre>")
    }
  }

  Void index()
  {
    Str html := "<h3>Documentations:</h3>"
    Sys.cur.plugins.each
    {
      doc := it.docProvider
      if(doc != null)
      {
        html += "<a href='/$it.name/'>$doc.dis</a><br/>"
      }
    }
    showDoc(html)
  }

  /*Void icon()
  {
    res.headers["Content-Type"] = "image/png"
    res.statusCode = 200
    out := res.out

  } */

  Void showDoc(Str html)
  {
    res.headers["Content-Type"] = "text/html"
    res.statusCode = 200
    out := res.out
    out.print("<html><body>$html</body></html>").close
  }
}


