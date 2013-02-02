// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using fwt

**
** MavenCommands
**
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
    build       = MavenCmd(plugin, "Build", "compile", false)
    run         = MavenCmd(plugin, "Run", "exec:exec", false)
    runSingle   = MavenCmd(plugin, "RunSingle", "exec:exec", true)
    test        = MavenCmd(plugin, "Test", "test", false)
    testSingle  = MavenCmd(plugin, "TestSingle", "test", true)
    buildAndRun = BasicBuildAndRunCmd(plugin)
  }

  // TODO: look in projReg for a parent project as defined in the xml and build that ?
  //override const Cmd? buildGroup:= MavenCmd("BuildGroup", "compile", false)
}

internal const class MavenCmd : BasicPluginCmd
{
  override const Str name
  override const ExecCmdInteractive interaction
  override const Bool persist := true
  const Str mavenCmd
  override const |Str -> Item?|? itemFinder := |Str str -> Item?|
  {
    return mavenFinder(str) ?: ConsoleFinders.javaFinder(str)
  }

  new make(MavenPlugin plugin, Str name, Str mvnCmd, Bool interactiveAlways) : super(plugin)
  {
    this.name = name
    this.mavenCmd = mvnCmd
    this.interaction = interactiveAlways ? ExecCmdInteractive.always
                                          : ExecCmdInteractive.onetime
  }

  override CmdArgs defaultCmd()
  {
    return CmdArgs.makeManual(["{{env_home}}/bin/mvn", mavenCmd], "{{project_dir}}")
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
    line := str[p1+2..<c].toInt(10, false) ?: 1
    col  := str[c+1..<p2].toInt(10, false) ?: 1
    text := file.name + str[p1 .. -1]
    return FileItem.makeFile(file).setDis(text).setLoc(
          ItemLoc{it.line = line-1; it.col  = col-1}).setIcon(
          Sys.cur.theme.iconErr)
  }
}

