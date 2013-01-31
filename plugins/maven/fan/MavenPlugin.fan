// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using gfx

**
** MavenPlugin
**
const class MavenPlugin : Plugin
{
  static const Image icon := Image(`fan://camMavenPlugin/res/maven.png`)

  static const Str _name := "camMavenPlugin"

  override PluginCommands? commands() {MavenCommands()}
  override Str name() {return _name}
  override PluginDoc? docProvider() {null}

  override PluginConfig? readConfig(Sys sys)
  {
    return MavenConfig(sys)
  }

  override Void onFrameReady(Frame frame)
  {
    (frame.menuBar as MenuBar).plugins.add(MavenMenu(frame))
  }

  override const |Uri -> Project?| projectFinder:= |Uri uri -> Project?|
  {
    f := uri.toFile
    if( ! f.exists || ! f.isDir) return null
     // pom.xml
    pom := f + `pom.xml`
    if(pom.exists)
      return Project{
        it.dis = f.name // todo : should read project name that from pom
        it.dir = f.uri
        it.icon = MavenPlugin.icon
        it.plugin = name
      }
     return null
  }

  override Space createSpace(Project prj)
  {
    return MavenSpace(Sys.cur.frame, prj.dir.toFile)
  }

  override Int spacePriority(Project prj)
  {
    if(prj.plugin != name)
      return 0
    return 50
  }

  static MavenConfig config()
  {
    return (MavenConfig) PluginManager.cur.conf(_name)
  }

  static MavenPlugin cur()
  {
    return (MavenPlugin) Sys.cur.plugin(_name)
  }

  static File? findPomFile(File? dir, File? upTo)
  {
    if(dir == null || dir == upTo)
      return null
    pom :=  dir + `pom.xml`
    if(pom.exists)
      return pom

    return findPomFile(dir.parent, upTo)
  }
}