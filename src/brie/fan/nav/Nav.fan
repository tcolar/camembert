// History:
//  Jan 02 13 tcolar Creation
//

**
** Nav : Navigation support ("file / items listings")
**
abstract class Nav
{
  abstract ItemList list
  abstract File root

  Regex[] hideFiles
  Int collapseLimit // auto-collapse limit
  NavItemBuilder navBuilder

  new make(Int collapseLimit, NavItemBuilder navBuilder)
  {
    this.collapseLimit = collapseLimit
    this.navBuilder = navBuilder
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
  }

  ** Highlight a file
  Void highlight(File? file)
  {
    if(file == null) return

    Int? index := list.files.eachWhile |item, index -> Int?|
    {
      return (item as FileItem).file.normalize == file.normalize ? index : null
    }
    if(index == null) return

    list.highlight = list.items[index]

    // if not in vieport then scroll to it
    if( ! list.viewportLines.contains(index))
      list.scrollToLine(index>=5 ? index-5 : 0)

    list.repaint
  }

  ** find items
  Void findItems(File dir, Item[] results, Bool preserveLayout := false,
        Str path:="", Uri:Project projects := ProjectRegistry.projects)
  {
    dir.listFiles.sort |a, b| {a.name  <=> b.name}.each |f|
    {
      if (! hidden(f))
      {
        results.add(navBuilder.forFile(f, path, 1))
      }
    }

    dir.listDirs.sort |a, b| {a.name  <=> b.name}.each |f|
    {
      if (! hidden(f))
      {
        if(projects.containsKey(f.normalize.uri))
        {
          // Not recursing in pods or pod groups
          prj := projects[f.normalize.uri]
          item := navBuilder.forProj(f, path, 1)
          item.icon = prj.icon
          results.add(item)
        }
        else
        {
          sub := f.list.findAll{! hidden(f)}.size
          Bool? expandable := sub > collapseLimit && sub > 0
          if(preserveLayout)
          {
            // keep layout of existing item if known
            expandable = list.findForFile(f)?.collapsed ?: expandable
          }
          if(expandable)
          {
            results.add(navBuilder.forDir(f, path, 0, true))
          }
          else
          {
            results.add(navBuilder.forDir(f, path, 0, false))
            // recurse
            findItems(f, results, preserveLayout, "${path}$f.name/", projects)
          }
        }
      }
    }
  }

  private Bool hidden(File f)
  {
    hideFiles.eachWhile |Regex r -> Bool?| {
        r.matches(f.uri.toStr) ? true : null} ?: false
  }

  virtual Void refresh(File? base := root)
  {
    if( ! base.isDir)
      base = base.parent
    FileItem[] newItems := [,]
    // Refresh from the first base available in the tree
    // because we can create many dirs at once it can be some ways up
    while(base != null)
    {
      item := list.items.find{(it as FileItem).file.normalize == base.normalize}
      if (item != null)
        break
      base = base.parent
    }
    if(base != null)
    {
      findItems(base, newItems, true)
      list.refresh(base, newItems)
    }
  }
}