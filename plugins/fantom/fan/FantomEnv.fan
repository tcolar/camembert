// History:
//  Jan 24 13 tcolar Creation
//

using netColarUtils
using camembert

**
** FantomEnvs
**
@Serializable
const class FantomEnv : BasicEnv
{
  @Setting{ help = ["Fantom ditro root directory [fan_home], will be use for fan commands"] }
  const Uri fantomHome := Env.cur.homeDir.uri

  @Setting{ help = ["Pod directories to crawl. Typically [fantomHome]/lib/fan/"] }
  const Uri[] podDirs := [Env.cur.homeDir.uri+`lib/fan`]

  override Uri? envHome() {return fantomHome}

  new make(|This|? f := null) : super(f)
  {
    if (f != null) f(this)
  }
}