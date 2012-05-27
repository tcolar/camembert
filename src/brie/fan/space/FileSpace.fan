//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt

**
** File system space
**
@Serializable
const class FileSpace : Space
{
  new make(Sys sys, File dir, Str dis:= FileUtil.pathDis(dir), Uri path := ``)
    : super(sys)
  {
    if (!dir.exists) throw Err("Dir doesn't exist: $dir")
    if (!dir.isDir) throw Err("Not a dir: $dir")
    this.dir = dir.normalize
    this.dis = dis
    this.path = path
  }

  const File dir

  const Uri path

  override const Str dis

  override Image icon() { Theme.iconDir }

  override Str:Str saveSession()
  {
    props := ["dir": dir.uri.toStr, "dis":dis]
    if (!path.path.isEmpty) props["path"] = path.toStr
    return props
  }

  static Space loadSession(Sys sys, Str:Str props)
  {
    make(sys,
         File(props.getOrThrow("dir").toUri, false),
         props.getOrThrow("dis"),
         props.get("path", "").toUri)
  }

  override Int match(Item item)
  {
    if (!FileUtil.contains(this.dir, item.file)) return 0
    if (item.pod != null) return 0
    return this.dir.path.size
  }

  override This goto(Item item)
  {
    make(sys, dir, dis, FileUtil.pathIn(dir, item.file))
  }

  override Widget onLoad(Frame frame)
  {
    // build path bar
    pathBar := GridPane
    {
      numCols = path.path.size + 1
    }
    x := this.dir
    pathBar.add(makePathButton(frame, x))
    path.path.each |name|
    {
      x = File(x.uri.plusName(name), false)
      pathBar.add(makePathButton(frame, x))
    }

    // build dir listing
    lastDir := x.isDir ? x : x.parent
    lister := ItemList(frame, Item.makeFiles(lastDir.list))

    // if path is file, make view for it
    Widget? view := null
    if (!x.isDir) view = View.makeBest(frame, x)

    return EdgePane
    {
      top = InsetPane(0, 4, 6, 2) { pathBar, }
      left = ScrollPane { lister, }
      center = view
    }
  }

  private Button makePathButton(Frame frame, File file)
  {
    dis := file === this.dir ? FileUtil.pathDis(file) : file.name
    return Button
    {
      text  = dis
      image = Theme.fileToIcon(file)
      onAction.add |e| { frame.goto(Item(file)) }
    }
  }

}

