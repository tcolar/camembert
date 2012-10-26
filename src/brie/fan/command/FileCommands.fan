using fwt

**************************************************************************
** ExitCmd
**************************************************************************

internal const class ExitCmd : Cmd
{
  override const Str name := "Exit"

  override Void invoke(Event event)
  {
    r := Dialog.openQuestion(frame, "Exit application?", null, Dialog.okCancel)
    if (r != Dialog.ok) return
      frame.saveSession
    Env.cur.exit(0)
  }
}
**************************************************************************
** ReloadCmd
**************************************************************************

internal const class ReloadCmd : Cmd
{
  override const Str name := "Reload"
  override const Key? key := Key("Ctrl+R")
  override Void invoke(Event event) { frame.reload }
}

**************************************************************************
** SaveCmd
**************************************************************************

internal const class SaveCmd : Cmd
{
  override const Str name := "Save"
  override const Key? key := Key("Ctrl+S")
  override Void invoke(Event event) { frame.save }
}

