// History:
//  Jan 02 13 tcolar Creation
//

**
** FancyNav : Folder/file/projects navigation
**
class FancyNav : Nav
{
  override ItemList list
  override File root

  // TODO: make a setting collapseLimit
  new make(Frame frame, File dir, NavItemBuilder navBuilder,
      Item? curItem, Int collapseLimit := 30, Int listWidth:=200)
    : super(collapseLimit, navBuilder)
  {
    this.collapseLimit = collapseLimit

    root = dir
    files := [Item(dir)]
    findItems(dir, files)
    list = ItemList(frame, files, listWidth)
    highlight(curItem.file)
  }
}