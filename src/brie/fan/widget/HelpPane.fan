
using fwt
using gfx
using fandoc
using compilerDoc

** Sidebar to search / display fandocs
class HelpPane : ContentPane
{
  static const gfx::Image fanIcon  := gfx::Image(`fan://icons/x16/database.png`, false)
  static const gfx::Image axonIcon := gfx::Image(`fan://icons/x16/func.png`, false)
  static const gfx::Image backIcon := gfx::Image(`fan://icons/x16/arrowLeft.png`, false)
  static const gfx::Image viewIcon := gfx::Image(`fan://camembert/res/binoculars.png`, false)

  WebBrowser? browser
  Text? search
  Combo searchType := Combo{items = ["term*","*term*","exact"]}
  private Frame frame

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
          numCols = 3
          expandCol = 3
          Button{
          image = backIcon
          onAction.add |Event e|
            {
              browser.back
            }
          },
          searchType,
          search,
        }
        center = EdgePane
        {
          left = GridPane{
            numCols = 2
            Button{
              image = fanIcon
              onAction.add |Event e| {render("")} // pod list
            },
            Button{
              image = axonIcon
              onAction.add |Event e|
              {
                if( ! Sys.cur.plugins.containsKey("camA"+"xonPl"+"ugin"))
                  browser.loadStr("Axon plugin is not installed.")
                else
                  render("axon-home")
              }
            },
          }
          right = GridPane{
            numCols = 2
            Label{it.text = "View src:"},
            Button
            {
              image = viewIcon
              onAction.add |Event e| {goto(search.text)}
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
    browser.onHyperlink.add |Event e|
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

  Void goto(Str where)
  {
    if(where.contains("::"))
    {
      if(where.contains("#"))
        where = where[0 ..< where.index("#")]
      info := Sys.cur.index.matchTypes(where, MatchKind.exact).first
      if(info != null)
      {
        try
        {
         frame.goto(FantomItem(info))
        }
        catch(Err err){err.trace}
      }
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
    search.text = uri.pathStr[1 .. -1] + (uri.frag != null ? "#$uri.frag" : "")
  }

  ** Render a page for the given input text
  ** Delegates to the browser loading from DocWebMod
  internal Void render(Str text)
  {
    port := Sys.cur.docServer.port
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

    search.text = text

    if(! text.isEmpty)
    {
      if(searchType.selectedIndex == 1)
        text += "?type=contains"
      else if(searchType.selectedIndex == 2)
        text += "?type=exact"
    }
    browser.load(`http://127.0.0.1:${port}/$text`)
  }
}


