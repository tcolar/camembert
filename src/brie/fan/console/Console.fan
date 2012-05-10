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
using syntax

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
    this.bottom = app.status
    this.commands = Commands(app)
  }

  Void onReady()
  {
    prompt.field.text = ""
    prompt.field.focus
  }

  Void run(Str text)
  {
    space  := text.index(" ")
    cmdStr := space == null ? text : text[0..<space]
    argStr := space == null ? null : text[space+1..-1]

    cmd := commands.get(cmdStr, false)

    app.marks = Mark[,]
    prompt.field.text = ""
    list([,])

    if (cmd == null)
    {
      list(commands.list)
      return
    }

    cmd.run(argStr)
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
      if (!matches.isEmpty) { list(matches); return }
    }

    // show matching commands
    list(commands.list)
  }

  Void clear()
  {
    prompt.field.text = ""
    list(Obj[,])
  }

  Void list(Obj[] items)
  {
    this.app.marks = items.findType(Mark#)
    this.lister = Lister(items)
    this.lister.onKeyDown.add |e| { if (!e.consumed) app.controller.onKeyDown(e) }
    lister.onAction.add |e| { listOnAction(e) }
    this.center = lister
    relayout
  }

  Void show(Mark mark)
  {
    file := mark.res.toFile
    lines := file.readAllLines
    rules := SyntaxRules.loadForFile(file, lines.first)
    if (rules == null) rules = SyntaxRules {}
    editor := Editor { it.rules = rules; it.ro = true }
    editor.loadLines(lines)
    editor.onKeyDown.add |e| { if (!e.consumed) app.controller.onKeyDown(e) }
    Desktop.callAsync |->| { editor.goto(mark.pos, false) }

    this.center = editor
    relayout
  }

  Void showStr(Str str)
  {
    editor := Editor { it.ro = true }
    editor.load(str.in)
    editor.onKeyDown.add |e| { if (!e.consumed) app.controller.onKeyDown(e) }
    this.center = editor
    relayout
  }

  Void listOnAction(Event e)
  {
    cmdItem := e.data as CmdItem
    if (cmdItem != null)
    {
      cmdItem.cmd.onItem(cmdItem)
      return
    }

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

  Void onCurMark(Mark cur)
  {
    index := lister.items.findIndex |item| { item === cur }
    if (index == null)
      lister.highlights = Span[,]
    else
      lister.highlights = [Span(index, 0, index, 10_000)]
  }

  Void log(Str line)
  {
    lister.addItem(line)
  }

  Void kill()
  {
    proc := this.proc
    if (proc == null) return
    this.inKill = true
    log("killing...")
    proc.kill
  }

  Void exec(Str[] cmd, File dir)
  {
    this.inKill = false
    this.proc = ConsoleProcess(this)
    proc.spawn(cmd, dir)
  }

  Void execFan(Str[] args, File dir, File fanHome := Env.cur.homeDir)
  {
    fan := fanHome + (Desktop.isWindows ? `bin/fan.exe` : `bin/fan`)
    args = args.dup.insert(0, fan.osPath)
    exec(args, dir)
  }

  internal Void procDone()
  {
    if (inKill) log("killed")
    app.index.reindexPod(app.curPod)
    proc = null
    inKill = false
  }

  App app
  Prompt prompt
  Commands commands
  Lister lister
  private ConsoleProcess? proc
  private Bool inKill
}