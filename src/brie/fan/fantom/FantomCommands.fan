// History:
//  Jan 25 13 tcolar Creation
//

using fwt

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
        FantomPlugin.config.selectEnv(name)
        plugin := Sys.cur.plugin(FantomPlugin#)
        // TODO: we need to reload the fantom index etc ...
      }
    }
  }

  new make(Str envName)
  {
    this.name = envName
  }
}


