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
    actor.send(ConsoleMsg("spawn", cmd, dir))
  }

  Console console()
  {
    Actor.locals["console"] ?: throw Err("Missing 'console' actor locale")
  }

  Void done()
  {
    echo("DONE!")
  }

  Void writeLines(Str[] lines)
  {
    lines.each |line| { console.lister.addItem(line) }
  }

  private Obj? receive(ConsoleMsg msg)
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
      proc.out = ConsoleOutStream(this)
      proc.run.join
    }
    catch (Err e)
    {
      e.trace
    }
    finally
    {
      Desktop.callAsync |->| { done }
    }
    return null
  }

  private const Actor actor
}

**************************************************************************
** ConsoleMsg
**************************************************************************

internal const class ConsoleMsg
{
  new make(Str id, Obj? a := null, Obj? b := null)
  {
    this.id = id
    this.a  = a
    this.b  = b
  }
  const Str id
  const Obj? a
  const Obj? b
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

