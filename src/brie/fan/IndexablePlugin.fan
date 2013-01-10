// History:
//  Jan 08 13 tcolar Creation
//

**
** Plugin that support indexing / index queries
**
mixin Indexable : Plugin
{
  ** Called to start the index
  virtual Void startIndex() {}


  //virtual Void refreshIndex()

  ** Return Goto matches for given text
  virtual FileItem[] findGotos(Str text, Space? space := null, File? file := null)
  {
    return [,]
  }

  ** Return known slots for given file or null if slots panel should not be shown
  virtual FileItem[]? findSlots(File file) {return null}
}