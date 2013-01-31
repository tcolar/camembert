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
  override const Cmd? build
  override const Cmd? buildGroup
  override const Cmd? run
  override const Cmd? runSingle
  override const Cmd? buildAndRun
  override const Cmd? test := MavenTestCmd()
  override const Cmd? testSingle
}

internal abstract const class MavenCmd : ExecCmd
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

internal const class MavenTestCmd : MavenCmd
{
  override const Str name := "Test"
  override const ExecCmdInteractive interaction := ExecCmdInteractive.onetime
  override const Bool persist := true

  override Str cmdKey()
  {
    return "[$name]"+MavenPlugin.findPomFile(frame.curFile, null)
  }

  override CmdArgs defaultCmd()
  {
    f := MavenPlugin.findPomFile(frame.curFile, null)
    return CmdArgs.makeManual(["{{env_home}}/bin/mvn", "test"], "{{project_dir}}")
  }
}

