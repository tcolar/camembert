using fwt
using gfx

** Sidebar to show recent documents
class RecentPane : ContentPane
{
  Frame frame
  ItemList picker

  new make(Frame frame)
  {
    this.frame = frame
    content =  BgEdgePane
    {
      top = BgLabel
      {
        text = "Recent Items (Modif+Number)"
      }
      picker = RecentItemList(frame, frame.history.items)
      center = picker
    }
  }

  Void update(History history)
  {
    picker.items = history.items
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

class RecentItemList : ItemList
{
  new make(Frame frame, Item[] items) : super(frame, items) {}

  override Void paintItem(Graphics g, Item item, Int x, Int y)
  {
    index := y / itemh

    if(index > 0 && index < 10)
      g.drawText(index.toStr, x, y)

    x += 20
    g.brush = fontColor
    if (item.icon != null)
      g.drawImage(item.icon, x, y)

    g.drawText(item.dis, x+20, y)

    if(item.space != null)
    {
      g.brush = wallpaperColor
      g.fillRect(size.w - 110, y, size.w, y + itemh)
      g.brush = fontColor
      dis := item.space.dis
      if(dis.contains("/"))
        dis = dis.split('/').last
      g.drawText(dis, size.w - 100, y)
    }
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
    if(link.icon != null)
      item.icon = link.icon

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

