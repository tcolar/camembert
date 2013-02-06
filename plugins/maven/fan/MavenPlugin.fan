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
  const PluginCommands cmds

  override const Image icon := Image(`fan://camMavenPlugin/res/maven.png`)
  override const Str name := _name
  override Uri? defaultEnvHome() {`/usr/share/maven/`}
  override PluginCommands? commands() {cmds}

  override Bool isProject(File dir)
  {
    return dir.isDir && (dir + `pom.xml`).exists
  }

  new make()
  {
    cmds = MavenCommands(this)
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

internal const class MavenCommands : PluginCommands
{
  override const Cmd build
  override const Cmd run
  override const Cmd runSingle
  override const Cmd test
  override const Cmd testSingle
  override const Cmd buildAndRun

  new make(MavenPlugin plugin)
  {
    mvn := "{{env_home}}/bin/mvn"
    build       = BasicPluginCmd(plugin, "Build", [mvn, "compile"],
                                 ExecCmdInteractive.onetime, mavenFinder)
    run         = BasicPluginCmd(plugin, "Run", [mvn, "exec:exec"],
                                 ExecCmdInteractive.onetime, mavenFinder)
    runSingle   = BasicPluginCmd(plugin, "RunSingle", [mvn, "exec:exec"],
                                 ExecCmdInteractive.always, mavenFinder)
    test        = BasicPluginCmd(plugin, "Test", [mvn, "test"],
                                 ExecCmdInteractive.onetime, mavenFinder)
    testSingle  = BasicPluginCmd(plugin, "TestSingle", [mvn, "test"],
                                 ExecCmdInteractive.always, mavenFinder)
    buildAndRun = BasicBuildAndRunCmd(plugin)
    // TODO: look in projReg for a parent project as defined in the xml and build that ?
    //override const Cmd? buildGroup:= MavenCmd("BuildGroup", "compile", false)
  }

  //maven :  [ERROR] /home/tcolar/DEV/fantom_dev/perso/algo/src/test/java/ArrayTest.java:[38,14] error: '.class' expected
  static const |Str -> Item?| mavenFinder := |Str str -> Item?|
  {
    if(str.size < 4) return null
    str = str.trim
    if( ! str.startsWith("[ERROR]") ) return null
    p1 := str.index(":[", 7); if (p1 == null) return null
    c  := str.index(",", p1 + 1); if (c == null) return null
    p2 := str.index("]", p1); if (p2 == null) return null
    if(p1 > c || c > p2) return null
    file := File.os(str[7..<p1].trim)
    if(! file.exists) return null
    line := str[p1+2..<c].toInt(10, false) ?: 1
    col  := str[c+1..<p2].toInt(10, false) ?: 1
    text := file.name + str[p1 .. -1]
    return FileItem.makeFile(file).setDis(text).setLoc(
          ItemLoc{it.line = line-1; it.col  = col-1}).setIcon(
          Sys.cur.theme.iconErr)
  }
}

