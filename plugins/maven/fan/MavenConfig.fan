// History:
//  Jan 30 13 tcolar Creation
//

using netColarUtils
using concurrent
using camembert

**
** MavenConfig
**
@Serializable
const class MavenConfig : PluginConfig
{
  const MavenOptions options
  const MavenEnv[] envs

  const AtomicInt curEnvIndex := AtomicInt()

  new make(Sys sys)
  {
    // load options
    cfgFolder := sys.optionsFile.parent
    optsFile := cfgFolder + `maven/options.props`
    options = (MavenOptions) JsonSettings.load(optsFile, MavenOptions#)

    // load envs
    tmp:= MavenEnv[,]
    (cfgFolder + `maven/`).listFiles.each
    {
      if(it.name.startsWith("env_"))
      {
        try
        {
          env := (MavenEnv) JsonSettings.load(it, MavenEnv#)
          tmp.add(env)
        }
        catch(Err e) Sys.cur.log.err("Failed to load $it.osPath !", e)
      }
    }

    if(tmp.isEmpty)
    {
      // create & add default env
      env := (MavenEnv) JsonSettings.load(cfgFolder + `maven/env_default.props`, MavenEnv#)
      tmp.add(env)
    }
    envs = tmp.sort |a, b| {a.order <=> b.order}

  }

  MavenEnv? envByName(Str name) {envs.find {it.name == name} }

  Void selectEnv(Str name)
  {
    Int? index := envs.eachWhile |env, index -> Int?| {if(env.name == name) return index; return null}
    if(index != null)
      curEnvIndex.val = index
  }

  MavenEnv curEnv() {envs[curEnvIndex.val]}
}