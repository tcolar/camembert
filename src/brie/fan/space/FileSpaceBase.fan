// History:
//  Jan 30 13 tcolar Creation
//

using gfx
using fwt

**
** FileSpaceBase
**
abstract class FileSpaceBase : BaseSpace
{
  override View? view
  override Nav? nav

  new make(Frame frame, File dir)
    : super(frame, dir)
  {
    view = View.makeBest(frame, this.file)
    nav = FancyNav(frame, dir, StdItemBuilder(this), FileItem.makeFile(this.file), 0)

    viewParent.content = view
    navParent.content = nav.list
  }

  override Image icon() { Sys.cur.theme.iconDir }

  override Str:Str saveSession()
  {
    props := ["dir": dir.uri.toStr]
    return props
  }

  override Int match(FileItem item)
  {
    if (!FileUtil.contains(this.dir, item.file)) return 0
    // if project we don't want to open them here but in a proper space
    if (item.isProject) return 0
    return this.dir.path.size
  }
}