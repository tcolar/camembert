//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 May 12  Brian Frank  Creation
//

using fwt
using concurrent

**
** ConsoleProcess
**
internal const class ConsoleProcess
{
  new make(Console console)
  {
    Actor.locals["console"] = console
    actor = Actor(ActorPool()) |msg| { receive(msg) }
  }

  Void spawn(Str[] cmd, File dir)
  {
    actor.send(Msg("spawn", cmd, dir))
  }

  Console console()
  {
    Actor.locals["console"] ?: throw Err("Missing 'console' actor locale")
  }

  Void kill()
  {
    proc := (Process)((Unsafe)procRef.val).val
    proc.kill
  }

  Void writeLines(Str[] lines)
  {
    app := console.app
    lines.each |line|
    {
      try
      {
        item := parseLine(line)
        console.lister.addItem(item)
        if (item is Mark)
          app.marks = app.marks.dup.add(item)
      }
      catch (Err e)
      {
        console.lister.addItem(line)
        e.trace
      }
    }
  }

  private Obj parseLine(Str str)
  {
    // Fantom "file(line,col): msg"
    // Javac  "file:col: msg"
    if (str.size > 4)
    {
      mark := parseFan(str);  if (mark != null) return mark
      mark  = parseJava(str); if (mark != null) return mark
    }
    return str
  }

  private Mark? parseFan(Str str)
  {
    p1 := str.index("(", 4); if (p1 == null) return null
    c  := str.index(",", p1); if (c == null) return null
    p2 := str.index(")", p1); if (p2 == null) return null
    file := File.os(str[0..<p1])
    line := str[p1+1..<c].toInt(10, false) ?: 1
    col  := str[c+1..<p2].toInt(10, false) ?: 1
    text := file.name + str[p1..-1]
    return Mark(FileRes(file), line-1, col-1, col-1, text)
  }

  private Mark? parseJava(Str str)
  {
    c1 := str.index(":", 4); if (c1 == null) return null
    c2 := str.index(":", c1+1); if (c2 == null) return null
    file := File.os(str[0..<c1])
    if (!file.exists) return null
    line := str[c1+1..<c2].toInt(10, false) ?: 1
    text := file.name + str[c1..-1]
    return Mark(FileRes(file), line-1, 0, 0, text)
  }

  private Obj? receive(Msg msg)
  {
    if (msg.id == "spawn") return doSpawn(msg.a, msg.b)
    echo("WARNING: unknown msg: $msg")
    throw Err("unknown msg $msg")
  }

  private Obj? doSpawn(Str[] cmd, File dir)
  {
    try
    {
      proc := Process(cmd, dir)
      procRef.val = Unsafe(proc)
      proc.out = ConsoleOutStream(this)
      proc.run.join
    }
    catch (Err e)
    {
      e.trace
    }
    finally
    {
      Desktop.callAsync |->| { console.procDone }
    }
    return null
  }

  private const Actor actor
  private const AtomicRef procRef := AtomicRef(null)
}

**************************************************************************
** ConsoleOutStream
**************************************************************************

internal class ConsoleOutStream : OutStream
{
  new make(ConsoleProcess proc) : super(null) { this.proc = proc }

  const ConsoleProcess proc

  override This write(Int b)
  {
    append(Buf().write(b).flip.readAllStr)
    return this
  }

  override This writeBuf(Buf b, Int n := b.remaining)
  {
    append(Buf().writeBuf(b, n).flip.readAllStr)
    return this
  }

  Void append(Str str)
  {
    curStr = curStr + str
    proc := this.proc
    lines := curStr.splitLines
    if (lines.size <= 1) return
    Desktop.callAsync |->| { proc.writeLines(lines[0..-2]) }
    curStr = lines.last
  }

  Str curStr := ""
}

