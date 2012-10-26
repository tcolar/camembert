// To change this License template, choose Tools / Templates
// and edit Licenses / FanDefaultLicense.txt
//
// History:
//   Oct 25, 2012 tcolar Creation
//
using fwt
using concurrent

**
** ProcessUtil
**
class ProcessUtil
{
  private [Str:RunArgs]? runArgs
  private File runArgsFile := Env.cur.workDir + `etc/camenbert/run.fog`
  
  new make()
  {
    if(runArgsFile.exists)
    {
      try
        runArgs = runArgsFile.readObj
      catch(Err e) {e.trace; runArgs = [:]}  
      }  
    else
      runArgs = [:]
  }
  
  File? findBuildFile(File? f)
  {
    if (f == null) return null
      if (f.name == "build.fan") return f

      // lookup up directory tree until we find "build.fan"
    if (!f.isDir) f = f.parent
      while (f.path.size > 0)
    {
      buildFile := f + `build.fan`
      if (buildFile.exists) return buildFile
        f = f.parent
    }
    return null
  }  

  ** Find build / run commands for a given pod
  ** If first time for this pod, ask user first
  RunArgs? findRunCmd(Frame frame)
  {
    f := frame.curFile
    folder := findBuildFile(f)?.parent ?: f.parent
    pod := frame.sys.index.podForFile(f)?.name
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
  }  
  
  Void warnNoBuildFile(Frame frame)
  {
    Dialog.openErr(frame, "No build.fan file found")
  }  
  
  Int waitForProcess(Console console, Duration timeout := 1min)
  {
    Actor(ActorPool(), |Obj? obj-> Obj? | {
        start := DateTime.now
        Console c := (obj as Unsafe).val
        while( c.isBusy )
        {
          Actor.sleep(100ms)
        }
        return c.lastResult  
      }).send(Unsafe(console)).get(timeout)
  }
}

@Serializable
const class RunArgs
{
  const Str pod
  const Str[] args
  const Str? runDir // null if pod dir
  
  new make(|This| f) {f(this)}
  
  new makeManual(Str pod, Str[] args, Str? runDir)
  {
    this.args = args
    this.runDir = runDir
    if(runDir!=null && runDir.trim.isEmpty)
      runDir = null
    this.pod = pod
  }
  
  Void execute(Console console, File defaultDir)
  {
    if(args.isEmpty) 
      return
    folder := runDir != null ? File.os(runDir) : defaultDir
    if(args[0]=="fan" || args[0] == "fan.exe")    
      console.execFan(args[1 .. -1], folder) 
    else  
      console.exec(args, folder) 
  }
}

