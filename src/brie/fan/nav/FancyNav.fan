// History:
//  Jan 02 13 tcolar Creation
//

**
** FancyNav : Folder/file/projects navigation
**
class FancyNav : Nav
{
  override ItemList items
  override File root

  static const Int limit := 999 // TODO: later, not sure I like it

  new make(Frame frame, File dir, Item? curItem)
  {
    root = dir
    files := [Item(dir)]
    findItems(dir, files)
    items = ItemList(frame, files)
    highlight(curItem)
  }

  private Void findItems(File dir, Item[] results, Str path := "")
  {
    dir.listFiles.sort |a, b| {a.name  <=> b.name}.each |f|
    {
      if (! hidden(f))
      {
        results.add(Item(f) { it.indent = path.isEmpty ? 0 : 1 })
      }
    }

    dir.listDirs.sort |a, b| {a.name  <=> b.name}.each |f|
    {
      if (! hidden(f))
      {
        // TODO: make this generic : isProjectDir() for any plugin
        if(Sys.cur.index.isPodDir(f)!=null || Sys.cur.index.isGroupDir(f) != null)
        {
          results.add(Item(f) { it.dis = "${path}$f.name/"})
          // Not recursing in pods or pod groups
        }
        else
        {
          sub := f.list.findAll{! hidden(f)}.size
          if(sub > limit && sub > 0)
          {
            results.add(Item(f)
            {
              it.dis = "${path}$f.name/"
              it.collapsed = true
            })
          }
          else
          {
            results.add(Item(f) { it.dis = "${path}$f.name/"})
            // recurse
            findItems(f, results, "${path}$f.name/")
          }
        }
      }
    }
  }

  Bool hidden(File f)
  {
    /*hideFiles.eachWhile |Regex r -> Bool?| {
        r.matches(f.uri.toStr) ? true : null} ?: */false
  }
}