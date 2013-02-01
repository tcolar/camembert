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
  override const Cmd build
  override const Cmd run
  override const Cmd runSingle
  override const Cmd test
  override const Cmd testSingle
  override const Cmd buildAndRun

  new make(MavenPlugin plugin)
  {
    build       = MavenCmd(plugin, "Build", "compile", false)
    run         = MavenCmd(plugin, "Run", "exec:exec", false)
    runSingle   = MavenCmd(plugin, "RunSingle", "exec:exec", true)
    test        = MavenCmd(plugin, "Test", "test", false)
    testSingle  = MavenCmd(plugin, "TestSingle", "test", true)
    buildAndRun = BasicBuildAndRunCmd(plugin)
  }

  // TODO: look in projReg for a parent project as defined in the xml and build that ?
  //override const Cmd? buildGroup:= MavenCmd("BuildGroup", "compile", false)
}

internal const class MavenCmd : BasicPluginCmd
{
  override const Str name
  override const ExecCmdInteractive interaction
  override const Bool persist := true
  const Str mavenCmd

  new make(MavenPlugin plugin, Str name, Str mvnCmd, Bool interactiveAlways) : super(plugin)
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

