// History:
//  Jan 04 13 tcolar Creation
//
using gfx

**
** NavItemBuilder
**
mixin NavItemBuilder
{
  abstract Item forFile(File f, Str path, Int indent)
  abstract Item forDir(File f, Str path, Int indent, Bool collapsed)
  abstract Item forProj(File f, Str path, Int indent)

  abstract Space space

  ** Root item icon
  virtual Image? icon()
  {
    space.icon
  }
}

class StdItemBuilder : NavItemBuilder
{
  override Space space

  new make(Space space)
  {
    this.space = space
  }

  override  FileItem forFile(File f, Str path, Int indent)
  {
    return FileItem.forFile(f, indent)
  }

  override  FileItem forDir(File f, Str path, Int indent, Bool collapsed)
  {
    if(collapsed)
      return FileItem.toCollapsed(FileItem.forFile(f, indent, "${path}$f.name/"), true)
    else
      return FileItem.toCollapsed(FileItem.forFile(f, indent, "${path}$f.name/"),false)
  }

  override FileItem forProj(File f, Str path, Int indent)
  {
    return FileItem.forProject(f, indent, "${path}$f.name")
  }
}