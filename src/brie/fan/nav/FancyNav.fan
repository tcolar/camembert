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
  Regex[] hideFiles

  // TODO: make a setting collapseLimit
  static const Int collapseLimit := 30 // auto-collapse limit

  new make(Frame frame, File dir, Item? curItem)
  {
    Regex[] r := Regex[,]
    try
    {
      Sys.cur.options.hidePatterns.each
      {
        r.add(Regex.fromStr(it))
      }
    }
    catch(Err e)
    {
      Sys.cur.log.err("Failed to load the hidden file patterns !", e)
    }
    hideFiles = r

    root = dir
    files := [Item(dir)]
    findItems(dir, files)
    items = ItemList(frame, files)
    highlight(curItem.file)
  }

  private Void findItems(File dir, Item[] results, Bool preserveLayout := false, Str path := "")
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
          // Not recursing in pods or pod groups
          results.add(Item(f) { it.dis = "${path}$f.name/"})
        }
        else
        {
          sub := f.list.findAll{! hidden(f)}.size
          Bool? expandable := sub > collapseLimit && sub > 0
          if(preserveLayout)
          {
            // keep layout of existing item if known
            expandable = items.findForFile(f)?.collapsed ?: expandable
          }
          if(expandable)
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
            findItems(f, results, preserveLayout, "${path}$f.name/")
          }
        }
      }
    }
  }

  Bool hidden(File f)
  {
    hideFiles.eachWhile |Regex r -> Bool?| {
        r.matches(f.uri.toStr) ? true : null} ?: false
  }

  override Void refresh()
  {
    newItems := [Item(root)]
    findItems(root, newItems, true)
    items.update(newItems)
  }
}