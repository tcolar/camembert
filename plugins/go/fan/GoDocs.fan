// History:
//  Jul 22 13 tcolar Creation
//

using camembert
using gfx
using web
using concurrent
using util
using netColarUtils

**
** GoDocs, provides acces to go documentation
**
const class GoDocs : PluginDocs
{
  override const Image? icon := Image(`fan://camGoPlugin/res/go.png`, false)

  const AtomicInt _goDoc := AtomicInt(0)
  const AtomicBool isIndexing := AtomicBool(false)

  ** name of the plugin responsible
  override Str pluginName() {this.typeof.pod.name}

  ** User friendly dsplay name
  override Str dis() {"Go"}

  ** Return a FileItem for the document matching the current source file (if known)
  ** TODO : when open item is a source file
  override FileItem? findSrc(Str query) {null}

  ** Return html for a given path
  ** Note, the query will be prefixed with the plugin name for example /fantom/fwt::Button
  override Str html(WebReq req, Str query, MatchKind matchKind)
  {
    if(isIndexing.val)
      return "Indexing in Progress"

    if(_goDoc.val == 0)
    {
      run
      Actor.sleep(2sec) // let godoc start
    }

    port := _goDoc.val
    query = query.trim

    html := ""
    try
    {
      // "Override" the stylesheet with some custom styles to make it
      // render better and according to the theme in the help pane.
      if(query == "doc/style.css")
        html = WebClient(`http://localhost:${port}/$query`).getStr + customCss
      else if(query == "pkg")
        html = WebClient(`http://localhost:${port}/pkg/`).getStr
      else if(query.contains("/"))
        html = WebClient(`http://localhost:${port}/$query`).getStr
      else if(query.isEmpty)
        html = "<a href='/$pluginName/pkg/'>All Packages</a>"
      else
        html = WebClient(`http://localhost:${port}/search?q=$query`).getStr

      html = html.replace("""href="/""", """href="/$pluginName/""")
      html = html.replace("""src="/""", """/src="/$pluginName/""")
    }
    catch(Err e)
    {
      e.trace
      html = "Could not connect to GoDoc, not indexed yet ?"
    }
    return html
  }

  Void run()
  {
    if(_goDoc.val != 0)
      return

    config := PluginManager.cur.conf(dis) as BasicConfig
    if(config == null) {echo("Godoc error: Missing config"); return}
    env := config.curEnv as BasicEnv
    if(env == null)  {echo("Godoc error: Missing env"); return}
    goPath := env.envHome.toFile
    if( ! goPath.exists)  {echo("Godoc error: envHome is not set properly to GoPath in the Go env !"); return}

    port := NetUtils.findAvailPort(6060)

    idx := PluginManager.cur.configDir + `state/go_index`

    if(! idx.exists){echo("No index yet"); return}

    goDoc := goPath + `bin/godoc`
    goArgs := [goDoc.osPath, "-http=:$port", "-index=true",
        "-index_files=$idx"]

    echo(goArgs)

    p := Process(goArgs)
    try
      p.run
    catch(Err e) {e.trace}
    _goDoc.val = port
  }

  Void index()
  {
    if(isIndexing.val)
      return // alreday indexing
    Actor(ActorPool(), |Obj? obj -> Obj?|
    {
      isIndexing.val = true

      try
      {
        config := PluginManager.cur.conf(dis) as BasicConfig
        if(config == null) {echo("Godoc error: Missing config"); isIndexing.val = false; return null}
        env := config.curEnv as BasicEnv
        if(env == null)  {echo("Godoc error: Missing env"); isIndexing.val = false ;return null}
        goPath := env.envHome.toFile
        if( ! goPath.exists)  {echo("Godoc error: envHome is not set properly to GoPath in the Go env !"); isIndexing.val = false; return null}

        idx := PluginManager.cur.configDir + `state/go_index`

        goDoc := goPath + `bin/godoc`
        goArgs := [goDoc.osPath, "-index=true",
            "-write_index=true", "-index_files=$idx"]

        echo(goArgs)

        p := Process(goArgs)
        p.run
        p.join
      } catch(Err e) {e.trace}
      finally{
        isIndexing.val = false
      }
      return null
    }).send("run")
  }

Str customCss(){
"""
    /*Camembert overrides*/
    body{background-color:$Sys.cur.theme.bg;color : $Sys.cur.theme.fontColor;}
    pre{background : $Sys.cur.theme.helpBg1;margin:5px; padding:5px;white-space: pre-wrap}
    h2{background-color : $Sys.cur.theme.helpBg2; color : #e8f8f2;}
    a{color : $Sys.cur.theme.edStr.fg;}
    pre .comment {color: $Sys.cur.theme.edComment.fg; }
    #topbar{display : none}
    .gopher{display : none;}
    #plusone{display : none;}
    .dir {font-size:0px;}
    .name{font-size : 14px;}"""
  }
}