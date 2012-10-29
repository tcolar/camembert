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
    exit        = ExitCmd{}
    reload      = ReloadCmd{key = Key(sys.shortcuts.reloadFile)}
    save        = SaveCmd{key = Key(sys.shortcuts.saveFile)}
    esc         = EscCmd{key = Key(sys.shortcuts.escape)}
    recent      = RecentCmd{key = Key(sys.shortcuts.recent)}
    prevMark    = PrevMarkCmd{key = Key(sys.shortcuts.prevMark)}
    nextMark    = NextMarkCmd{key = Key(sys.shortcuts.nextMark)}
    find        = FindCmd{key = Key(sys.shortcuts.find)}
    findInSpace = FindInSpaceCmd{key = Key(sys.shortcuts.findInSpace)}
    goto        = GotoCmd{key = Key(sys.shortcuts.goto)}
    build       = BuildCmd{key = Key(sys.shortcuts.build)}
    editConfig  = EditConfigCmd{}
    reloadConfig= ReloadConfigCmd{}
    run         = RunCmd{key = Key(sys.shortcuts.run)}
    buildAndRun = BuildAndRunCmd{key = Key(sys.shortcuts.buildAndRun)}
    terminate   = TerminateCmd{}
    searchDocs  = HelpCmd{key = Key(sys.shortcuts.searchDocs)}

    list := Cmd[,]
    typeof.fields.each |field|
    {
      if ( ! field.type.fits(Cmd#)) return
        Cmd cmd := field.get(this)
      list.add(cmd)
      cmd.sysRef.val = sys
    }
    this.list = list
  }

  Cmd? findByKey(Key key) { list.find |cmd| { cmd.key == key } }

  const Sys sys
  const Cmd[] list
  const Cmd exit
  const Cmd reload
  const Cmd save
  const Cmd esc
  const Cmd recent
  const Cmd prevMark
  const Cmd nextMark
  const Cmd find
  const Cmd findInSpace
  const Cmd goto
  const Cmd build
  const Cmd editConfig
  const Cmd reloadConfig
  const Cmd run
  const Cmd buildAndRun
  const Cmd terminate
  const Cmd searchDocs
}

**************************************************************************
** Cmd
**************************************************************************

const abstract class Cmd
{
  abstract Str name()

  abstract Void invoke(Event event)
  const Key? key

  internal const AtomicRef sysRef := AtomicRef(null)
  Sys sys() {sysRef.val }

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
  new make(|This| f) {f(this)}
}

internal const class ReloadConfigCmd : Cmd
{
  override const Str name := "Reload Config"
  override Void invoke(Event event)
  {
    Sys.reload
  }
  new make(|This| f) {f(this)}
}

internal const class HelpCmd : Cmd
{
  override const Str name := "Search Docs"
  override Void invoke(Event event)
  {
    selection := frame.curView?.curSelection ?: ""
    frame.helpPane.showSearch(selection)
  }
  new make(|This| f) {f(this)}
}