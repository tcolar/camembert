// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using gfx

**
** MavenSpace
**
class MavenSpace : FileSpace
{
  override Str? plugin := MavenPlugin._name

  new make(Frame frame, File dir)
    : super(frame, dir)
  {
  }

  override Image icon() { MavenPlugin.icon }

  override Int match(FileItem item)
  {
    if (!FileUtil.contains(this.dir, item.file)) return 0
    // if project we don't want to open them here but in a proper space
    if (item.isProject) return 0
    return 1000 + this.dir.path.size
  }
}

