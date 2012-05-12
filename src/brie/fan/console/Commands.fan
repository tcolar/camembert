//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt
using bocce
using concurrent

class Commands
{
  new make(App app)
  {
    this.app = app
    this.list = [
      c("b",     "Bookmarks", BookmarkCmd#),
      c("build", "Build current pod", BuildCmd#),
      c("f",     "Find in current doc", FindCmd#),
      c("fi",    "Find case insensitive in current doc", FindInsensitiveCmd#),
      c("fp",    "Find in current pod", FindPodCmd#),
      c("gl",    "Goto line", GotoLineCmd#),
      c("gt",    "Goto type", GotoTypeCmd#),
      c("gf",    "Goto file", GotoFileCmd#),
      c("s",     "Show type/slot", ShowCmd#),
      c("ri",    "Rebuild entire index", ReindexCmd#),
      c("?",     "Help", HelpCmd#),
    ]
  }

  private Cmd c(Str name, Str summary, Type t)
  {
    Cmd cmd := t.make
    cmd.name    = name
    cmd.summary = summary
    cmd.toStr   = name.padr(5) + "  " + summary
    cmd.app     = app
    return cmd
  }

  Cmd? get(Str name, Bool checked := true)
  {
    exact := list.find |c| { c.name == name }
    if (exact != null) return exact
    x := list.findAll |c| { c.name.startsWith(name) }
    if (x.size == 1) return x.first
    if (checked) throw Err("Command not found: $name")
    return null
  }

  App app
  Cmd[] list
}

//////////////////////////////////////////////////////////////////////////
// Cmd base class
//////////////////////////////////////////////////////////////////////////

abstract class Cmd
{
  App? app
  Str name    := "?"
  Str summary := "?"
  override Str toStr := "?"

  Console console() { app.console }

  Editor? editor()
  {
    if (app.view isnot EditorView) return null
    return ((EditorView)app.view).editor
  }

  virtual Obj[] match(Str arg) { Obj#.emptyList }

  virtual Void run(Str? arg) {}

  virtual Void onItem(CmdItem itme) {}

  Void log(Str line)
  {
    app.console.log(line)
  }
}

//////////////////////////////////////////////////////////////////////////
// CmdItem
//////////////////////////////////////////////////////////////////////////

class CmdItem
{
  new make(Cmd cmd, Str dis, Obj? data) { this.cmd = cmd; this.dis = dis; this.data = data }

  Cmd cmd { private set }
  const Str dis
  const Obj? data

  override Str toStr() { dis }
}

//////////////////////////////////////////////////////////////////////////
// MatchCmd
//////////////////////////////////////////////////////////////////////////

class MatchCmd : Cmd
{
  override Void run(Str? arg)
  {
    app.console.list(match(arg ?: "no-arg"))
    app.curMark = 0
  }
}

//////////////////////////////////////////////////////////////////////////
// FindCmd / FindInsensitiveCmd
//////////////////////////////////////////////////////////////////////////

class FindCmd : MatchCmd
{
  virtual Bool matchCase() { true }
  override Obj[] match(Str arg)
  {
    res := app.res
    editor := this.editor
    marks := Mark[,]
    spans := Span[,]
    if (arg.size < 2 || editor == null) return marks
    while (marks.size < 1000)
    {
      lastMark := marks.last
      pos := editor.findNext(arg, lastMark?.pos, matchCase)
      if (pos == null) break
      line := editor.line(pos.line).trim
      spans.add(Span(pos, Pos(pos.line, pos.col+arg.size)))
      marks.add(Mark(res, pos.line, pos.col, pos.col+arg.size, line))
    }
    editor.highlights = spans
    return marks
  }
}

class FindInsensitiveCmd : FindCmd
{
  override Bool matchCase() { false }
}

//////////////////////////////////////////////////////////////////////////
// FindPod
//////////////////////////////////////////////////////////////////////////

class FindPodCmd : Cmd
{
  override Void run(Str? arg)
  {
    if (arg == null || arg.trim.isEmpty || app.curPod == null) return

    marks := Mark[,]
    app.curPod.srcFiles.each |file|
    {
      file.readAllLines.each |line, linei|
      {
        col := line.index(arg)
        if (col == null) return
        text := "$file.name(${linei+1}): $line.trim"
        marks.add(Mark(FileRes(file), linei, col, col+arg.size, text))
      }
    }
    app.console.list(marks)
  }
}

//////////////////////////////////////////////////////////////////////////
// Goto Cmds
//////////////////////////////////////////////////////////////////////////

class GotoTypeCmd : MatchCmd
{
  override Void run(Str? arg) { super.run(arg); console.clear }
  override Obj[] match(Str arg) { app.index.matchTypes(arg).map |t->Mark| { t.toMark } }
}

class GotoFileCmd : MatchCmd
{
  override Void run(Str? arg) { super.run(arg); console.clear }
  override Obj[] match(Str arg) { app.index.matchFiles(arg) }
}

class GotoLineCmd : MatchCmd
{
  override Void run(Str? arg)
  {
    mark := toMark(arg)
    if (mark != null) app.goto(mark)
    console.clear
  }

  override Obj[] match(Str arg)
  {
    mark := toMark(arg)
    if (mark == null) return [,]
    lines := Obj[,]
    s := (mark.line - 5).max(0)
    e := (mark.line + 5).min(editor.lineCount)

    for (i := s; i<e; ++i)
      lines.add(i == mark.line ? mark : editor.line(i))

    highlight := mark.line - s
    Desktop.callAsync |->|
    {
      console.lister.highlights = [Span(highlight, 0, highlight, 10_000)]
    }

    return lines
  }

  private Mark? toMark(Str? arg)
  {
    if (editor == null) return null
    line := ((arg ?: "1").toInt(10, false) ?: 1) - 1
    if (line < 0) line = 0
    if (line >= editor.lineCount) line = editor.lineCount-1
    text := editor.line(line)
    if (text.isEmpty) text = " "
    return Mark(app.res, line, 0, 0, text)
  }
}

//////////////////////////////////////////////////////////////////////////
// ShowCmd
//////////////////////////////////////////////////////////////////////////

class ShowCmd : MatchCmd
{
  override Obj[] match(Str arg)
  {
    app.index.matchTypes(arg).map |t->CmdItem| { CmdItem(this, t.qname, t) }
  }

  override Void run(Str? arg)
  {
    t := app.index.matchTypes(arg ?: "no-arg").first
    if (t == null) { console.log("No types found: $arg"); return }
    console.show(t.toMark)
  }

  override Void onItem(CmdItem item)
  {
    TypeInfo t := item.data
    console.show(t.toMark)
  }
}

//////////////////////////////////////////////////////////////////////////
// BookmarkCmd
//////////////////////////////////////////////////////////////////////////

class BookmarkCmd : MatchCmd
{
  override Void run(Str? arg)
  {
    console.list(Bookmark.load)
    console.lister.focus
  }
}

//////////////////////////////////////////////////////////////////////////
// BuildCmd
//////////////////////////////////////////////////////////////////////////

class BuildCmd : Cmd
{
  override Void run(Str? arg)
  {
    f := findBuildFile()
    console.execFan([f.osPath], f.parent)
  }

  File? findBuildFile()
  {
    // get the current resource as a file, if this file is
    // the build.fan file itself, then we're done
    f := app.res.toFile(false)
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

//////////////////////////////////////////////////////////////////////////
// ReindexCmd
//////////////////////////////////////////////////////////////////////////

class ReindexCmd : Cmd
{
  override Void run(Str? arg) { app.index.reindexAll }
}

//////////////////////////////////////////////////////////////////////////
// KillTest
//////////////////////////////////////////////////////////////////////////

/*
class KillTest : Cmd
{
  override Void run(Str? arg)
  {
    console.execFan(["brie::KillTest"], Env.cur.workDir)
  }

  static Void main()
  {
    while (true) { echo("Looping $Time.now "); Actor.sleep(3sec) }
  }
}
*/


//////////////////////////////////////////////////////////////////////////
// HelpCmd
//////////////////////////////////////////////////////////////////////////

class HelpCmd : Cmd
{
  override Void run(Str? arg)
  {
    s := StrBuf().add(
     """Esc         Focus console
        F1          Focus editor and clear console
        Ctrl+Space  Focus nav history
        Ctrl+1      Focus nav level-1
        Ctrl+2      Focus nav level-2
        Ctrl+3      Focus nav level-3
        F9          Build
        F8          Next mark
        Shift+F8    Prev mark
        Ctrl+C      Copy
        Ctrl+D      Delete cur line
        Ctrl+K      Kill console process
        Ctrl+R      Reload
        Ctrl+S      Save
        Ctrl+V      Paste
        Ctrl+X      Cut
        """)

    s.add("\n")
    console.commands.list.each |c| { s.add(c.name.padr(11) + " " + c.summary + "\n") }
    console.showStr(s.toStr)
  }
}



