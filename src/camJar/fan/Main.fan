// History:
//  Jan 01 14 tcolar Creation
//

using netColarJar

**
** Install & Run Camembert, first updating it using Fanr if not up to date
**
class Main : FantomRunner
{
  Uri repo := `http://repo.status302.com/fanr/`
  Uri swtBase := `http://colar.net/swt`
  // Note: All deps get pulled automatically.
  Str[] pods := ["camembertIde"]

  ** Run the app (install as needed first)
  override Void run()
  {
    installPods

    if( ! installSwt)
      return // just installed swt, needs a restart

    // Ok, run Camembert now
    try
      Pod.find("camembertIde").type("Main").make()->main
    catch(Err e) {e.trace}
  }

  ** Install pods if missing
  Void installPods()
  {
    pod := Pod.find("camembertIde", false)
    if(pod == null)
    {
      try
        fetchFanr(repo, pods)
      catch(Err e)
        e.trace
    }
    else
    {
      echo("Found $pod.name at version $pod.version")
      echo("  Note: Remove $pod.uri to force updating.")
    }
  }

  ** Install SWT lib if missing
  ** Return if it was already installed
  Bool installSwt()
  {
    platform := Env.cur.platform
    swt := FANTOM_HOME + `lib/java/ext/${platform}/swt.jar`
    if(! swt.exists)
    {
      fetchHttp(`${swtBase}/${platform}/swt.jar`, swt)
      echo("Installed ${swt.osPath}")
      echo("\n!! RESTART REQUIRED !!")
      return false
    }
    return true
  }
}