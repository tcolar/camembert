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

  new make(Frame frame, File dir, Int navWidth := 250)
    : super(frame, dir)
  {
    view = View.makeBest(frame, this.file)
    nav = FancyNav(frame, dir, StdItemBuilder(this), FileItem.makeFile(this.file)
                  , 0, null, navWidth)

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

  ** Default impl, is to look by file name
  ** Could be slow in giant file trees (100k files +)
  override Item[] findGotoMatches(Str text)
  {
    if(text.isEmpty)
      return [,]
    excludes := ["class", "pyc", "jar"]
    return fileMatches(text, excludes).map|f -> Item|
    {
      path := f.parent.normalize.uri.relTo(dir.normalize.uri).toStr
      return FileItem.makeFile(f).setDis("$f.name | $path")
    }
  }

  ** find files with matching names
  ** if exts is not null only matches files with NOT matching extension
  File[] fileMatches(Str text, Str[]? exts := null, Bool excludeDirs := true)
  {
    text = text.lower
    File[] files := [,]
    dir.walk|f|
    {
      if(excludeDirs && f.isDir)
        return
      if(exts != null && exts.find{it.lower == f.ext?.lower} != null)
        return
      if(f.basename.lower.startsWith(text))
        files.add(f)
    }
    return files
  }
}