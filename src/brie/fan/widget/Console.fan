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
using syntax
using concurrent

**
** Console
**
class Console : InsetPane
{
  ConsoleCmd? lastCmd

  Menu menu := Menu
  {
    MenuItem
    {
      it.text = "Clear console"
      it.onAction.add |Event e| {clear}
    },
    MenuItem
    {
      it.text = "Copy all text"
      it.onAction.add |Event e| {copyText}
    },
  }

  new make(Frame frame) : super(3, 5, 0, 5)
  {
    this.frame = frame
    this.list = ItemList(frame, Item[,])
    this.content = BgEdgePane{
      left = GridPane{
        Button
        {
          image = Image(`fan://icons/x16/refresh.png`)
          onAction.add {redo}
        },
        Button
        {
          it.image = Image(`fan://icons/x16/close.png`)
          it.onAction.add |evt| {Sys.cur.commands.processWindow.invoke(evt)}
        },
        Button
        {
          image = Image(`fan://icons/x16/file.png`)
          onAction.add {clear}
        },
      }
      center = this.list
    }
    this.visible = false
    list.onMouseDown.add |Event event|
    {
      if(event.button == 3)
       menu.open(event.widget, event.pos)
    }
  }

  Bool isBusy() { proc != null }

  Bool isOpen := false { private set }

  Void toggle() { if (isOpen) close; else open }

  Void open()
  {
    isOpen = true
    visible = true
    frame.updateStatus
    parent.relayout
  }

  Void show(Item[] marks)
  {
    frame.marks = marks
    list.items = marks
    open
  }

  Void append(Item[] marks)
  {
    marks.each {list.addItem(it)}
    list.scrollToLine(list.lineCount)
    open
  }

  Void close()
  {
    isOpen = false
    visible = false
    frame.updateStatus
    parent.relayout
  }

  Void highlight(Item? item) { list.highlight = item }

  Void log(Str line)
  {
    list.addItem(Item(line))
  }

  Void clear()
  {
    frame.marks = [,]
    list.items = frame.marks
  }

  ** Copy all the text from the console to the clipboard
  Void copyText()
  {
    text := ""
    list.items.each {text += "${it.dis}\n"}
    Desktop.clipboard.setText(text)
  }

  /*** kill and wait for kill to be complete
  ** Return wether kill succeeded
  Bool killAndWait()
  {
    if(proc == null)
      return true

    kill
    start := DateTime.now
    while(proc != null)
    {
      if(DateTime.now - start > 10sec)
        break
      Actor.sleep(100ms)
    }
    if(proc != null)
    {
      append([Item.makeStr("Oooops ... could not terminate the process !")
              .setIcon(Sys.cur.theme.iconErr)])
      return false
    }
    return true
  }

  Void kill()
  {
    if (proc == null)
      return
    this.inKill = true
    log("Stopping.")
    proc.kill
  }*/

  Void redo()
  {
    if(lastCmd != null)
    {
      exec(lastCmd)
    }
  }

  Void exec(ConsoleCmd cmd)
  {
    lastCmd = cmd

    open

    frame.marks = Item[,]
    this.inKill = false
    this.proc = ConsoleProcess(this, cmd.itemFinder)
    this.onDone = cmd.onDone
    log("Running: $cmd.args in $cmd.dir.osPath")
    proc.spawn(cmd.args, cmd.dir)
  }

  internal Void procDone(Int result)
  {
    // ** WARNING: using **Any** fwt/console access methods here can cause lockups
    // Even if using Deskop.callAsync
    lastResult = result
    proc = null
    if (onDone != null)
    {
      try
        onDone(this)
      catch (Err e){}
    }
    inKill = false
    onDone = null
    Sys.log.info("Process completed")
  }

  Frame frame { private set }
  ItemList list { private set}
  Int lastResult := 0
  private ConsoleProcess? proc
  private Bool inKill
  private |Console|? onDone
}

const class ConsoleCmd
{
  const Str[] args

  const File dir

  ** Will be called back when done
  const |Console|? onDone := null

  ** Create fileItem for given error lines (ie: errors)
  const |Str -> Item?|? itemFinder := null

  new make(|This|? f) {f(this)}
}

**************************************************************************
** ConsoleProcess
**************************************************************************

internal const class ConsoleProcess
{
  const |Str -> Item?|? itemFinder := null

  new make(Console console, |Str -> Item?|? itemFinder := null)
  {
    Actor.locals["console"] = console
    actor = Actor(ActorPool()) |msg| { receive(msg) }
    this.itemFinder = itemFinder
  }

  Void spawn(Str[] cmd, File dir)
  {
    actor.send(Msg("spawn", cmd, dir, Unsafe(console)))
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
    frame := console.frame
    lines.each |line|
    {
      try
      {
        item := itemFinder?.call(line) ?: Item(line)
        console.list.addItem(item)
        if ((item is FileItem))
          frame.marks = frame.marks.dup.add(item)
      }
      catch (Err e)
      {
        console.list.addItem(Item(line))
        e.trace
      }
    }
    console.list.scrollToLine(console.list.lineCount)
  }

  private Obj? receive(Msg msg)
  {
    if (msg.id == "spawn") return doSpawn(msg.a, msg.b, msg.c)
      Sys.log.info("WARNING: unknown msg: $msg")
    throw Err("unknown msg $msg")
  }

  private Obj? doSpawn(Str[] cmd, File dir, Unsafe c)
  {
    Int result := -1
    try
    {
      if( Desktop.isWindows && ! cmd.isEmpty && ! cmd[0].endsWith(".exe"))
        cmd = [cmd[0] + ".exe"].addAll(cmd[1 .. -1])
      proc := Process(cmd, dir)
      procRef.val = Unsafe(proc)
      proc.out = ConsoleOutStream(this)
      cons := c.val as Console
      id := Sys.cur.processManager.register(proc)
      try
        result = proc.run.join
      finally
        Sys.cur.processManager.unregister(id)
    }
    catch (Err e)
    {
      e.trace
      cons := c.val as Console
      cons.log(e.traceToStr)
      return null
    }
    finally
    {
      cons := c.val as Console
      cons.procDone(result)
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
    proc := this.proc
    curStr = curStr + str
    lines := curStr.splitLines
    if (lines.size <= 1) return
      Desktop.callAsync |->| { proc.writeLines(lines[0..-2]) }
    curStr = lines.last
  }

  Str curStr := ""
}


