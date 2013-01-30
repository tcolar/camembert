// History:
//  Jan 25 13 tcolar Creation
//

using fwt

internal const class FantomCommands : PluginCommands
{
  override const Cmd? build := FantomBuildCmd()
  override const Cmd? buildGroup
  override const Cmd? run
  override const Cmd? runSingle
  override const Cmd? buildAndRun
  override const Cmd? test
  override const Cmd? testSingle
}

internal abstract const class FantomCmd : ExecCmd
{
  const FantomPlugin plugin := FantomPlugin.cur
  const FantomEnv env := FantomPlugin.config.curEnv
  override Str:Str variables() {["env_home":env.fantomHome.toFile.osPath]}

  /*Void execFan(Str cmd, Str[] args, File dir, Func callback)
  {
    env := FantomPlugin.curEnv
    exe := env.fantomHome + `/bin/$cmd`
    args = args.dup.insert(0, exe)
    console.exec(args, dir, callback)
  }*/
}

internal const class SwitchConfigCmd : Cmd
{
  override const Str name

  override Void invoke(Event event)
  {
    MenuItem mi := event.widget
    // Note: we receive an event for the "deselected" item as well
    if(mi.selected)
    {
      Desktop.callAsync |->|
      {
        FantomPlugin.config.selectEnv(name)
        plugin := Sys.cur.plugin(FantomPlugin#)
        // TODO: we need to reload the fantom index etc ...
      }
    }
  }

  new make(Str envName)
  {
    this.name = envName
  }
}

/*internal const class TerminateCmd : FantomCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Terminate"
  override Void invoke(Event event)
  {
    console.kill
  }
}*/


**************************************************************************
** BuildCmd
**************************************************************************

internal const class FantomBuildCmd : FantomCmd
{
  override const Str name := "Build"
  override const ExecCmdInteractive interaction := ExecCmdInteractive.never
  override const Bool persist := false
  override const |Console|? callback := |Console c| {
    f := FantomPlugin.findBuildFile(frame.curFile)
    pod := plugin.index.podForFile(f)
    if (pod != null)
      plugin.index.reindexPod(pod)
  }

  override File? keyFile()
  {
    kf := FantomPlugin.findBuildFile(frame.curFile)
    if(kf == null)
      FantomPlugin.warnNoBuildFile(frame)
    return kf
  }

  override CmdArgs defaultCmd()
  {
    f := FantomPlugin.findBuildFile(frame.curFile)
    return CmdArgs.makeManual(["{{env_home/bin/fan}}", f.osPath], f.parent.osPath)
  }
}
/*
internal const class BuildGroupCmd : FantomCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Build Group"
  override Void invoke(Event event)
  {
    // save current file
    frame.save

    f := frame.process.findBuildGroup(frame.curFile)
    if (f == null)
    {
      frame.process.warnNoBuildGroupFile(frame)
      return
    }

    execFan("fan", [f.osPath], f.parent) |c|
    {
      plugin.index.pods.each |p|
      {
        if(p.srcDir != null && FileUtil.contains(f.parent, p.srcDir))
          plugin.index.reindexPod(p)
      }
    }
  }
}


**
** Command to run a pod
**
internal const class RunPodCmd : FantomCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Run Pod"
  override Void invoke(Event event)
  {
    cmd := frame.process.findRunCmd(frame)

    f := frame.curFile
    defaultDir := frame.process.findBuildFile(f)?.parent ?: f.parent

    cmd?.execute(console, defaultDir)
  }
}

internal const class BuildAndRunCmd : FantomCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "BuildAndRun"
  override Void invoke(Event event)
  {
    Sys.cur.commands.build.invoke(event)
    Desktop.callAsync |->|{
      frame.process.waitForProcess(console, 3min)
      if(console.lastResult == 0 )
        Sys.cur.commands.runPod.invoke(event)
    }
  }
}

**
** Command to run a single item
**
internal const class RunSingleCmd : FantomCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Run Single"
  override Void invoke(Event event)
  {
    cmd := frame.process.findRunSingleCmd(frame)
    f := frame.curFile
    defaultDir := frame.process.findBuildFile(f)?.parent ?: f.parent

    cmd?.execute(console, defaultDir)
  }
}

**
** Command to test a single item
**
internal const class TestPodCmd : FantomCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Test Pod"
  override Void invoke(Event event)
  {
    f := frame.curFile
    pod := plugin.index.podForFile(f)?.name

    if(pod == null)
     return

    folder := frame.process.findBuildFile(f)?.parent ?: f.parent

    RunArgs.makeManual(pod, ["fant", pod], null).execute(console, folder)
  }
}


**
** Command to test a single item
**
internal const class TestSingleCmd : FantomCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Test Single"
  override Void invoke(Event event)
  {
    cmd := frame.process.findTestSingleCmd(frame)
    f := frame.curFile
    defaultDir := frame.process.findBuildFile(f)?.parent ?: f.parent

    cmd?.execute(console, defaultDir)
  }
}*/



