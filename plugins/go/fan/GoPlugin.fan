// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using gfx
using fwt
using util
using syntax
using netColarUtils

**
** GoPlugin
**
const class GoPlugin : BasicPlugin
{
  static const Str _name := "Go"
  const GoDocs docProv := GoDocs()
  const GoCommands cmds

  override const Image icon := Image(`fan://camGoPlugin/res/go.png`)
  override const Str name := _name
  override PluginCommands? commands() {cmds}
  override PluginDocs? docProvider() {docProv}
  override Bool isIndexing() {docProv.isIndexing.val}
  override Type? envType() {GoEnv#}

  const GoFmtCmd fmtCmd

  new make()
  {
    cmds = GoCommands(this)
    syntax := Pod.of(this).file(`/res/syntax-go.fog`)
    addSyntaxRule("go", syntax, ["go"])
    fmtCmd = GoFmtCmd(this)
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
    if(initial)
    {
      super.onFrameReady(frame, initial)
      plugins := (frame.menuBar as MenuBar).plugins
      menu := plugins.children.find{it->text == _name}
      menu.add(MenuItem{ it.command = GoIndexCmd(this).asCommand })
      menu.add(MenuItem{ it.command = GoFmtCmd(this).asCommand })
    }
  }

  override Space createSpace(Project prj)
  {
    return GoSpace(Sys.cur.frame, prj.dir.toFile, this.typeof.pod.name, icon.file.uri)
  }

  override Void onFileSaved(File f) {
    e := Event()
    e.data = f
    fmtCmd.invoke(e)
  }

  override Void onInit(File configDir)
  {
    // create go template if not there yet
    go := configDir + `templates/go_file.json`
    if( ! go.exists)
      JsonUtils.save(go.out, Template{it.name="Go file"
        it.extensions=["go"]
        it.text="// History: {date} {user} Creation\n\npackage {folder}\n\nimport ()\n\n"})
  }
}

// Go format command
const class GoFmtCmd : Cmd
{
  const GoPlugin plugin

  new make(GoPlugin plugin)
  {
    this.plugin = plugin
  }

  override const Str name := "GoFmt on current file."
  override Void invoke(Event event)
  {
    f := event.data as File
    if(f == null)
    {
      // this is when called manually from the menu rater than automatically on save
      f = frame.curFile
      // Save the file first before calling goFmt
      frame.save()
    }
    if(!f.exists || f.ext != "go")
      return
    config := PluginManager.cur.conf(GoPlugin._name) as BasicConfig
    if(config == null)
      return
    env := config.curEnv as GoEnv
    if(env == null || ! env.goFmtOnSave)
      return
    distro := env.envHome.toFile
    if( ! distro.exists)
      return
    goFmt := distro + `./bin/gofmt`
    if( ! goFmt.exists)
      return

    opts := env.goFmtOpts
    if(opts.isEmpty)
      opts = [goFmt.osPath, "-w", "{{file}}"] // default
    options := Str[goFmt.osPath]
    opts.each
    {
      options.add(it.replace("{{file}}", f.name))
    }

    // Remember the current location in file
    // Note that it might become "invalid" depending what gofmt does
    item := frame.curSpace.curFileItem

    frame.console.log("Running " + options)
    p := Process(options, f.parent)
    id := Sys.cur.processManager.register(p, "GoFmt")
    try
      p.run().join()
    finally
      Sys.cur.processManager.unregister(id)
    frame.curSpace.refresh
    frame.curView.onGoto(item)
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

  static File? goPath()
  {
    config := PluginManager.cur.conf("Go") as BasicConfig
    if(config == null) return null
    env := config.curEnv as GoEnv
    if(env == null) return null
    goPath := env.goPath.toFile
    if( ! goPath.exists) return null
    return goPath
  }

  static File? prj()
  {
    plugin := (GoPlugin) PluginManager.cur.plugins["camGoPlugin"]
    return plugin.findProject(Sys.cur.frame.curFile)
  }

  ** Error:
  **    ./hello.go:7: undefined: dsfdfgd
  ** Log:
  **    2013/10/09 14:50:17 drupsway_test.go:75: a:1:{s:9:"cc_number";b:0;}
  ** Relative path sometimes, absolute paths other times
  static const |Str -> Item?| goFinder := |Str str -> Item?|
  {
    startAt := 0
    error := true
    if(str.size < 4) return null
    if(str.size > 20 && str[4]=='/' && str[7] == '/' && str[13]==':' && str[16]==':')
    {
      startAt = 20
      error = false
    }
    p1 := str.index(":", startAt); if (p1 == null) return null
    c  := str.index(":", p1 + 1); if (c == null) return null
    // Try absolute path
    path := Uri(str[startAt ..< p1].trim)
    file := path.toFile
    if(! file.exists){
    // Try relative to goPath
      file = goPath + path
    }
    if(! file.exists){
      // Try relative to project
      file = prj + path
    }
    if(! file.exists)
      return null
    pos := str[p1 + 1 ..< c]
    line := pos.toInt(10, false) ?: 1
    text := str
    icon := error ? Sys.cur.theme.iconErr: Sys.cur.theme.iconMark
    return FileItem.makeFile(file).setDis(text).setLoc(
          ItemLoc{it.line = line-1; it.col  = col-1}).setIcon(
          icon)
  }
}

