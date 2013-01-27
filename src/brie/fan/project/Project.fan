// History:
//  Jan 25 13 tcolar Creation
//

using gfx

**
** Project
**
@Serializable
const class Project
{
  // TODO: subprojects allowed / what kind ?

  FileItem item

  ** Plugin responsible for this project
  Type plugin

  Str:Str params := [:]

  new make(|This|? f) {if(f!=null) f(this)}
}