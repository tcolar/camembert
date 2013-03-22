// History:
//  Feb 27 13 tcolar Creation
//

using camembert
using gfx
using netColarUtils

**
**PythonPlugin
**
const class PythonPlugin : BasicPlugin
{
  static const Str _name := "Python"
  const PythonDocs docProv := PythonDocs()
  const PluginCommands cmds

  override const Image icon := Image(`fan://camPythonPlugin/res/python.png`)
  override const Str name := _name
  override Uri? defaultEnvHome() {`/usr/`}
  override PluginCommands? commands() {cmds}
  override PluginDocs? docProvider() {docProv}
  override Type envType() {PythonEnv#}

  ** reindex(if needed) docs upon env swicth
  override Void envSwitched(BasicConfig newConf) {docProv.reindex}

  override Bool isProject(File dir)
  {
    return dir.isDir && (dir + `__init__.py`).exists
  }

  new make()
  {
    cmds = PythonCommands(this)
  }

  override Str prjName(File prjDir)
  {
    return prjDir.name
  }

  override Void onInit(File configDir)
  {
    // create python template if not there yet
    python := configDir + `templates/python_file.json`
    if( ! python.exists)
      JsonUtils.save(python.out, Template{it.name="Python file"
        it.extensions=["py"]
        it.text="\n# History: {date} {user} Creation\n\n"})
  }
}

internal const class PythonCommands : PluginCommands
{
  override const Cmd run
  override const Cmd runSingle
  override const Cmd test
  override const Cmd testSingle

  new make(PythonPlugin plugin)
  {
    python := "{{env_home}}/bin/python"
    run         = BasicPluginCmd(plugin, "Run", [python, "{{cur_file}}"],
                                 ExecCmdInteractive.onetime, pythonFinder)
    runSingle   = BasicPluginCmd(plugin, "RunSingle", [python, "{{cur_file}}"],
                                 ExecCmdInteractive.always, pythonFinder)
    test        = BasicPluginCmd(plugin, "Test", [python, "{{cur_file}}"],
                                 ExecCmdInteractive.onetime, pythonFinder)
    testSingle  = BasicPluginCmd(plugin, "TestSingle", [python, "{{cur_file}}"],
                                 ExecCmdInteractive.always, pythonFinder)
  }

  // Python error example -> File "/home/tcolar/DEV/pyramid_env/pyramid-examples/board/board/__init__.py", line 2, in <module>
  static const |Str -> Item?| pythonFinder := |Str str -> Item?|
  {
    if(str.size < 4) return null
    str = str.trim
    if( ! str.startsWith("File \"") ) return null
    p1 := str.index("\"", 7); if (p1 == null) return null
    c  := p1+8
    p2 := str.index(",", c); if (p2 == null) return null
    file := File.os(str[6..<p1].trim)
    if(! file.exists) return null
    line := str[c..<p2].toInt(10, false) ?: 1
    return FileItem.makeFile(file).setDis(str).setLoc(
          ItemLoc{it.line = line; it.col  = 0}).setIcon(
          Sys.cur.theme.iconErr)
    return null
  }
}

