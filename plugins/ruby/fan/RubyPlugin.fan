// History:
//  Feb 27 13 tcolar Creation
//

using camembert
using gfx
using netColarUtils

**
** RubyPlugin
**
const class RubyPlugin : BasicPlugin
{
  static const Str _name := "Ruby"
  const RubyDocs docProv := RubyDocs()
  const PluginCommands cmds

  override const Image icon := Image(`fan://camRubyPlugin/res/ruby.png`)
  override const Str name := _name
  override Uri? defaultEnvHome() {`/usr/`}
  override PluginCommands? commands() {cmds}
  override PluginDocs? docProvider() {docProv}
  override Type envType() {RubyEnv#}

  override Bool isProject(File dir)
  {
    if(isCustomPrj(dir, "Ruby")) return true
    return dir.isDir && (dir + `Rakefile`).exists
  }

  new make()
  {
    cmds = RubyCommands(this)
  }

  override Str prjName(File prjDir)
  {
    // TODO : get project name from RakeFile or rails spec ??
    return prjDir.name
  }

  override Void onInit(File configDir)
  {
    // create ruby template if not there yet
    ruby := configDir + `templates/ruby_file.json`
    if( ! ruby.exists)
      JsonUtils.save(ruby.out, Template{it.name="Ruby file"
        it.extensions=["rb"]
        it.text="\n# History: {date} {user} Creation\n\nclass {{name}}\n#TODO\nend\n"})
  }
}

internal const class RubyCommands : PluginCommands
{
  override const Cmd run
  override const Cmd runSingle
  override const Cmd test
  override const Cmd testSingle

  new make(RubyPlugin plugin)
  {
    ruby := "{{env_home}}/bin/ruby"
    run         = BasicPluginCmd(plugin, "Run", [ruby, "{{cur_file}}"],
                                 ExecCmdInteractive.onetime, rubyFinder)
    runSingle   = BasicPluginCmd(plugin, "RunSingle", [ruby, "{{cur_file}}"],
                                 ExecCmdInteractive.always, rubyFinder)
    test        = BasicPluginCmd(plugin, "Test", [ruby, "{{cur_file}}"],
                                 ExecCmdInteractive.onetime, rubyFinder)
    testSingle  = BasicPluginCmd(plugin, "TestSingle", [ruby, "{{cur_file}}"],
                                 ExecCmdInteractive.always, rubyFinder)
  }

  // Ruby error example -> /home/tcolar/DEV/hello-0.0.1/lib/hello.rb:44: syntax error, unexpected ':', expecting '}'
  static const |Str -> Item?| rubyFinder := |Str str -> Item?|
  {
    if(str.size < 1) return null
    str = str.trim
    p1 := str.index(":"); if (p1 == null) return null
    p2 := str.index(":", p1 + 1); if (p2 == null) return null
    line := str[p1+1..<p2].toInt(10, false)
    if(line == null) return null
    file := File.os(str[0..<p1].trim)
    if(! file.exists) return null
    return FileItem.makeFile(file).setDis(str).setLoc(
          ItemLoc{it.line = line - 1; it.col  = 0}).setIcon(
          Sys.cur.theme.iconErr)
    return null
  }
}

