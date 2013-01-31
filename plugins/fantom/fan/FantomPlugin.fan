// History:
//  Jan 05 13 tcolar Creation
//

using gfx
using netColarUtils
using fwt
using camembert

**
** FantomPlugin
** Builtin plugin for fantom features
**
const class FantomPlugin : Plugin
{
  static const Str _name := "camFantomPlugin"

  ** FantomIndexing service
  const FantomIndex index

  override PluginCommands? commands() {FantomCommands()}
  override PluginDoc? docProvider() {FantomDoc(this)}
  override Str name() {return _name}

  new make()
  {
    index = FantomIndex()
  }

  override PluginConfig? readConfig(Sys sys)
  {
    return FantomConfig(sys)
  }

  override Void onFrameReady(Frame frame)
  {
    (frame.menuBar as MenuBar).plugins.add(FantomMenu(frame))
    index.reindexAll
  }

  override Bool isIndexing() {index.isIndexing}

  override const |Uri -> Project?| projectFinder:= |Uri uri -> Project?|
  {
    f := uri.toFile
    if( ! f.exists || ! f.isDir) return null
     // pod group
     buildFile := FantomUtils.findBuildPod(f, f)
     if(buildFile != null)
      return Project{
        it.dis = FantomUtils.getPodName(f)
        it.dir = f.uri
        it.icon = Sys.cur.theme.iconPod
        it.plugin = name
      }

     // pod
     buildFile = FantomUtils.findBuildGroup(f, f)
     if(buildFile != null)
      return Project{
        it.dis = FantomUtils.getPodName(f)
        it.dir = f.uri
        it.icon = Sys.cur.theme.iconPodGroup
        it.plugin = name
        it.params = ["isGroup" : "true"]
      }
     return null
  }

  override Space createSpace(Project prj)
  {
    return FantomSpace(Sys.cur.frame, prj.dir.toFile, null)
  }

  override Int spacePriority(Project prj)
  {
    if(prj.plugin != FantomPlugin._name)
      return 0
    // group
    if(prj.params["isGroup"] == "true")
      return 55
    //pod
    return 50
  }

  override Image? iconForFile(File file)
  {
    if(file.isDir)
    {
      pod := index.isPodDir(file)
      if(pod != null)
        return Sys.cur.theme.iconPod
      group := index.isGroupDir(file)
      if(group != null)
        return Sys.cur.theme.iconPodGroup
    }
    // fantom files handled by standard Theme code
    return null
  }

  override Void onShutdown(Bool isKill := false)
  {
    if( ! isKill)
    {
      index.cache.pool.stop
      index.crawler.pool.stop
    }
    else
    {
      index.cache.pool.kill
      index.crawler.pool.kill
    }
  }

  // Utilities

  static FantomConfig config()
  {
    return (FantomConfig) PluginManager.cur.conf(_name)
  }

  static FantomPlugin cur()
  {
    return (FantomPlugin) Sys.cur.plugin(_name)
  }

  static File? findBuildFile(File? f)
  {
    return FantomUtils.findBuildPod(f.parent, null)
  }

  static File? findBuildGroup(File? f)
  {
    return FantomUtils.findBuildGroup(f.parent, null)
  }

  ** Find build / run commands for a given pod
  ** If first time for this pod, ask user first
  /*RunArgs? findRunCmd(Frame frame)
  {
    f := frame.curFile
    folder := findBuildFile(f)?.parent ?: f.parent
    pod := index.podForFile(f)?.name
    if(pod == null)
    {
      Dialog.openErr(frame, "Could not find pod for $f, not built ?")
      return null
    }
    args := runArgs[pod]
    if(args == null)
    {
      // First time running this, ask the user
      cmd := Text{text="fan"}
      arg1 := Text{text="$pod"}
      arg2 := Text(); arg3 := Text(); arg4 := Text(); arg5 := Text(); arg6 := Text();
      dir := Text{text = folder.osPath}
      dialog := Dialog(frame)
      {
        title = "Run"
        commands = [ok, cancel]
        body = EdgePane
        {
          it.top = GridPane
          {
            numCols = 2
            Label{text="Command"}, cmd,
            Label{text="arg1"}, arg1,
            Label{text="arg2"}, arg2,
            Label{text="arg3"}, arg3,
            Label{text="arg4"}, arg4,
            Label{text="arg5"}, arg5,
            Label{text="arg6"}, arg6,
            Label{text="Run in"}, dir,
          }
          it.bottom = Label{text = "This will be saved in $runArgsFile.osPath"}
        }
      }

      if (Dialog.ok != dialog.open) return null

        d := (dir.text.trim == folder.osPath) ? null : dir.text.trim
      params := Str[,]
      [cmd.text, arg1.text, arg2.text, arg3.text, arg4.text, arg5.text, arg6.text].each
      {
        if( ! it.trim.isEmpty) {params.add(it.trim)}
        }
      runArgs[pod] = RunArgs.makeManual(pod, params, d)

      runArgsFile.writeObj(runArgs)
    }

    return runArgs[pod]
  }*/

  static Void warnNoBuildFile(Frame frame)
  {
    Dialog.openErr(frame, "No build.fan BuildPod file found")
  }

  static Void warnNoBuildGroupFile(Frame frame)
  {
    Dialog.openErr(frame, "No build.fan / buildall.fan BuildGroup file found")
  }

  /*RunArgs? findRunSingleCmd(Frame frame)
  {
    f := frame.curFile
    if(f==null)
      return null

    folder := findBuildFile(f)?.parent ?: f.parent
    pod := index.podForFile(f)?.name
    target := pod == null ? f.basename : "${pod}::$f.basename"
    cmd := runSingleArgs[f]

    command := Text{text = cmd?.arg(0) ?: "fan"}
    arg1 := Text{text= cmd?.arg(1) ?: target}
    arg2 := Text{text = cmd?.arg(2) ?: ""}
    arg3 := Text{text = cmd?.arg(3) ?: ""}
    arg4 := Text{text = cmd?.arg(4) ?: ""}
    arg5 := Text{text = cmd?.arg(5) ?: ""}
    arg6 := Text{text = cmd?.arg(6) ?: ""}
    dir := Text{text = folder.osPath}
    dialog := Dialog(frame)
    {
      title = "Run"
      commands = [ok, cancel]
      body = EdgePane
      {
        it.center = GridPane
        {
          numCols = 2
          Label{text="Command"}, command,
          Label{text="arg1"}, arg1,
          Label{text="arg2"}, arg2,
          Label{text="arg3"}, arg3,
          Label{text="arg4"}, arg4,
          Label{text="arg5"}, arg5,
          Label{text="arg6"}, arg6,
          Label{text="Run in"}, dir,
        }
      }
    }

    if (Dialog.ok != dialog.open) return null

    d := (dir.text.trim == folder.osPath) ? null : dir.text.trim
    params := Str[,]
    [command.text, arg1.text, arg2.text, arg3.text, arg4.text, arg5.text, arg6.text].each
    {
      if( ! it.trim.isEmpty) {params.add(it.trim)}
    }
    runSingleArgs[f] = RunArgs.makeManual(pod, params, d)

    return runSingleArgs[f]
  }

  RunArgs? findTestSingleCmd(Frame frame)
  {
    f := frame.curFile
    if(f==null)
      return null

    pod := index.podForFile(f)?.name
    target := pod == null ? f.basename : "${pod}::$f.basename"
    cmd := testSingleArgs[f]

    command := Text{text = cmd?.arg(0) ?: "fant"}
    arg1 := Text{text= cmd?.arg(1) ?: target}
    dialog := Dialog(frame)
    {
      title = "Test"
      commands = [ok, cancel]
      body = EdgePane
      {
        it.center = GridPane
        {
          numCols = 2
          Label{text="Fant target:"}, arg1,
        }
      }
    }

    if (Dialog.ok != dialog.open) return null

    params := ["fant", arg1.text.trim]
    testSingleArgs[f] = RunArgs.makeManual(pod, params, null)

    return testSingleArgs[f]
  }*/

}