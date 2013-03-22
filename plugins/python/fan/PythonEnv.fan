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

  new make(|This|? f := null) : super(f)
  {
    if (f != null) f(this)
  }
}