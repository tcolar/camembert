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
  const Cmd exit     := ExitCmd()
  const Cmd save     := SaveCmd()
  const Cmd prevMark := PrevMarkCmd()
  const Cmd nextMark := NextMarkCmd()
  const Cmd build    := BuildCmd()
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

**************************************************************************
** Prev/Next Mark
**************************************************************************

internal const class PrevMarkCmd : Cmd
{
  override const Str name := "Prev Mark"
  override const Key? key := Key("Shift+F8")
  override Void invoke(Event event) { frame.curMark-- }
}

internal const class NextMarkCmd : Cmd
{
  override const Str name := "Next Mark"
  override const Key? key := Key("F8")
  override Void invoke(Event event) { frame.curMark++ }
}

**************************************************************************
** BuildCmd
**************************************************************************

internal const class BuildCmd : Cmd
{
  override const Str name := "Build"
  override const Key? key := Key("F9")
  override Void invoke(Event event)
  {
    f := findBuildFile
    if (f == null)
    {
      Dialog.openErr(frame, "No build.fan file found")
      return
    }

    console.execFan([f.osPath], f.parent)
  }

  File? findBuildFile()
  {
    // save current file
    frame.save

    // get the current resource as a file, if this file is
    // the build.fan file itself, then we're done
    f := frame.curFile
    if (f == null) return null
    if (f.name == "build.fan") return f

    // lookup up directory tree until we find "build.fan"
    if (!f.isDir) f = f.parent
    while (f.path.size > 0)
    {
      buildFile := f + `build.fan`
      if (buildFile.exists) return buildFile
      f = f.parent
    }
    return null
  }
}


