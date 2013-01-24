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
  Void findItems(File dir, Item[] results, Bool preserveLayout := false, Str path:="")
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
        // TODO: also those might not be ready before indexer is done -> cache that ?
        // TODO: make this generic : isProjectDir() for any plugin
        if(Sys.cur.index.isPodDir(f)!=null || Sys.cur.index.isGroupDir(f) != null)
        {
          // Not recursing in pods or pod groups
          results.add(navBuilder.forProj(f, path, 0))
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
            findItems(f, results, preserveLayout, "${path}$f.name/")
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

  virtual Void refresh(File base := root)
  {
    if( ! base.isDir)
      base = base.parent
    FileItem[] newItems := [,]
    findItems(base, newItems, true)
    list.refresh(base, newItems)
  }
}