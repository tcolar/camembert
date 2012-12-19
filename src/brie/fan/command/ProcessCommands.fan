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

internal const class BuildGroupCmd : Cmd
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

    console.execFan([f.osPath], f.parent) |c|
    {
      sys.index.pods.each |p|
      {
        if(p.srcDir != null && FileUtil.contains(f.parent, p.srcDir))
          sys.index.reindexPod(p)
      }
    }
  }
}


**
** Command to run a pod
**
internal const class RunPodCmd : Cmd
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
        sys.commands.runPod.invoke(event)
    }
  }
}

**
** Command to run a single file
**
internal const class RunSingleCmd : Cmd
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


