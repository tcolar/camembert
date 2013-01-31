// History:
//  Jan 29 13 tcolar Creation
//

using fwt

**
** Executable command
**
abstract const class ExecCmd : Cmd
{
  ** How interactive is the command (can user review/edit the command)
  abstract ExecCmdInteractive interaction()

  ** Persist to file or not - Whether to remember across restarts, or just for this session
  abstract Bool persist()

  ** A unique key for the command
  abstract Str cmdKey()

  ** Default command args
  abstract CmdArgs defaultCmd()

  ** The variables for this command (Ex: "env_home" : "/tmp/...")
  virtual Str:Str variables() {[:]}

  ** the folder  where the command will be executed
  abstract File folder()

  abstract |Console|? callback()

  override Void invoke(Event event)
  {
    frame.save

    key := cmdKey

    cmd := frame.process.getCmd(cmdKey)

    if(cmd == null)
    {
      cmd = defaultCmd
      if(interaction != ExecCmdInteractive.never)
        cmd = confirmCmd(cmd)
    }
    else
      if(interaction == ExecCmdInteractive.always)
        cmd = confirmCmd(cmd)

    if(cmd == null)
      return // cancelled

    if(interaction != ExecCmdInteractive.never)
    {
      frame.process.setCmd(cmdKey, cmd, persist)
    }

    cmd.execute(frame.console, variables, callback)
  }

  private CmdArgs? confirmCmd(CmdArgs cmd)
  {
    f := frame.curFile
    runArgsFile :=  frame.process.file
    dir := Text{text = cmd.runDir}
    desc := persist ? Label{text = "This will be saved in $runArgsFile.osPath"} : null
    Text[] texts := Text[,]
    (0 .. 6).each |index|
    {
      texts.add( Text{it.text = cmd.arg(index) ?: ""} )
    }
    dialog := Dialog(frame)
    {
      title = "Exec"
      commands = [ok, cancel]
      body = EdgePane
      {
        it.top = GridPane
        {
          numCols = 2
          Label{text="Command"}, texts[0],
          Label{text="arg1"},  texts[1],
          Label{text="arg2"},  texts[2],
          Label{text="arg3"},  texts[3],
          Label{text="arg4"},  texts[4],
          Label{text="arg5"},  texts[5],
          Label{text="arg6"},  texts[6],
          Label{text="Run in"}, dir,
        }
        it.bottom = desc
        }
      }

      if (Dialog.ok != dialog.open) return null

      d := dir.text.trim
      params := Str[,]
      texts.each
      {
        if( ! it.text.trim.isEmpty)
          params.add(it.text.trim)
      }
      newCmd := CmdArgs.makeManual(params, d)
      return newCmd
  }
}

**************************************************************************
** ExecCmdInteractive
**************************************************************************

** Whether the user gets to review/edit the command before it's executed
** onetime, will ask once and then be remembered after that
enum class ExecCmdInteractive
{
  never, onetime, always
}

**************************************************************************
** CmdArgs
**************************************************************************
@Serializable
const class CmdArgs
{
  const Str[] args
  const Str runDir
  new make(|This| f) {f(this)}

  new makeManual(Str[] args, Str runDir)
  {
    this.args = args
    this.runDir = runDir.trim
  }

  Void execute(Console console, Str:Str variables, |Console|? callback := null)
  {
    if(args.isEmpty)
      return
    params := Str[,]
    dir := runDir
    variables.each |val, key|
    {
      dir = dir.replace("{{$key}}", val)
    }
    args.each
    {
      param := it
      variables.each |val, key|
      {
        param = param.replace("{{$key}}", val)
      }
      params.add(param)
    }
    console.exec(params, File.os(dir), callback)
  }

  Str? arg(Int index)
  {
    args.size > index ? args[index] : null
  }
}