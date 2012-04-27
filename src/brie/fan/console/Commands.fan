//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt

class Commands
{
  new make(App app)
  {
    this.app = app
    this.list = [
      c("f",    "Find in current doc", FindCmd#),
      c("fi",   "Find case insensitive in current doc", FindInsensitiveCmd#),
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

  Doc? doc()
  {
    if (app.view isnot EditorView) return null
    return ((EditorView)app.view).editor.doc
  }

  virtual Obj[] match(Str arg) { Obj#.emptyList }

//  abstract Void invoke()
}

//////////////////////////////////////////////////////////////////////////
// FindCmd
//////////////////////////////////////////////////////////////////////////

class FindCmd : Cmd
{
  virtual Bool matchCase() { true }
  override Obj[] match(Str arg)
  {
    doc := this.doc
    matches := Mark[,]
    if (arg.size < 2 || doc == null) return matches
    while (matches.size < 1000)
    {
      mark := doc.findNext(arg, matches.last, matchCase)
      if (mark == null) break
      matches.add(mark)
    }
    return matches
  }
}

class FindInsensitiveCmd : FindCmd
{
  override Bool matchCase() { false }
}



