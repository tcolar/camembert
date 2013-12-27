// History:
//  Jan 25 13 tcolar Creation
//

using fwt
using camembert

const class FantomCommands : PluginCommands
{
  override const Cmd build      := BuildCmd()
  override const Cmd buildGroup := BuildGroupCmd()
  override const Cmd run        := RunPodCmd(false, false)
  override const Cmd runSingle  := RunPodCmd(true, false)
  override const Cmd test       := RunPodCmd(false, true)
  override const Cmd testSingle := RunPodCmd(true, true)
  override const Cmd buildAndRun:= BuildAndRunCmd{}
}

abstract const class FantomCmd : ExecCmd
{
  FantomPlugin plugin() {FantomPlugin.cur}
  FantomEnv env() {
    config := PluginManager.cur.conf("Fantom") as BasicConfig
    return config.curEnv
  }
  override const |Str -> Item?|? itemFinder := |Str str -> Item?|
  {
    return ConsoleFinders.fanFinder(str) ?: ConsoleFinders.javaFinder(str)
  }
  override Str:Str variables()
  {
    ["env_home" : env.fantomHome.toFile.osPath,
     "project_dir" : FantomPlugin.findBuildFile(frame.curFile).parent.osPath,
     "cur_file" : frame.curFile.osPath]
  }
  override File folder()
  {
    return FantomPlugin.findBuildFile(frame.curFile).parent
  }
  override Str cmdKey()
  {
    kf := FantomPlugin.findBuildFile(frame.curFile)
    if(kf == null)
      FantomPlugin.warnNoBuildFile(frame)
    return "[$name]$kf"
  }
}

internal abstract const class FantomGroupCmd : ExecCmd
{
  FantomPlugin plugin() {FantomPlugin.cur}
  FantomEnv env() {
    config := PluginManager.cur.conf("Fantom") as BasicConfig
    return config.curEnv
  }
  override const |Str -> Item?|? itemFinder := |Str str -> Item?|
  {
    return ConsoleFinders.fanFinder(str) ?: ConsoleFinders.javaFinder(str)
  }
  override Str:Str variables()
  {
    ["env_home" : env.fantomHome.toFile.osPath,
     "project_dir" : FantomPlugin.findBuildGroup(frame.curFile).parent.osPath,
     "cur_file" : frame.curFile.osPath]
  }
  override File folder()
  {
    return FantomPlugin.findBuildGroup(frame.curFile).parent
  }

  override Str cmdKey()
  {
    kf := FantomPlugin.findBuildGroup(frame.curFile)
    if(kf == null)
      FantomPlugin.warnNoBuildGroupFile(frame)
    return "[$name]$kf"
  }
}

internal const class SwitchConfigCmd : Cmd
{
  override const Str name

  override Void invoke(Event event)
  {
    MenuItem mi := event.widget
    // Note: we receive an event for the "deselected" item as well
    if(mi.selected)
    {
      Desktop.callAsync |->|
      {
        frame.curEnv = name
        config := PluginManager.cur.conf("Fantom") as BasicConfig
        config.selectEnv(name)
        ReindexAllCmd().invoke(event)
      }
    }
  }

  new make(Str envName)
  {
    this.name = envName
  }
}

internal const class ReindexAllCmd : Cmd
{
  override const Str name := "Reindex All"

  override Void invoke(Event event)
  {
    plugin := FantomPlugin.cur
    File[] srcDirs := ProjectRegistry.pluginProjects(FantomPlugin#.pod.name)
                      .vals.map |proj -> File| {proj.dir.toFile}
    config := PluginManager.cur.conf("Fantom") as BasicConfig
    env := config.curEnv as FantomEnv
    File[] podDirs := env.podDirs
                      .map |uri -> File| {uri.plusSlash.toFile}
    plugin.index.reindex(srcDirs, podDirs, true)
  }
}

**************************************************************************
** BuildCmd
**************************************************************************

internal const class BuildCmd : FantomCmd
{
  override const Str name := "Build"
  override const ExecCmdInteractive interaction := ExecCmdInteractive.never
  override const Bool persist := false
  override const |Console|? callback := |Console c| {
    Desktop.callAsync |->|{
      f := FantomPlugin.findBuildFile(frame.curFile)
      pod := plugin.index.podForFile(f)
      if (pod != null)
        plugin.index.reindexPod(pod)
    }
  }

  override CmdArgs defaultCmd()
  {
    f := FantomPlugin.findBuildFile(frame.curFile)
    return CmdArgs.makeManual(["{{env_home}}/bin/fan", f.osPath], "{{project_dir}}")
  }
}

internal const class BuildGroupCmd : FantomGroupCmd
{
  override const Str name := "Build Group"
  override const ExecCmdInteractive interaction := ExecCmdInteractive.never
  override const Bool persist := false
  override const |Console|? callback := |Console c| {
    Desktop.callAsync |->|{
      f := FantomPlugin.findBuildGroup(frame.curFile)
      plugin.index.pods.each |p|
      {
        if(p.srcDir != null && FileUtil.contains(f.parent, p.srcDir))
          plugin.index.reindexPod(p)
      }
    }
  }

  override CmdArgs defaultCmd()
  {
    f := FantomPlugin.findBuildGroup(frame.curFile)
    return CmdArgs.makeManual(["{{env_home}}/bin/fan", f.osPath], "{{project_dir}}")
  }
}


**
** run / test cmd
**
internal const class RunPodCmd : FantomCmd
{
  override const Str name
  override const ExecCmdInteractive interaction
  override const Bool persist := true
  override const |Console|? callback := null
  const Bool single
  const Bool test

  new make(Bool single, Bool test)
  {
    this.single = single
    this.test = test
    nm := test ? "Test" : "Run"
    name = single ? "$nm Single" : "$nm"
    interaction = single ? ExecCmdInteractive.always : ExecCmdInteractive.onetime
  }

  override CmdArgs defaultCmd()
  {
    f := FantomPlugin.findBuildFile(frame.curFile)
    pod := plugin.index.podForFile(f)?.name
    bn := frame.curFile.basename

    target := single ? (pod == null ? f.basename : "${pod}::$bn") : pod
    cmd := test ? "fant" : "fan"
    return CmdArgs.makeManual(["{{env_home}}/bin/$cmd", target], "{{project_dir}}")
  }
}

internal const class BuildAndRunCmd : Cmd
{
  new make(|This| f) {f(this)}
  override const Str name := "BuildAndRun"
  override Void invoke(Event event)
  {
    FantomPlugin.cur.commands.build.invoke(event)
    Desktop.callAsync |->|{
      frame.process.waitForProcess(console, 3min)
      if(console.lastResult == 0 )
        FantomPlugin.cur.commands.run.invoke(event)
    }
  }
}



