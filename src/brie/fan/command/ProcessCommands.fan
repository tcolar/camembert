using fwt
using concurrent

internal const class TerminateCmd : Cmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Terminate"
  override Void invoke(Event event)
  {
    console.kill
  }
}


**************************************************************************
** BuildCmd
**************************************************************************

internal const class BuildCmd : Cmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Build"
  override Void invoke(Event event)
  {
    // save current file
    frame.save

    f := frame.process.findBuildFile(frame.curFile)
    if (f == null)
    {
      frame.process.warnNoBuildFile(frame)
      return
    }

    console.execFan([f.osPath], f.parent) |c|
    {
      pod := sys.index.podForFile(f)
      if (pod != null)
        sys.index.reindexPod(pod)
    }
  }
}

**
** Command to run a pod
**
internal const class RunCmd : Cmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Run"
  override Void invoke(Event event)
  {
    cmd := frame.process.findRunCmd(frame)
    f := frame.curFile
    defaultDir := frame.process.findBuildFile(f)?.parent ?: f.parent

    cmd?.execute(console, defaultDir)
  }
}

internal const class BuildAndRunCmd : Cmd
{
  new make(|This| f) {f(this)}
  override const Str name := "BuildAndRun"
  override Void invoke(Event event)
  {
    sys.commands.build.invoke(event)
    Desktop.callAsync |->|{
      frame.process.waitForProcess(console, 3min)
      if(console.lastResult == 0 )
        sys.commands.run.invoke(event)
    }
  }
}