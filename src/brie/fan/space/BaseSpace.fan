// History:
//  Jan 03 13 tcolar Creation
//

using fwt

**
** BaseSpace
** Base space for file based spaces
**
abstract class BaseSpace : Space
{
  override Type? plugin := null
  override Widget ui
  override File? root() {dir}
  override Str dis
  override File? curFile() { file }

  ContentPane viewParent
  ContentPane slotsParent
  ContentPane navParent

  Frame frame
  File file
  File dir

  ** Subclass should call this and then use
  ** viewparent.content = ...
  ** navParents.content = ....
  ** and so on to set Ui parts
  new make(Frame frame, Str dis, File dir, File? file := null)
  {
    this.frame = frame
    if (!dir.exists) throw Err("Dir doesn't exist: $dir")
    if (!dir.isDir) throw Err("Not a dir: $dir")
    this.dis = dis
    this.dir  = dir.normalize
    file = file ?: dir
    this.file = file
    slotsParent = InsetPane(0, 5, 0, 0)
    viewParent = InsetPane(0, 5, 0, 0)
    navParent = InsetPane(0, 5, 0, 5)
    ui = EdgePane
    {
      left = EdgePane
      {
        left = navParent
        right = slotsParent
      }
      center = viewParent
    }
  }

  ** Go to the given item. (in Editor & Nav)
  override Void goto(FileItem? item)
  {
    // Update view (editor)
    file = item == null ? file : item.file
    newView := View.makeBest(frame, file)
    if(newView != null)
    {
      if(item != null)
        newView.onGoto(item)
      else
        newView.onGoto(Item.makeLoc(view.curPos.line, view.curPos.col, null))
      updateView(newView)
    }

    // select in nav
    nav?.highlight(item?.file)
  }

  virtual Void updateView(View newView)
  {
    viewParent.content = newView
    view = newView
    viewParent.relayout
  }
}