// History:
//  Jan 24 13 tcolar Creation
//

using netColarUtils

**
** FantomEnvs
**
@Serializable
const class FantomEnv
{
  @Setting{ help = "Display Name for this env (You may create multiple env_*.props files)" }
  const Str name := "default"

  @Setting{ help = ["Fantom ditro root directory [fan_home], will be use for fan commands"] }
  private const Uri fantomHome := Env.cur.homeDir.uri

  @Setting{ help = ["Pod directories to crawl. Typically [fantomHome]/lib/fan/"] }
  const Uri[] podDirs := [Env.cur.homeDir.uri+`lib/fan`]

  @Setting{ help ="Sort ordering of this env. Lower shows first."}
  const Int order := 10

  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }
}