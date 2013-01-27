// History:
//  Jan 23 13 tcolar Creation
//

using netColarUtils

**
** Template for new files (Global)
**
@Serializable
const class Template
{
  //Text of the template. Following variables may be used:",
  // {date} {user} {name}
  const Str text

  // File extensions for which this template is the best match
  const Str[] extensions := [,]

  // Display sorting value if many tpl match an extension (lower = first)
  const Int order := 10

  const Str name

  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }
}