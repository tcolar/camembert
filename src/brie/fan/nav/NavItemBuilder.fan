// History:
//  Jan 04 13 tcolar Creation
//

**
** NavItemBuilder
**
mixin NavItemBuilder
{
  abstract Item forFile(File f, Str path, Int indent)
  abstract Item forDir(File f, Str path, Int indent, Bool collapsed)
  abstract Item forProj(File f, Str path, Int indent)
}

class StdItemBuilder : NavItemBuilder
{
  override  Item forFile(File f, Str path, Int indent)
  {
    return Item(f) { it.indent = indent }
  }

  override  Item forDir(File f, Str path, Int indent, Bool collapsed)
  {
    if(collapsed)
      return Item(f){it.dis = "${path}$f.name/"; it.collapsed = true; it.indent = indent}
    else
      return Item(f) { it.dis = "${path}$f.name/"; it.indent = indent}
  }

  override  Item forProj(File f, Str path, Int indent)
  {
    return Item(f) {it.indent = indent; it.isProject = true}
  }
}