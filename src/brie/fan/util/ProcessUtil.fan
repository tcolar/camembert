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
  ** Build pod args -> saved in memory and persisted in file
  private [Str:RunArgs]? runArgs
  private File runArgsFile := Env.cur.workDir + `etc/camembert/run.fog`

  ** Single run args -> just kep in memory for session
  private File:RunArgs runSingleArgs := [:]
  private File:RunArgs testSingleArgs := [:]

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
    return FileUtil.findBuildPod(f.parent, null)
  }

  File? findBuildGroup(File? f)
  {
    return FileUtil.findBuildGroup(f.parent, null)
  }

  ** Find build / run commands for a given pod
  ** If first time for this pod, ask user first
  RunArgs? findRunCmd(Frame frame)
  {
    f := frame.curFile
    folder := findBuildFile(f)?.parent ?: f.parent
    pod := Sys.cur.index.podForFile(f)?.name
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
    Dialog.openErr(frame, "No build.fan BuildPod file found")
  }

  Void warnNoBuildGroupFile(Frame frame)
  {
    Dialog.openErr(frame, "No build.fan / buildall.fan BuildGroup file found")
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

  RunArgs? findRunSingleCmd(Frame frame)
  {
    f := frame.curFile
    if(f==null)
      return null

    folder := findBuildFile(f)?.parent ?: f.parent
    pod := Sys.cur.index.podForFile(f)?.name
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

    pod := Sys.cur.index.podForFile(f)?.name
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
    else if(args[0]=="fant" || args[0] == "fant.exe")
      console.execFan(args[1 .. -1], folder, null, "fant")
    else
      console.exec(args, folder)
  }

  Str? arg(Int index)
  {
    args.size > index ? args[index] : null
  }
}

