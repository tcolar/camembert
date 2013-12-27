// History:
//  Oct 02 13 tcolar Creation
//

using netColarUtils
using camembert

**
** GoEnv
**
@Serializable
const class GoEnv : BasicEnv
{
  @Setting{ help = ["Go project workspace (where source projects are)"] }
  const Uri goPath := `/home/go/`

  @Setting{ help = ["Whether to run gofmt upon saving a .go file."] }
  const Bool goFmtOnSave := true

  @Setting{ help = ["GoFmt options"] }
  const Str[] goFmtOpts := ["-w", "{{file}}"]

  override Uri? envHome() {return goPath}

  new make(|This|? f := null) : super(f)
  {
    if (f != null) f(this)
  }
}

