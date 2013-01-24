//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 May 12  Brian Frank  Creation
//

using gfx
using fwt
using concurrent
using petanque

**
** ItemList
**
class ItemList : Panel
{
  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

  new make(Frame frame, Item[] items, Int width := 200)
  {
    this.frame = frame
    this.width = width
    this.items = items
    update
    onMouseUp.add |e| { doMouseUp(e) }
  }

  //////////////////////////////////////////////////////////////////////////
  // Config
  //////////////////////////////////////////////////////////////////////////

  Frame? frame { private set }

  Item[] items := [,] {set{&items = it; update}}

  Font font := Sys.cur.theme.font

  Item? highlight { set { &highlight = it; repaint } }

//////////////////////////////////////////////////////////////////////////
// Panel
//////////////////////////////////////////////////////////////////////////

  override Int lineCount() { visibleItems.size }

  override Int lineh() { itemh }

  override Int colCount := 5 { private set }

  override const Int colw := font.width("m")

  private Int itemh() { font.height.max(18) }

  private Int width

//////////////////////////////////////////////////////////////////////////
// Items
//////////////////////////////////////////////////////////////////////////

  Void addItem(Item item)
  {
    items.add(item)
    update()
  }

  private Void update()
  {
    max := 5
    items.each |x| { max = x.dis.size.max(max) }
    this.colCount = max + 2 // leave 2 for icon
    relayout
    repaint
  }

  Void clear() { items = Item[,] }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    Size(width ,200)
  }

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////
  override Void onPaintLines(Graphics g, Range lines)
  {
    x := 0
    y := 0
    itemh := this.itemh

    Str? collapsedBase := null
    visibleItems.eachRange(lines) |item, i|
    {
      paintItem(g, item, x, y)
      y += itemh
    }
  }

  private Void paintItem(Graphics g, Item item, Int x, Int y)
  {
    if (item === this.highlight)
    {
      g.brush = Sys.cur.theme.selectedItem
      g.fillRect(0, y, size.w, itemh)
    }
    x += item.indent*20
    g.brush = Sys.cur.theme.fontColor
    if (item.icon != null) g.drawImage(item.icon, x, y)
    g.drawText(item.dis, x+20, y)
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  private Item? yToItem(Int y) { itemAtLine(yToLine(y)) }

  private Item? itemAtLine(Int line)
  {
    visibleItems.getSafe(line)
  }

  private Void doMouseUp(Event event)
  {
    obj := itemAtLine(yToLine(event.pos.y))
    if(obj==null ||  ! (obj is FileItem))
    {
      event.consume
      return
    }

    item := obj as FileItem

    if (event.count == 1 && event.button == 1)
    {
      event.consume
      item.selected(frame)
      if(item.file.isDir)
      {
        toggleCollapse(item)
      }
      return
    }

    if (event.id === EventId.mouseUp && event.button == 3 && event.count == 1)
    {
      event.consume
      menu := item.popup(frame)

      if(item.file.isDir)
      {
        if(menu == null)
          menu = Menu()
        else
          menu.addSep

        menu.add(MenuItem{it.text="Refresh tree"
          it.onAction.add |e| {frame.curSpace.nav?.refresh(item.file)} })
          menu.add(MenuItem{it.text="Expand tree"
            it.onAction.add |e| {expand(item, true)} })
      }
      if (menu != null)
      {
        menu.open(event.widget, event.pos)
      }
      return
    }
  }

  private Item[] visibleItems()
  {
    items.findAll { ! it.hidden }
  }

  ** Toggle collapse / expand an item (1 level)
  Void toggleCollapse(FileItem item)
  {
    if(item.collapsed)
      expand(item)
    else
      collapse(item)
  }

  ** Collapse a folder and all subfolders
  Void collapse(FileItem item)
  {
    item.setCollapsed(true)
    index := items.indexSame(item) + 1
    // hide children
    while(index < items.size)
    {
      that := items[index] as FileItem
      if(that.file.pathStr.startsWith(item.file.pathStr))
        that.hidden = true
      else
        break // we are out of the parents path
      index++
    }

    update
  }

  ** Expand a folder
  ** if recurse is true then expand any subfolder as well
  Void expand(FileItem item, Bool recurse := false)
  {
    item.setCollapsed(false)
    index := items.indexSame(item) + 1
    // hide children
    while(index < items.size)
    {
      that := items[index] as FileItem
      if(! recurse && that.file.path.size > item.file.path.size + 1)
      {  //  skipping subfolder items
        index++;
        continue
      }
      if(that.file.pathStr.startsWith(item.file.pathStr))
      {
        that.hidden = false
        if(that.file.isDir)
          that.setCollapsed(that.isProject || ! recurse)
      }
      else
        break // we are out of the parents path
      index++
    }

    update
  }

  ** Refresh an item tree, typically a directory
  ** base is the item (base of tree) being refreshed
  Void refresh(File base, FileItem[] newItems)
  {
    Int? start := items.eachWhile |item, index -> Int?|
    {
      return (item as FileItem).file == base ? index : null
    }

    if(start == null)
      return

    // drop the current subtree
    start += 1
    removeEnd := start
    pathStr := base.pathStr
    while(removeEnd < items.size)
    {
      that := items[removeEnd] as FileItem
      if(that.file.pathStr.startsWith(pathStr))
        removeEnd++
      else
        break // out of the subtree
    }

    items = items[0 ..< start].addAll(newItems).addAll(items[removeEnd .. -1])

    update
  }

  FileItem? findForFile(File f)
  {
    return files.find {it.file.normalize == f.normalize}
  }

  FileItem[] files()
  {
    return (FileItem[]) items.findAll{it is FileItem}
  }
}

