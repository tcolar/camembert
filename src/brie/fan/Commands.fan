//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using concurrent

**
** Application level commands
**
const class Commands
{
  new make(Sys sys)
  {
    this.sys = sys
    list := Cmd[,]
    typeof.fields.each |field|
    {
      if (field.type != Cmd#) return
      Cmd cmd := field.get(this)
      list.add(cmd)
      cmd.sysRef.val = sys
    }
    this.list = list
  }

  Cmd? findByKey(Key key) { list.find |cmd| { cmd.key == key } }

  const Sys sys
  const Cmd[] list
  const Cmd exit := ExitCmd()
  const Cmd save := SaveCmd()
}

**************************************************************************
** Cmd
**************************************************************************

const abstract class Cmd
{
  abstract Str name()

  abstract Void invoke(Event event)

  virtual Key? key() { null }

  Sys sys() { sysRef.val }
  internal const AtomicRef sysRef := AtomicRef(null)

  Options options() { sys.options }
  Frame frame() { sys.frame }
}

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
** SaveCmd
**************************************************************************

internal const class SaveCmd : Cmd
{
  override const Str name := "Save"
  override const Key? key := Key("Ctrl+S")
  override Void invoke(Event event) { frame.save }
}



