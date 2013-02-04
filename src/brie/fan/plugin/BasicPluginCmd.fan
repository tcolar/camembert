// History:
//  Jan 31 13 tcolar Creation
//

using fwt

const class BasicPluginCmd : ExecCmd
{
  override const Str name
  override const ExecCmdInteractive interaction
  override const Bool persist
  override const |Str -> Item?|? itemFinder
  const BasicPlugin plugin
  const BasicEnv env
  const Str[] args

  new make(BasicPlugin plugin, Str name, Str[] args,
           ExecCmdInteractive interaction, |Str -> Item?|? itemFinder := null)
  {
    this.plugin = plugin
    this.env = BasicPlugin.config(plugin.name).curEnv
    this.name = name
    this.args = args
    this.interaction = interaction
    this.persist = interaction != ExecCmdInteractive.never
    this.itemFinder = itemFinder
  }

  override Str:Str variables()
  {
    return ["env_home" : env.envHome.toFile.osPath,
     "project_dir" : plugin.findProject(frame.curFile).osPath,
     "cur_file" : frame.curFile.osPath]
  }

  override const |Console|? callback := null

  override CmdArgs defaultCmd()
  {
    return  CmdArgs.makeManual(args, "{{project_dir}}")
  }

  override File folder()
  {
    return plugin.findProject(frame.curFile)
  }

  override Str cmdKey()
  {
    return "[$name]"+plugin.findProject(frame.curFile)
  }
}

const class BasicBuildAndRunCmd : Cmd
{
  const BasicPlugin plugin

  new make(BasicPlugin plugin)
  {
    this.plugin = plugin
  }

  override const Str name := "BuildAndRun"
  override Void invoke(Event event)
  {
    plugin.commands.build.invoke(event)
    Desktop.callAsync |->|{
      frame.process.waitForProcess(console, 3min)
      if(console.lastResult == 0 )
        plugin.commands.run.invoke(event)
    }
  }
}

