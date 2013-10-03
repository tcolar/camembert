// History:
//  Oct 02 13 tcolar Creation
//

using netColarUtils
using camembert

**
** RubyEnv
**
@Serializable
const class GoEnv : BasicEnv
{
  @Setting{ help = ["Go project workspace (where source projects are)"] }
  const Uri goPath := `/home/go/`

  new make(|This|? f := null) : super(f)
  {
    if (f != null) f(this)
  }
}

