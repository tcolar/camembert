// History:
//  Jan 24 13 tcolar Creation
//

using netColarUtils
using concurrent
using camembert

**
** FantomConfig
**
@Serializable
const class FantomConfig : PluginConfig
{
  const FantomOptions options
  const FantomEnv[] envs

  const AtomicInt curEnvIndex := AtomicInt()

  new make(Sys sys)
  {
    // load fantom options
    cfgFolder := sys.optionsFile.parent
    optsFile := cfgFolder + `Fantom/options.props`
    options = (FantomOptions) JsonSettings.load(optsFile, FantomOptions#)

    // load envs
    tmp:= FantomEnv[,]
    (cfgFolder + `Fantom/`).listFiles.each
    {
      if(it.name.startsWith("env_"))
      {
        try
        {
          env := (FantomEnv) JsonSettings.load(it, FantomEnv#)
          tmp.add(env)
        }
        catch(Err e) Sys.cur.log.err("Failed to load $it.osPath !", e)
      }
    }

    if(tmp.isEmpty)
    {
      // create & add default env
      env := (FantomEnv) JsonSettings.load(cfgFolder + `Fantom/env_default.props`, FantomEnv#)
      tmp.add(env)
    }
    envs = tmp.sort |a, b| {a.order <=> b.order}

    createTemplates(cfgFolder)
  }

  ** Create the default templates if missing
  Void createTemplates(File configDir)
  {
    // Create templates if missing
    fanClass := configDir + `templates/fantom_class.json`
    if( ! fanClass.exists)
      JsonUtils.save(fanClass.out, Template{it.name="Fantom class"; it.order = 3
        it.extensions=["fan","fwt"]
        it.text="// History:\n//  {date} {user} Creation\n//\n\n**\n** {name}\n**\nclass {name}\n{\n}\n"})

    fanMixin := configDir + `templates/fantom_mixin.json`
    if( ! fanMixin.exists)
      JsonUtils.save(fanMixin.out, Template{it.name="Fantom mixin"; it.order = 13
        it.text="// History:\n//  {date} {user} Creation\n//\n\n**\n** {name}\n**\nmixin {name}\n{\n}\n"})

    fanEnum := configDir + `templates/fantom_enum.json`
    if( ! fanEnum.exists)
      JsonUtils.save(fanEnum.out, Template{it.name="Fantom enum"; it.order = 23
        it.text="// History:\n//  {date} {user} Creation\n//\n\n**\n** {name}\n**\nenum class {name}\n{\n}\n"})

    licenses := configDir + `licenses/default.json`
    if( ! licenses.exists)
      JsonUtils.save(licenses.out, LicenseTpl{it.name="default"
        it.text="// Copyright 2013 : me - Change this and create new licenses in config/licenses/\n//\n"})

  }

  FantomEnv? envByName(Str name) {envs.find {it.name == name} }

  Void selectEnv(Str name)
  {
    Int? index := envs.eachWhile |env, index -> Int?| {if(env.name == name) return index; return null}
    if(index != null)
      curEnvIndex.val = index
  }

  FantomEnv curEnv() {envs[curEnvIndex.val]}
}