using fwt

internal const class ToggleHelpCmd : Cmd
{
  override const Str name := "Toggle Doc Pane"
  override Void invoke(Event event)
  {
    frame.helpPane.toggle
  }
  new make(|This| f) {f(this)}
}

internal const class ToggleRecentCmd : Cmd
{
  override const Str name := "Toggle Recent Pane"
  override Void invoke(Event event)
  {
    frame.recentPane.toggle
  }
  new make(|This| f) {f(this)}
}

internal const class ToggleConsoleCmd : Cmd
{
  new make(|This| f) {f(this)}
  override const Str name := "Toggle Console Pane"
  override Void invoke(Event event)
  {
    frame.console.toggle
  }
}


