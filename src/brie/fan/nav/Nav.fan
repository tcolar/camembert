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

  ** Refresh a particular item or all if null
  virtual Void refresh(Item? item := null) {}

  Void highlight(Item? curItem)
  {
    if(curItem == null) return

    items.items.eachWhile |item, index -> Bool?|
    {
      if(item.toStr == curItem.toStr)
      {
        items.highlight = item
        items.scrollToLine(index>=5 ? index-5 : 0)
        return true
      }
      return null
    }
  }

  //TODO: expand / collapse nodes ?
  // expandall / collapseall ?
}