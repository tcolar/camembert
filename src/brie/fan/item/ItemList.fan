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
class ItemList : Panel, Themable
{
  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

  new make(Frame frame, Item[] items, Int width := 200)
  {
    this.frame = frame
    this.width = width
    this.items = items
    onMouseUp.add |e| { doMouseUp(e) }
    updateTheme()
    colw = font.width("m")
    update
  }

  override Void updateTheme()
  {
    t := Sys.cur.theme
    wallpaperColor = t.bg
    viewportColor = t.bg
    font = t.font
    selectedItemColor = t.selectedItem
    fontColor = t.fontColor
    colw = font.width("m")
    gutterColor = t.scrollBg
    thumbColor = t.scrollFg
    repaint
  }

  //////////////////////////////////////////////////////////////////////////
  // Config
  //////////////////////////////////////////////////////////////////////////

  Frame? frame { private set }

  Item[] items := [,] {set{&items = it; update}}

  Font? font
  Color? selectedItemColor
  Color? fontColor

  Item? highlight { set { &highlight = it; repaint } }

//////////////////////////////////////////////////////////////////////////
// Panel
//////////////////////////////////////////////////////////////////////////

  override Int lineCount() { items.size }

  override Int lineh() { itemh }

  override Int colCount := 5 { private set }

  override Int colw

  Int itemh() { font.height.max(18) }

  Int width

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
    g.font = font

    x := 0
    y := 0
    itemh := this.itemh

    Str? collapsedBase := null
    items.eachRange(lines) |item, i|
    {
      paintItem(g, item, x, y)
      y += itemh
    }
  }

  virtual Void paintItem(Graphics g, Item item, Int x, Int y)
  {
    if (item === this.highlight)
    {
      g.brush = selectedItemColor
      g.fillRect(0, y, size.w, itemh)
    }
    x += item.indent*20
    g.brush = fontColor
    if (item.icon != null) g.drawImage(item.icon, x, y)
    g.drawText(item.dis, x+20, y)
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  private Item? yToItem(Int y) { itemAtLine(yToLine(y)) }

  private Item? itemAtLine(Int line)
  {
    items.getSafe(line)
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
    if(item.file == null)
      return

    if (event.count == 1 && event.button == 1)
    {
      event.consume
      item.selected(frame)
      if(item.file.isDir && ! item.isProject)
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
          it.onAction.add |e| {collapse(item);expand(item, true)} })
        menu.add(MenuItem{it.text="Collapse"
          it.onAction.add |e| {collapse(item)} })
      }
      if (menu != null)
      {
        menu.open(event.widget, event.pos)
      }
      return
    }
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
  Void collapse(FileItem base)
  {
    base.setCollapsed(true)
    Int? start := items.eachWhile |item, index -> Int?|
    {
      return (item as FileItem).file == base.file ? index : null
    }
    start += 1
    index := start
    // hide children
    while(index < items.size)
    {
      that := items[index] as FileItem
      if( ! that.file.pathStr.startsWith(base.file.pathStr))
        break
      index++
    }

    items.removeRange(start ..< index)

    update
  }

  ** Expand a folder
  ** if recurse is true then expand any subfolder as well
  Void expand(FileItem base, Bool recurse := false)
  {
    base.setCollapsed(false)
    Int? index := items.eachWhile |item, index -> Int?|
    {
      return (item as FileItem).file == base.file ? index : null
    }
    newItems := FileItem[,]
    frame.curSpace.nav?.findItems(base.file, newItems, false,
                     (index == 0 ? "" : base.dis), recurse ? 1000 : null)
    items.insertAll(index + 1, newItems)

    update
  }

  ** Refresh an item tree, typically a directory
  ** base is the item (base of tree) being refreshed
  Void refresh(File base, FileItem[] newItems)
  {
    Int? start := items.eachWhile |item, index -> Int?|
    {
      return (item as FileItem).file.normalize == base.normalize ? index : null
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

