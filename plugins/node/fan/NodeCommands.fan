// History:
//  Jan 31 13 tcolar Creation
//

using camembert
using fwt

internal const class NodeCommands : PluginCommands
{
  override const Cmd run
  override const Cmd runSingle
  override const Cmd test
  override const Cmd testSingle

  new make(NodePlugin plugin)
  {
    run         = NodeCmd(plugin, "Run", ["{{env_home}}/bin/node", "app.js"], false)
    runSingle   = NodeCmd(plugin, "RunSingle", ["{{env_home}}/bin/node", "{{cur_file}}"], true)
    test        = NodeCmd(plugin, "Test", ["{{env_home}}/bin/npm", "test"], false)
    testSingle  = NodeCmd(plugin, "TestSingle", ["{{env_home}}/bin/node", "{{cur_file}}"], true)
  }
}

internal const class NodeCmd : BasicPluginCmd
{
  override const Str name
  override const ExecCmdInteractive interaction
  override const Bool persist := true
  const Str[] args
  override const |Str -> Item?|? itemFinder := |Str str -> Item?|
  {
    return nodeFinder(str)
  }

  new make(NodePlugin plugin, Str name, Str[] args, Bool interactiveAlways) : super(plugin)
  {
    this.name = name
    this.args = args
    this.interaction = interactiveAlways ? ExecCmdInteractive.always
                                          : ExecCmdInteractive.onetime
  }

  override CmdArgs defaultCmd()
  {
    return CmdArgs.makeManual(args, "{{project_dir}}")
  }

  // at Object.<anonymous> (/home/tcolar/DEV/node/projects/server302/test/test.js:11:1)
  static const |Str -> Item?| nodeFinder := |Str str -> Item?|
  {
    if(str.size < 4) return null
    p1 := str.index("(", 4); if (p1 == null) return null
    c  := str.index(":", p1 + 1); if (c == null) return null
    p2 := str.index(")", p1); if (p2 == null) return null
    if(p1 > c || c > p2) return null
    file := File.os(str[p1+1 ..< c].trim)
    if(! file.exists) return null
    pos := str[c+1 ..< p2].split(':')
    if(pos.size != 2) return null
    line := pos[0].toInt(10, false) ?: 1
    col  := pos[1].toInt(10, false) ?: 1
    text := str
    return FileItem.makeFile(file).setDis(text).setLoc(
          ItemLoc{it.line = line-1; it.col  = col-1}).setIcon(
          Sys.cur.theme.iconErr)
  }
}


