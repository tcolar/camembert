// History:
//  Jan 29 13 tcolar Creation
//

//////////////////////////////////////////////////////////////////////////
// Process commands -> delegated to plugins
//////////////////////////////////////////////////////////////////////////

using fwt

internal abstract const class PluginCmd : Cmd
{
  PluginCommands? commands()
  {
    name := frame.curSpace.plugin
    if(name == null) return null // TODO: dialog ?

    plugin := Sys.cur.plugin(name)
    return plugin.commands
  }
}

internal const class BuildCmd : PluginCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Build"
  override Void invoke(Event event)
  {
    commands?.build?.invoke(event)
  }
}

internal const class BuildGroupCmd : PluginCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Build Group"
  override Void invoke(Event event)
  {
    commands?.buildGroup?.invoke(event)
  }
}


**
** Command to run a pod
**
internal const class RunCmd : PluginCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Run"
  override Void invoke(Event event)
  {
    commands?.run?.invoke(event)
  }
}

internal const class BuildAndRunCmd : PluginCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "BuildAndRun"
  override Void invoke(Event event)
  {
    commands?.buildAndRun?.invoke(event)
  }
}

**
** Command to run a single item
**
internal const class RunSingleCmd : PluginCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Run Single"
  override Void invoke(Event event)
  {
    commands?.runSingle?.invoke(event)
  }
}

**
** Command to test a single item
**
internal const class TestCmd : PluginCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Test"
  override Void invoke(Event event)
  {
    commands?.test?.invoke(event)
  }
}


**
** Command to test a single item
**
internal const class TestSingleCmd : PluginCmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Test Single"
  override Void invoke(Event event)
  {
    commands?.testSingle?.invoke(event)
  }
}



