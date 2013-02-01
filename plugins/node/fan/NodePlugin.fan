// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using gfx
using xml

**
** NodePlugin
**
const class NodePlugin : BasicPlugin
{
  override const Image icon := Image(`fan://camNodePlugin/res/node.png`)

  override const Str name := "camNodePlugin"

  override Uri? defaultEnvHome() {`/usr/local/`}

  override PluginCommands? commands() {NodeCommands(this)}

  override Bool isProject(File dir)
  {
    if(dir.path.contains("node_modules"))
      return false
    return (dir + `package.json`).exists
  }

  //TODO: override Str prjName(File prjDir)
}