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
      c("b",    "Build current pod", BuildCmd#),
      c("f",    "Find in current doc", FindCmd#),
      c("fi",   "Find case insensitive in current doc", FindInsensitiveCmd#),
      c("gt",   "Goto type", GotoTypeCmd#),
      c("gf",   "Goto file", GotoFileCmd#),
      c("s",    "Show type/slot", ShowCmd#),
      c("?",    "Help", HelpCmd#),
    ]
  }

  private Cmd c(Str name, Str summary, Type t)
  {
    Cmd cmd := t.make
    cmd.name    = name
    cmd.summary = summary
    cmd.toStr   = name.padr(4) + "  " + summary
    cmd.app     = app
    return cmd
  }

  Cmd? get(Str name, Bool checked := true)
  {
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
// FindCmd
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
     """Esc       Focus console
        F1        Focus editor
        Ctrl+1    Focus nav level-1
        Ctrl+2    Focus nav level-2
        Ctrl+3    Focus nav level-3
        F9        Build
        F8        Next mark
        Shift+F8  Prev mark
        Ctrl+C    Copy
        Ctrl+K    Kill
        Ctrl+R    Reload
        Ctrl+S    Save
        Ctrl+V    Paste
        Ctrl+X    Cut
        """)

    s.add("\n")
    console.commands.list.each |c| { s.add(c.name.padr(9) + " " + c.summary + "\n") }
    console.showStr(s.toStr)
  }
}



