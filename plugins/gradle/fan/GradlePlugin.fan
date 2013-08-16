// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using gfx
using xml

**
** GradlePlugin
**
const class GradlePlugin : BasicPlugin
{
  static const Str _name := "Gradle"
  const PluginCommands cmds

  override const Image icon := Image(`fan://camGradlePlugin/res/gradle.png`)
  override const Str name := _name
  override Uri? defaultEnvHome() {`/usr/`}
  override PluginCommands? commands() {cmds}

  override Bool isProject(File dir)
  {
    if(isCustomPrj(dir, "Gradle")) return true
    return dir.isDir && (dir + `build.gradle`).exists
  }

  new make()
  {
    cmds = GradleCommands(this)
  }

  ** Read project name from pom
  override Str prjName(File prjDir)
  {
    build := prjDir + `build.gradle`
    // TODO: Can that be  read in Gradle file ?
    return build.parent.name
  }
}

internal const class GradleCommands : PluginCommands
{
  override const Cmd build
  override const Cmd run
  //override const Cmd runSingle
  override const Cmd test
  //override const Cmd testSingle
  override const Cmd buildAndRun

  new make(GradlePlugin plugin)
  {
    gradle := "{{env_home}}/bin/gradle"
    build       = BasicPluginCmd(plugin, "Build", [gradle, "build"],
                                 ExecCmdInteractive.onetime, gradleFinder)
    run         = BasicPluginCmd(plugin, "Run", [gradle, "run"],
                                 ExecCmdInteractive.onetime, gradleFinder)
    test        = BasicPluginCmd(plugin, "Test", [gradle, "test"],
                                 ExecCmdInteractive.onetime, gradleFinder)
    buildAndRun = BasicBuildAndRunCmd(plugin)
  }

  //maven :  [ERROR] /home/tcolar/DEV/fantom_dev/perso/algo/src/test/java/ArrayTest.java:[38,14] error: '.class' expected
  static const |Str -> Item?| gradleFinder := |Str str -> Item?|
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

