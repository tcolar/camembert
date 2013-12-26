// History:
//  Jan 03 13 tcolar Creation
//

using fwt
using gfx

**
** BaseSpace
** Base space for file based spaces
**
abstract class BaseSpace : Space
{
  override Str? plugin := null
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
  new make(Frame frame, File dir, File? file := null)
  {
    this.frame = frame
    if (!dir.exists) throw Err("Dir doesn't exist: $dir")
    if (!dir.isDir) throw Err("Not a dir: $dir")
    this.dis = ProjectRegistry.projects[dir.normalize.uri]?.dis ?: FileUtil.pathDis(dir)
    this.dir  = dir.normalize
    file = file ?: dir
    this.file = file
    slotsParent = InsetPane(0, 1, 0, 0)
    viewParent = InsetPane(0, 1, 0, 1)
    navParent = InsetPane(0, 1, 0, 1)

    ui = SashPane
    {
      orientation = Orientation.horizontal
      weights = [20, 80]
      SashPane
      {
        orientation = Orientation.vertical
        weights = [100, 0]
        navParent,
        slotsParent,
      },
      viewParent,
    }
  }

  // To be called by implementation when slot nav is updated
  Void slotsUpdated(Bool isEmpty)
  {
    sash := slotsParent.parent as SashPane
    // show the slot nav only if any items in it
    if(sash != null && ! isEmpty)
      sash.weights = [50,50]
    else
      sash.weights = [100,0]
    slotsParent.relayout
    viewParent.parent.relayout
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