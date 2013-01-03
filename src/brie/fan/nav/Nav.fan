// History:
//  Jan 02 13 tcolar Creation
//

**
** Nav : Navigation support ("file / items listings")
**
mixin Nav
{
  abstract ItemList items
  abstract File root

  ** Refresh the nav
  abstract Void refresh()

  ** Highlight a file
  Void highlight(File? file)
  {
    if(file == null) return

    items.items.eachWhile |item, index -> Bool?|
    {
      if(item.file == file)
      {
        items.highlight = item
        items.scrollToLine(index>=5 ? index-5 : 0)
        return true
      }
      return null
    }
  }
}