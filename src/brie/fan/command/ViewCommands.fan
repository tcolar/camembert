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

internal const class SwitchTheme : Cmd
{
  const File file

  new make(File file) {this.file = file}
  override const Str name := "Switch theme"
  override Void invoke(Event event)
  {
    Sys.cur._theme.val = Theme.load(file)
    updateTheme(frame)
    frame.spaces.each
    {
      it.refresh // force reload the views
      updateTheme(it.ui) // update the itemlists (navs)
    }
  }

  ** Recursively apply new theme to all the frame components
  Void updateTheme(Widget w)
  {
    if(w is Themable)
    {
      (w as Themable).updateTheme
    }
    // recurse
    w.children.each {updateTheme(it)}
  }
}

