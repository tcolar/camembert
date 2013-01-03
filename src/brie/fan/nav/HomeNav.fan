// History:
//  Jan 02 13 tcolar Creation
//

**
** HomeNav : Nav for projects list
**
class HomeNav : Nav
{
  override ItemList items
  override File root

  new make(Frame frame, File dir, Item? curItem)
  {
    root = dir
    files := [Item(dir)]
    //findItems(dir, files)
    items = ItemList(frame, files)
    highlight(curItem)
  }

  override Void refresh() {}
}