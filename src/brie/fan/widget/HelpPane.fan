
using fwt
using gfx
using fandoc
using compilerDoc

** Sidebar to search / display fandocs
class HelpPane : ContentPane
{
  static const gfx::Image backIcon := gfx::Image(`fan://icons/x16/arrowLeft.png`, false)
  static const gfx::Image viewIcon := gfx::Image(`fan://camembert/res/binoculars.png`, false)

  WebBrowser? browser
  Text? search
  Combo searchType := Combo{items = ["term*","*term*","exact"]}
  private Frame frame
  Str:PluginDoc providers := [:]
  Combo provider

  new make(Frame frame)
  {
    this.frame = frame
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

    Sys.cur.plugins.each
    {
      provider := it.docProvider
      if(provider != null)
      {
        providers[provider.dis] = provider
      }
    }
    provider = Combo{it.items = providers.keys.sort}

    content = EdgePane
    {
      search = Text
      {
        text=""
        onAction.add |Event e|
        {
          render(search.text)
        }
      }

      top = EdgePane
      {
        top = GridPane
        {
          numCols = 2
          expandCol = 2
          provider,
          search,
        }
        center = EdgePane
        {
          left = GridPane{
            numCols = 3
            Button{
            image = backIcon
            onAction.add |Event e|
              {
                browser.back
              }
            },
            Button{
            image = Sys.cur.theme.iconHome
            onAction.add |Event e|
              {
                render("")
              }
            },
            searchType,
          }
          right = GridPane{
            numCols = 2
            Label{it.text = "View src:"},
            Button
            {
              image = viewIcon
              onAction.add |Event e|
              {
                gotoDoc
              }
            },
          }
        }
      }
      center = BorderPane
      {
        it.border  = Border("1,1,0,0 $Desktop.sysNormShadow")
        it.content = browser
      }
    }

    browser?.onHyperlink?.add |Event e|
    {
      onHyperlink(e)
    }
    render("")
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

  Void gotoDoc()
  {
    item := providers[provider.selected].findSrc(search.text)
    if(item != null)
    {
      try
      {
       frame.goto(item)
      }
      catch(Err e){e.trace}
    }
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

  Void onHyperlink(Event e)
  {
    uri := (e.data as Uri)
    if(uri.path.size < 1)
      search.text = uri.pathStr
    else
      search.text = uri.path[1..-1].join("/") + (uri.frag != null ? "#$uri.frag" : "")
  }

  ** Render a page for the given input text
  ** Delegates to the browser loading from DocWebMod
  internal Void render(Str text)
  {
    if(browser == null)
      return
    port := Sys.cur.docServer.port
    if(visible == false)
      show
    if(text.contains("://"))
    {
      browser.load(text.toUri)
      return
    }
    text = text.trim

    search.text = text

    if(! text.isEmpty)
    {
      if(searchType.selectedIndex == 1)
        text += "?type=contains"
      else if(searchType.selectedIndex == 2)
        text += "?type=exact"
    }
    if( ! text.isEmpty)
      text = providers[provider.selected].pluginName + "/$text"
    target := `http://127.0.0.1:${port}/$text`
    browser.load(target)
  }
}


