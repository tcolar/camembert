// History:
//  Dec 17 13 tcolar Creation
//

using camembert
using fwt
using gfx

**
** PhpSpace
**
class PhpSpace : FileSpaceBase
{
  override Str? plugin

  new make(Frame frame, File dir, Str plugin, Uri iconUri)
    : super(frame, dir, 220, Image(iconUri))
  {
    this.plugin = plugin
    slots := makeSlotNav()
    slotsParent.content = slots
  }

  override Int match(FileItem item)
  {
    if (!FileUtil.contains(this.dir, item.file)) return 0
    // if project we don't want to open them here but in a proper space
    if (item.isProject) return 0
    return 1000 + this.dir.path.size
  }

  static Space loadSession(Frame frame, Str:Str props)
  {
    make(frame, File(props.getOrThrow("dir").toUri), props.getOrThrow("pluginName"),
         props.getOrThrow("icon").toUri)
  }

  override Str:Str saveSession()
  {
    props := ["dir": dir.uri.toStr, "icon" : icon.file.uri.toStr,
    "pluginName" : plugin]
    return props
  }

  override Void goto(FileItem? item)
  {
    super.goto(item)
    // Update slot nav
    newSlots := makeSlotNav()
    slotsParent.content = newSlots
    slotsParent.relayout
    // needs to repaint view parent if slots pane went away or came back
    viewParent.parent.relayout
  }

  // Figure out slots of given Python file
  // Just some very basic pattern matching for the time being
  private Widget? makeSlotNav()
  {
    Sys.log.err("msn!")
    if (file.ext != "php" && file.ext != "module") return null
    items := Item[,]
    inClass := false
    inFunc := false
    brackets := 0
    file.readAllLines.each |line, index|
    {
      line = line.trim
      try
      {
        if(inClass || inFunc)
        {
          line.each{
            if(it == '{')
              brackets++
            else if(it == '}')
              brackets--
          }
          if(brackets == 0)
          {
            inClass = false
            inFunc = false
          }
        }
        if(!inClass && !inFunc && line.startsWith("class "))
        {
          // a struct type
          inClass = true
          brackets = line.contains("{") ? 1 : 0
          item := FileItem.makeFile(file)
          item.dis = line[5..-1].trim
          item.icon = Sys.cur.theme.iconType
          item.loc = ItemLoc{it.line=index}
          items.add(item)
        }
        if(line.startsWith("function ")){
          // method
          inFunc = true
          brackets = line.contains("{") ? brackets + 1 : brackets
          item := FileItem.makeFile(file)
          i := line.index("(")
          item.dis = line[9 ..< i].trim
          item.icon = Sys.cur.theme.iconMethod
          item.loc = ItemLoc{it.line=index}
          item.indent = inClass ? 1 : 0
          items.add(item)
        }
      }catch(Err e){e.trace}
    }
    return ItemList(frame, items, 175) // end of struct
  }

}