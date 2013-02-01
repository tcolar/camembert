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

  virtual Str[] expandDirs() {[,]}
  virtual Str[] expandDirsWith() {[,]}

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
    return FileItem.makeFile(f, indent)
  }

  override  FileItem forDir(File f, Str path, Int indent, Bool collapsed)
  {
    if(collapsed)
      return FileItem.makeFile(f, indent).setDis("${path}$f.name/").setCollapsed(true)
    else
      return FileItem.makeFile(f, indent).setDis("${path}$f.name/").setCollapsed(false)
  }

  override FileItem forProj(File f, Str path, Int indent)
  {
    return FileItem.makeProject(f, indent).setDis("$f.name")
  }
}