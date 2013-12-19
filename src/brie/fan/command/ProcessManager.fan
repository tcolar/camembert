// History:
//  Dec 19 13 tcolar Creation
//

using fwt
using gfx

**
** ProcessManager
**
class ProcessManager
{
  [Int:Proc] procs := [:]
  Int id := 0

  Window window

  new make()
  {
    table := Table
    {
      model = ProcTableModel(this)
    }
    window = Window
    {
      size = Size(1000,400)
      title = "Processes"
      EdgePane
      {
        top = EdgePane
        {
          it.left = Button
          {
            text = "Refresh"
            onAction.add |evt| {table.refreshAll}
          }
          it.right = Button
          {
            text = "Kill selected"
            onAction.add |evt| {
              if(table.selected.size > 0)
              {
                id := table.model.text(0, table.selected[0]).toInt
                kill(id)
                table.refreshAll
              }
            }
          }
        }
        center = table
      },
    }
  }

  ** Register a process
  ** If there is an existing process with the exact same command then we kill it first
  Int register(Process p, Str name := ""){
    procs.each |proc, id|
    {
      if(proc.p.command.toStr == p.command.toStr){
        kill(id)
      }
    }

    id++
    procs[id] = Proc(p, name)
    return id
  }

  Void unregister(Int id){
    procs.remove(id)
  }

  Void kill(Int id)
  {
    if(procs.containsKey(id))
    {
      Sys.log.info("Killing procss ${procs[id]}")
      procs[id].p.kill
      procs.remove(id)
    }
  }

  Void show()
  {
    window.open
  }
}

class ProcTableModel : TableModel{
  ProcessManager p

  override Int numCols := 4
  new make(ProcessManager p){
    this.p = p;
  }

  override Str header(Int col){
    switch(col)
    {
      case 0:
        return "Id"
      case 1:
        return "Name"
      case 2:
        return "Runtime"
      default:
        return "Command"
    }
  }

  override Str text(Int col, Int row){
    id := p.procs.keys[row]
    proc := p.procs[id]
    switch(col)
    {
      case 0:
        return "$id"
      case 1:
        return proc.name
      case 2:
        return (DateTime.now - proc.started).toSec.toStr + " sec"
      default:
        return proc.p.command.toStr
    }
  }

  override Int numRows()
  {
    return p.procs.size
  }
}

class Proc
{
  Process p
  Str name
  DateTime started

  new make(Process p, Str name)
  {
    this.p = p
    this.name = name
    this.started = DateTime.now
  }

  override Str toStr()
  {
    return "$name $p.command.toStr"
  }
}