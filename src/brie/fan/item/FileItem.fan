// History:
//  Jan 08 13 tcolar Creation
//
using fwt

**
** FileItem
**
@Serializable
class FileItem : Item
{
  const File file

  Bool isProject := false
  Str? sortStr
  Bool collapsed := false

  new makeFile(File? f, Int indent := 0) : super.makeStr(f.name + (f.isDir ? "/" : ""))
  {
    this.indent = indent
    this.file = f
    this.icon = Theme.fileToIcon(f)
  }

  new makeProject(File f, Int indent := 0, Str? sortPath := null) : super.makeStr(f.name)
  {
    this.indent = indent
    this.file = f
    this.icon = Theme.fileToIcon(f)
    this.isProject = true
    this.sortStr = sortPath ?: f.name.lower
  }

  This setCollapsed(Bool val)
  {
    icon = val ? Sys.cur.theme.iconFolderClosed : Sys.cur.theme.iconFolderOpen
    collapsed = val
    return this
  }

  This setProject(Bool val) {isProject = val; return this}

  This setSortStr(Str sortStr) {this.sortStr = sortStr; return this}

  ** Called when this item is left clicked
  override Void selected(Frame frame)
  {
    if(isProject || ! file.isDir)
      frame.goto(this)
  }

  ** call when item is right clicked
  override Menu? popup(Frame frame)
  {
    if (isProject) return null
    // File menus
    return Menu
    {
      MenuItem
      {
        it.text = "Find in \"$file.name\""
        it.onAction.add |e|
          { (Sys.cur.commands.find as FindCmd).find(file) }
      },
      MenuItem
      {
        dir := file.isDir ? file : file.parent
        it.text = "New file in \"$dir.name\""
        it.onAction.add |e|
          { (Sys.cur.commands.newFile as NewFileCmd).newFile(dir, "NewFile.fan", frame) }
      },
      MenuItem
      {
        it.text = "Delete \"$file.name\""
        it.onAction.add |e|
        {
          (Sys.cur.commands.delete as DeleteFileCmd).delFile(file, frame)
          frame.goto(this) // refresh
        }
      },
      MenuItem
      {
        it.text = "Rename/Move \"$file.name\""
        it.onAction.add |e|
        {
          (Sys.cur.commands.move as MoveFileCmd).moveFile(file, frame)
          frame.goto(this) // refresh
        }
      },
    }
  }
}

