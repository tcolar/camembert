using fwt
using gfx

** Sidebar to show recent documents
class RecentPane : ContentPane
{
  Frame frame
  RecentPicker picker

  new make(Frame frame)
  {
    this.frame = frame
    content =  BgEdgePane
    {
        top = BgLabel
        {
          text = "Recent Items (Modif+Number)"
        }
        picker = RecentPicker(frame.history.items) |item, e|
        {
          frame.goto(item)
        }
        center = picker
    }
  }

  Void update(History history)
  {
    (picker.mdl as RecentPickerModel).update(history)
    picker.refresh
  }

  Void hide()
  {
    this.visible = false
    parent.relayout
    if( ! frame.helpPane.visible)
    {
      parent.visible = false
      parent.parent.relayout
    }
  }

  Void show()
  {
    this.visible = true
    parent.relayout
    if(parent.visible == false)
    {
      parent.visible = true
      parent.parent.relayout
    }
  }

  Void toggle()
  {
    if (this.visible)
      hide
    else
      show
  }
}

class RecentPicker : BgEdgePane
{
  Table table
  RecentPickerModel mdl
  new make(Item[] items, |Item, Event| onAction) : super()
  {
    mdl = RecentPickerModel(items)
    table = Table
    {
      it.headerVisible = false
      it.model = mdl
      it.onSelect.add |Event e|
      {
        onAction(mdl.items[e.index], e)
      }
      /*it.onKeyDown.add |Event e|
      {
        code := e.keyChar
        if (code >= 97 && code <= 122) code -= 32
        code -= 65
        if (code >= 0 && code < 26 && code < mdl.numRows)
          onAction(mdl.items[code], e)
        if(e.key==Key.enter && table.selected.size>0)
          onAction(mdl.items[table.selected[0]], e)
      }*/
    }
    center = table
  }

  Void refresh()
  {
    table.refreshAll
  }
}

class RecentPickerModel : TableModel
{
  new make(Item[] items)
  {
    this.items = items
  }

  override Int numCols() { return 3 }
  override Int numRows() { return items.size }
  override Int? prefWidth(Int col)
  {
    switch (col)
    {
      case 0: return 25
      case 1: return 200
      default: return null
    }
  }
  override Image? image(Int col, Int row) { col==1 ? (items[row].icon ?: def) : null}
  override Font? font(Int col, Int row) { Sys.cur.theme.font }
  override Color? fg(Int col, Int row)  { Sys.cur.theme.fontColor }
  override Color? bg(Int col, Int row)  { Sys.cur.theme.bg }
  override Str text(Int col, Int row)
  {
    switch (col)
    {
      case 0:  return row >= 1 && row <= 9 ? row.toStr : ""
      case 1:  return items[row].dis
      case 2:  return items[row].space?.dis ?: ""
      default: return ""
    }
  }
  Item[] items
  Image def := Sys.cur.theme.iconFile
  Font accFont := Sys.cur.theme.font.toSize(Sys.cur.theme.font.size - 1)
  Color accColor := Color("#666")

  Void update(History history)
  {
    items = history.items
  }
}

class History
{
  |History|[] pushListeners := [,]

  **
  ** Log navigation to the specified resource
  ** into the history.  Return this.
  **
  This push(Space space, FileItem link)
  {
    if(link.file.isDir) return this

    // create history item
    item := FileItem.makeFile(link.file).setSpace(space)

    // remove any item that matches file (regardless of space)
    dup := items.findAll{it is FileItem}.findIndex |x|
    {
      //item.space.typeof == x.space.typeof &&
      item.file.normalize == (x as FileItem).file.normalize
    }
    if (dup != null) items.removeAt(dup)

    // keep size below max
    while (items.size >= max) items.removeAt(-1)

    // push into most recent position
    items.insert(0, item)

    pushListeners.each {it.call(this)}
    return this
  }

  **
  ** The first item is the most recent navigation and the last
  ** item is the oldest navigation.
  **
  FileItem[] items := [,] { private set }

  private Int max := 40
}

