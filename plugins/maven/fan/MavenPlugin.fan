// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using gfx
using xml

**
** MavenPlugin
**
const class MavenPlugin : BasicPlugin
{
  static const Str _name := "Maven"

  override const Image icon := Image(`fan://camMavenPlugin/res/maven.png`)

  override const Str name := _name

  override Uri? defaultEnvHome() {`/usr/share/maven/`}

  override PluginCommands? commands() {MavenCommands(this)}

  override Bool isProject(File dir)
  {
    return (dir + `pom.xml`).exists
  }

  ** Read project name from pom
  override Str prjName(File prjDir)
  {
    pom := prjDir + `pom.xml`
    Str? name
    try
    {
      root := XParser(pom.in).parseDoc.root
      artifact := root.elem("artifactId").text
      if(artifact.toStr.startsWith("\${"))
      {
        // If a property, try to see if it's declared locally
        artifact = root.elem("properties").elem(artifact.toStr[2 .. -2]).text
      }
      name = artifact.toStr
    }
    catch(Err e){}
    return name ?: pom.parent.name // failsafe
  }
}