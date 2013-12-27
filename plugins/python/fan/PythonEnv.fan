// History:
//  Mar 21 13 tcolar Creation
//

using netColarUtils
using camembert

**
** PythonEnv
**
@Serializable
const class PythonEnv : BasicEnv
{
  @Setting{ help = ["Path to python command"] }
  const Uri pythonPath := `/usr/bin/python`

  @Setting{ help = ["Path to Python3, needed for documentation to work !"] }
  const Uri python3Path := `/usr/bin/python3`

  override Uri? envHome() {return pythonPath}

  new make(|This|? f := null) : super(f)
  {
    if (f != null) f(this)
  }
}

