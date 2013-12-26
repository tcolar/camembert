// History:
//  Oct 02 13 tcolar Creation
//

using camembert
using fwt
using gfx

**
** GoSpace
**
class GoSpace : FileSpaceBase
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
    slotsUpdated(newSlots == null || newSlots.items.isEmpty)
  }

  // Figure out slots of given Go file
  // At this point not using Reflexion, but basic parsing
  // Which is not too bad since Go grammar is kept fairly simple
  // The parsing is quite lame an inperfect but good enough for this purpose
  private ItemList? makeSlotNav()
  {
    if (file.ext != "go") return null
    items := Item[,]
    inStruct := false
    inFunc := false
    brackets := 0
    file.readAllLines.each |line, index|
    {
      line = line.trim
      try
      {
        if(inStruct || inFunc)
        {
          line.each{
            if(it == '{')
              brackets++
            else if(it == '}')
              brackets--
          }
          if(brackets == 0)
          {
            inStruct = false
            inFunc = false
          }
        }
        else
        {
          if(line.startsWith("type") && line.contains("struct"))
          {
            // a struct type
            inStruct = true
            brackets = 1
            item := FileItem.makeFile(file)
            item.dis = line[4..<line.index("struct")].trim
            item.icon = Sys.cur.theme.iconType
            item.loc = ItemLoc{it.line=index}
            items.add(item)
          }
          else if(line.startsWith("type ")){
            // A type that is not a struct
            item := FileItem.makeFile(file)
            item.dis = line[5..<line.index(" ", 5)].trim
            item.icon = Sys.cur.theme.iconType
            item.loc = ItemLoc{it.line=index}
            items.add(item)
          }
          else if(line.startsWith("var ")){
            // "global" var
            item := FileItem.makeFile(file)
            item.dis = line[4..<line.index(" ", 4)].trim
            item.icon = Sys.cur.theme.iconField
            item.loc = ItemLoc{it.line=index}
            items.add(item)
          }
          else if(line.startsWith("func(") || line.startsWith("func (")){
            // method
            inFunc = true
            brackets = 1
            item := FileItem.makeFile(file)
            i := line.index(")", line.index("(")) + 1
            item.dis = line[i ..< line.index("(", i)].trim
            item.icon = Sys.cur.theme.iconMethod
            item.loc = ItemLoc{it.line=index}
            item.indent = 1
            items.add(item)
          }
          else if(line.startsWith("func ")){
            // method
            inFunc = true
            brackets = 1
            item := FileItem.makeFile(file)
            item.dis = line[5..<line.index("(", 5)].trim
            item.icon = Sys.cur.theme.iconMethod
            item.loc = ItemLoc{it.line=index}
            item.indent = 0
            items.add(item)
          }
        }
        // Not doing structure vars for now ... might get too busy
      }catch(Err e){e.trace}
    }
    return ItemList(frame, items, 175) // end of struct
  }

}