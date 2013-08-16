// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using gfx
using fwt
using util
using syntax

**
** NodePlugin
**
const class GoPlugin : BasicPlugin
{
  static const Str _name := "Go"
  const GoDocs docProv := GoDocs()
  const GoCommands cmds

  override const Image icon := Image(`fan://camGoPlugin/res/go.png`)
  override Uri? defaultEnvHome() {`/usr/`}
  override const Str name := _name
  override PluginCommands? commands() { cmds}
  override PluginDocs? docProvider() {docProv}
  override Bool isIndexing() {docProv.isIndexing.val}

  new make()
  {
    cmds = GoCommands(this)
    syntax := Pod.of(this).file(`/res/syntax-go.fog`)
    addSyntaxRule("go", syntax, ["go"])
  }

  override Bool isProject(File dir)
  {
    return isCustomPrj(dir, "Go")
  }

  override Str prjName(File prjDir)
  {
    return prjDir.name
  }

  override Void onFrameReady(Frame frame, Bool initial := true)
  {
    super.onFrameReady(frame, initial)
    if(initial)
    {
      plugins := (frame.menuBar as MenuBar).plugins
      menu := plugins.children.find{it->text == _name}
      menu.add(MenuItem{ it.command = GoIndexCmd(this).asCommand })
    }
  }
}

const class GoIndexCmd : Cmd
{
  override const Str name := "Re-Index docs"
  const GoPlugin plugin

  new make(GoPlugin plugin)
  {
    this.plugin = plugin
  }

  override Void invoke(Event event)
  {
    plugin.docProv.index
  }
}

const class GoCommands : PluginCommands
{
  override const Cmd run
  override const Cmd runSingle
  override const Cmd test
  override const Cmd testSingle
  override const Cmd build
  override const Cmd buildAndRun

  new make(GoPlugin plugin)
  {
    go := "{{env_home}}/bin/go"

    build       = BasicPluginCmd(plugin, "Build", [go, "build"],
                                 ExecCmdInteractive.onetime, goFinder)
    run         = BasicPluginCmd(plugin, "Run", [go, "run"],
                                 ExecCmdInteractive.onetime, goFinder)
    runSingle   = BasicPluginCmd(plugin, "RunSingle", [go, "run", "{{cur_file}}"],
                                 ExecCmdInteractive.always, goFinder)
    test        = BasicPluginCmd(plugin, "Test", ["go", "test"],
                                 ExecCmdInteractive.onetime, goFinder)
    testSingle  = BasicPluginCmd(plugin, "TestSingle", [go, "test", "{{cur_file}}"],
                                 ExecCmdInteractive.always, goFinder)
    buildAndRun = BasicBuildAndRunCmd(plugin)
  }

  // TODO: deal with relative path
  // ./hello.go:7: undefined: arghhh
  static const |Str -> Item?| goFinder := |Str str -> Item?|
  {
    if(str.size < 4) return null
    p1 := str.index(":", 4); if (p1 == null) return null
    c  := str.index(":", p1 + 1); if (c == null) return null
    p2 := str.index(":", c + 1); if (p2 == null) return null
    file := File.os(str[0 ..< p1].trim)
    if(! file.exists) return null
    pos := str[c+1 ..< p2]
    line := pos.toInt(10, false) ?: 1
    text := str
    return FileItem.makeFile(file).setDis(text).setLoc(
          ItemLoc{it.line = line-1; it.col  = col-1}).setIcon(
          Sys.cur.theme.iconErr)
  }
}

