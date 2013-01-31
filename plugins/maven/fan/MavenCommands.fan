// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using fwt

**
** MavenCommands
**
internal const class MavenCommands : PluginCommands
{
  override const Cmd build      := MavenCmd("Build", "compile", false)
  //override const Cmd? buildGroup
  override const Cmd run        := MavenCmd("Run", "exec:exec", false)
  override const Cmd runSingle  := MavenCmd("RunSingle", "exec:exec", true)
  override const Cmd test       := MavenCmd("Test", "test", false)
  override const Cmd testSingle := MavenCmd("TestSingle", "test", true)
  override const Cmd buildAndRun:= BuildAndRunCmd{}
}

internal abstract const class MavenBaseCmd : ExecCmd
{
  MavenPlugin plugin() {MavenPlugin.cur}
  MavenEnv env() {MavenPlugin.config.curEnv}
  override Str:Str variables()
  {
    return ["env_home" : env.mavenHome.toFile.osPath,
     "project_dir" : MavenPlugin.findPomFile(frame.curFile, null).parent.osPath]
  }
  override const |Console|? callback := null
  override File folder()
  {
    return MavenPlugin.findPomFile(frame.curFile, null).parent
  }
  override Str cmdKey()
  {
    return "[$name]"+MavenPlugin.findPomFile(frame.curFile, null)
  }
}

internal const class SwitchConfigCmd : Cmd
{
  override const Str name

  override Void invoke(Event event)
  {
    MenuItem mi := event.widget
    if(mi.selected)
    {
      Desktop.callAsync |->|
      {
        MavenPlugin.config.selectEnv(name)
      }
    }
  }

  new make(Str envName)
  {
    this.name = envName
  }
}

internal const class MavenCmd : MavenBaseCmd
{
  override const Str name
  override const ExecCmdInteractive interaction
  override const Bool persist := true
  const Str mavenCmd

  new make(Str name, Str mvnCmd, Bool interactiveAlways)
  {
    this.name = name
    this.mavenCmd = mvnCmd
    this.interaction = interactiveAlways ? ExecCmdInteractive.always
                                          : ExecCmdInteractive.onetime
  }

  override CmdArgs defaultCmd()
  {
    return CmdArgs.makeManual(["{{env_home}}/bin/mvn", mavenCmd], "{{project_dir}}")
  }
}

internal const class BuildAndRunCmd : Cmd
{
  new make(|This| f) {f(this)}
  override const Str name := "BuildAndRun"
  override Void invoke(Event event)
  {
    MavenPlugin.cur.commands.build.invoke(event)
    Desktop.callAsync |->|{
      frame.process.waitForProcess(console, 3min)
      if(console.lastResult == 0 )
        MavenPlugin.cur.commands.run.invoke(event)
    }
  }
}

