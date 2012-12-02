
using fwt
using gfx
using fandoc
using compilerDoc

// TODO: when in axon file/prj search axon libs only ?

** Sidebar to search / display fandocs
class HelpPane : ContentPane
{
  WebBrowser? browser
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
        text=""
        prefCols = 15
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
          Button{image = gfx::Image(`fan://icons/x16/arrowLeft.png`);
          onAction.add |Event e|
            {
              browser.back
            }
          },
          Button{image = gfx::Image(`fan://camembert/res/home.png`, false);
          onAction.add |Event e| {render("")}},
          search,
        }
        center = Button
        {
          it.text = "Open in Editor"
          onAction.add |Event e|
          {
            goto(search.text)
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

  Void goto(Str where)
  {
    if(where.contains("::"))
    {
      if(where.contains("#"))
        where = where[0 ..< where.index("#")]
      info := sys.index.matchTypes(where, MatchKind.exact).first
      if(info != null)
      {
        try
        {
         frame.goto(Item(info))
        }
        catch(Err err){}
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

    browser.load(`http://127.0.0.1:8787/$text`)
  }
}


