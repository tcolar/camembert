// History:
//  Jan 30 13 tcolar Creation
//

using camembert
using gfx
using util

**
** NodePlugin
**
const class NodePlugin : BasicPlugin
{
  static const Str _name := "Node"
  override const Image icon := Image(`fan://camNodePlugin/res/node.png`)
  override Uri? defaultEnvHome() {`/usr/local/`}
  override const Str name := _name
  override PluginCommands? commands() {NodeCommands(this)}

  override Bool isProject(File dir)
  {
    if(dir.path.contains("node_modules"))
      return false
    return (dir + `package.json`).exists
  }

  override Str prjName(File prjDir)
  {
    Str? name
    json := prjDir + `package.json`
    if(json.exists)
    {
      try
      {
        data := (Str:Obj?) JsonInStream(json.in).readJson
        name = data["name"]
      }
      catch(Err e){e.trace}
    }
    return name ?: prjDir.name  // fallback
  }
}

internal const class NodeCommands : PluginCommands
{
  override const Cmd run
  override const Cmd runSingle
  override const Cmd test
  override const Cmd testSingle

  new make(NodePlugin plugin)
  {
    node := "{{env_home}}/bin/node"
    npm := "{{env_home}}/bin/npm"

    run         = BasicPluginCmd(plugin, "Run", [node, "app.js"],
                                 ExecCmdInteractive.onetime, nodeFinder)
    runSingle   = BasicPluginCmd(plugin, "RunSingle", [node, "{{cur_file}}"],
                                 ExecCmdInteractive.always, nodeFinder)
    test        = BasicPluginCmd(plugin, "Test", [npm, "test"],
                                 ExecCmdInteractive.onetime, nodeFinder)
    testSingle  = BasicPluginCmd(plugin, "TestSingle", [node, "{{cur_file}}"],
                                 ExecCmdInteractive.always, nodeFinder)
  }

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

