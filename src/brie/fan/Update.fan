// History:
//  Feb 27 14 tcolar Creation
//

using netColarJar

**
** Update
**
class Update : FantomRunner
{
  Uri repo := `http://repo.status302.com/fanr/`
  Uri swtBase := `http://colar.net/swt`
  // Note: All deps get pulled automatically.
  Str[] pods := ["camembertIde"]

  override Void run()
  {
    try
      fetchFanr(repo, pods)
    catch(Err e)
      e.trace
  }
}