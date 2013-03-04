// History:
//  Feb 27 13 tcolar Creation
//

using netColarUtils
using camembert

**
** RubyEnv
**
@Serializable
const class RubyEnv : BasicEnv
{
  @Setting{ help = ["Path to ruby command"] }
  const Uri rubyPath := `/usr/bin/ruby`

  @Setting{ help = ["Path to ri command (documentation tool)"] }
  const Uri riPath := `/usr/local/bin/ri`

  new make(|This|? f := null) : super(f)
  {
    if (f != null) f(this)
  }
}