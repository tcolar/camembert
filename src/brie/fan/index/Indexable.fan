// History:
//  Jan 08 13 tcolar Creation
//

**
** Indexable
** Support for indexing vy a plugin
**
mixin Indexable
{
  ** Crawl the source dirs looking for projects directories
  ** The indexer cache will cache this and only call agin upon request
  FileItem[] projects(File[] srcDirs)
  {
  }
}