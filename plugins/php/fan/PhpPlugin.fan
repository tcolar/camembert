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
  override Uri? defaultEnvHome() {`/usr/bin/`}
  override const Str name := _name
  override PluginCommands? commands() {cmds}

  new make()
  {
    cmds = PhpCommands()
    syntax := Pod.of(this).file(`/res/syntax-php.fog`)
    addSyntaxRule("php", syntax, ["php"])
  }

  override Bool isProject(File dir)
  {
    return isCustomPrj(dir, "Php")
  }

  override Str prjName(File prjDir)
  {
    return prjDir.name
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