// History:
//  Dec 17 13 tcolar Creation
//

using camembert
using gfx
using fwt
using util
using syntax
using netColarUtils

**
** Super minimal php support (juts highlighting for now)
**
const class PhpPlugin : BasicPlugin
{
  static const Str _name := "Php"

  const PhpCommands cmds
  override const Image icon := Image(`fan://camPhpPlugin/res/php.png`)
  override const Str name := _name
  override PluginCommands? commands() {cmds}
  override Type? envType() {PhpEnv#}

  new make()
  {
    cmds = PhpCommands()
    syntax := Pod.of(this).file(`/res/syntax-php.fog`)
    addSyntaxRule("php", syntax, ["php", "module"])
  }

  override Bool isProject(File dir)
  {
    return isCustomPrj(dir, "Php")
  }

  override Str prjName(File prjDir)
  {
    return prjDir.name
  }

  override Space createSpace(Project prj)
  {
    return PhpSpace(Sys.cur.frame, prj.dir.toFile, this.typeof.pod.name, icon.file.uri)
  }

  override Void onInit(File configDir)
  {
    // create Php template if not there yet
    php := configDir + `templates/php_file.json`
    if( ! php.exists)
      JsonUtils.save(php.out, Template{it.name="Php file"
        it.extensions=["php"]
        it.text="<?php\nHistory: {date} {user} Creation\n\n?>\n"})
  }
}

const class PhpCommands : PluginCommands
{
}

@Serializable
const class PhpEnv : BasicEnv
{
  override Uri? envHome() {return null}

  new make(|This|? f := null) : super(f)
  {
    if (f != null) f(this)
  }
}