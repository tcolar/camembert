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
      FileItem? curItem, Int collapseLimit := 50, Str? dis := null, Int listWidth:=200)
    : super(collapseLimit, navBuilder)
  {
    this.collapseLimit = collapseLimit

    root = dir
    files := [FileItem.makeProject(dir, 0).setIcon(navBuilder.icon)]
    if(dis!=null)
      files[0].setDis(dis)
    findItems(dir, files)
    list = ItemList(frame, files, listWidth)
    highlight(curItem.file)
  }
}