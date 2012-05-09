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
      c("b",    "Build current pod", Build#),
      c("f",    "Find in current doc", FindCmd#),
      c("fi",   "Find case insensitive in current doc", FindInsensitiveCmd#),
      c("gt",   "Goto type", GotoTypeCmd#),
      c("gf",   "Goto file", GotoFileCmd#),
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

  Void log(Str line)
  {
    app.console.log(line)
  }
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
  override Obj[] match(Str arg)
  {
    app.index.matchTypes(arg)
  }
}

class GotoFileCmd : MatchCmd
{
  override Obj[] match(Str arg)
  {
    app.index.matchFiles(arg)
  }
}

//////////////////////////////////////////////////////////////////////////
// Build
//////////////////////////////////////////////////////////////////////////

class Build : Cmd
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



