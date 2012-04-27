//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt
using compiler
using bocce

**
** Console
**
class Console : EdgePane
{

  new make(App app)
  {
    this.app = app
    this.prompt = Prompt(app, this)
    this.lister = Lister([,])
    this.top = prompt
    this.center = lister
    this.commands = Commands(app)
  }

  Void ready()
  {
    prompt.field.text = ""
    prompt.field.focus
  }

  Void typing(Str text)
  {
    // reset marks
    app.marks = Mark[,]

    // find all matching commands
    space  := text.index(" ")
    cmdStr := space == null ? text : text[0..<space]
    argStr := space == null ? null : text[space+1..-1]
    cmds   := commands.list.findAll |c| { c.name.startsWith(cmdStr) }

    // find exact matching commands
    cmd := commands.list.find |c| { c.name == cmdStr }
    if (cmd == null && cmds.size == 1) cmd = cmds.first

    // if typing "cmd arg" show matching arguments
    if (cmd != null && argStr != null)
    {
      matches := cmd.match(argStr)
      if (!matches.isEmpty)
      {
        marks := matches.findType(Mark#)
        if (!marks.isEmpty) app.marks = marks
        list(matches)
        return
      }
    }

    // show matching commands
    if (cmds.isEmpty)
      list(["No matching commands"])
    else
      list(cmds)
  }

  Void list(Obj[] items)
  {
    this.lister = Lister(items)
    lister.onAction.add |e| { listOnAction(e) }
    this.center = lister
    relayout
  }

  Void listOnAction(Event e)
  {
    mark := e.data as Mark
    if (mark != null)
    {
      markIndex := app.marks.findIndex |m| { m === mark }
      if (markIndex != null)
        app.curMark = markIndex
      else
        app.goto(mark)
      return
    }
  }

  Void onCurMark(Int curMark)
  {
    lister.highlights = [Span(curMark, 0, curMark, 10_000)]
  }

  App app
  Prompt prompt
  Commands commands
  Lister lister
}


