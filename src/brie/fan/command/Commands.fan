//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

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
  const Cmd exit        := ExitCmd()
  const Cmd reload      := ReloadCmd()
  const Cmd save        := SaveCmd()
  const Cmd esc         := EscCmd()
  const Cmd recent      := RecentCmd()
  const Cmd prevMark    := PrevMarkCmd()
  const Cmd nextMark    := NextMarkCmd()
  const Cmd find        := FindCmd()
  const Cmd findInSpace := FindInSpaceCmd()
  const Cmd goto        := GotoCmd()
  const Cmd build       := BuildCmd()
  const Cmd editConfig  := EditConfigCmd()
  const Cmd reloadConfig:= ReloadConfigCmd()
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
  Console console() { frame.console }
  
  Command asCommand()
  {
    k := key != null ? " ($key)" : ""
    return Command("${name}$k", null, |Event e| {invoke(e)})
  }
}




internal const class EditConfigCmd : Cmd
{
  override const Str name := "Edit config"
  override Void invoke(Event event)
  {
    frame.goto(Item.makeFile(Options.file))
  }
}

internal const class ReloadConfigCmd : Cmd
{
  override const Str name := "Reload Config"
  override const Key? key := Key("Shift+Ctrl+R")
  override Void invoke(Event event)
  {
    Sys.reload
  }
}


