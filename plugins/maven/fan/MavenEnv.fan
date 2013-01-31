// History:
//  Jan 30 13 tcolar Creation
//

using netColarUtils

**
** MavenEnv
**
@Serializable
const class MavenEnv
{
  @Setting{ help = ["Display Name for this env (You may create multiple env_*.props files)"] }
  const Str name := "default"

  @Setting{ help = ["Maven home"] }
  const Uri mavenHome := `/usr/share/maven/`

  @Setting{ help = ["Sort ordering of this env. Lower shows first."]}
  const Int order := 10

  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }
}