using fwt
using concurrent 

**************************************************************************
** EscCmd
**************************************************************************

internal const class EscCmd : Cmd
{
  override const Str name := "Close Console"
  override const Key? key := Key("Esc")
  override Void invoke(Event event)
  {
    frame.marks = Item[,]
    frame.console.close
    frame.curView?.onReady
  }
}

internal const class TerminateCmd : Cmd
{
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
  override const Str name := "Build"
  override const Key? key := Key("F9")
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
  override const Str name := "Run"
  override const Key? key := Key("F5")
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
  override const Str name := "BuildAndRun"
  override const Key? key := Key("F6")
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