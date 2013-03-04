// History:
//  Feb 27 13 tcolar Creation
//

using netColarUtils
using camembert

**
** PythonOptions
**
@Serializable
const class PythonOptions : BasicOptions
{
  @Setting { help = ["Path to the pydoc command. Used to display the Python documentation."] }
  const Str pyDocPath := "/usr/bin/pydoc"

  ** Default constructor with it-block
  new make(|This|? f := null) : super(f)
  {
  }
}