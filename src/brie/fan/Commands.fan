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
  const Cmd goto     := GotoCmd()
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
** GotoCmd
**************************************************************************

internal const class GotoCmd : Cmd
{
  override const Str name := "Goto"
  override const Key? key := Key("Ctrl+G")
  override Void invoke(Event event)
  {
    // prompt field
    font :=  Desktop.sysFontMonospace
    prompt := Text
    {
      it.font = font
    }

    // table of matches
    matches := GotoMatchModel { itemFont = font; width = 500 }
    table := Table
    {
      it.headerVisible = false
      it.model = matches
    }

    // build dialog
    Item? selected
    ok := Dialog.ok
    cancel := Dialog.cancel
    dialog := Dialog(frame)
    {
      title = "Goto"
      commands = [ok, cancel]
      body = EdgePane
      {
        top = InsetPane(0, 0, 10, 0) { prompt, }
        bottom = ConstraintPane
        {
          minw = maxw = matches.width+10
          minh = maxh = 500
          table,
        }
      }
    }
    prompt.onAction.add |e| { dialog.close(ok) }
    prompt.onKeyDown.add |e|
    {
      if (e.key == Key.down) { e.consume; table.focus; return }
    }
    prompt.onModify.add |e|
    {
      matches.items = findMatches(prompt.text.trim)
      table.refreshAll
    }
    table
    {
      onAction.add |e|
      {
        selected = matches.items.getSafe(table.selected.first ?: -1)
        dialog.close(ok)
      }
    }


    // open dialog
    if (dialog.open != Dialog.ok) return

    // if we got actual selection from table use that
    // otherwise assume top match from table
    if (selected == null) selected = matches.items.first
    if (selected == null) return
    frame.goto(selected)
  }

  private Item[] findMatches(Str text)
  {
    acc := Item[,]

    // integers are always line numbers
    line := text.toInt(10, false)
    file := frame.curFile
    if (line != null && file != null)
      return [Item { it.dis= "Line $line"; it.file = file; it.line = line-1 }]

    /// slots in current type
    curType := frame.curSpace.curType
    if (curType != null)
    {
      curType.slots.each |s|
      {
        if (s.name.startsWith(text)) acc.add(Item(s) { dis = s.name })
      }
    }

    // match types
    if (!text.isEmpty)
      acc.addAll(sys.index.matchTypes(text).map |t->Item| { Item(t) })

    // f <file>
    if (text.startsWith("f ") && text.size >= 3)
      acc.addAll(sys.index.matchFiles(text[2..-1]))

    return acc
  }
}

internal class GotoMatchModel : TableModel
{
  Font? itemFont
  Int width
  Item[] items := Item[,]

  override Int numRows() { items.size }
  override Int numCols() { 1 }
  override Str header(Int col) { "" }
  override Str text(Int col, Int row) { items[row].dis }
  override Image? image(Int col, Int row) { items[row].icon }
  override Font? font(Int col, Int row) { itemFont }
  override Int? prefWidth(Int col) { width }
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

