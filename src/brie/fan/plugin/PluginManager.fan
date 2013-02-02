// History:
//  Jan 08 13 tcolar Creation
//

using gfx
using concurrent

**
** Manages plugins
**
const class PluginManager : Service
{
  ** Pod name / Plugin implementation instance map
  const Str:Plugin plugins := [:] {ordered = true}

  const File configDir

  ** Plugin name(pod) -> PluginConfig of each plugin
  private const AtomicRef _pluginConfs := AtomicRef()

  new make(File configDir)
  {
    this.configDir = configDir
    pods := Pod.list.findAll {it.meta.containsKey("camembert.plugin")}
    Str:Plugin temp := [:]

    // find the plugins
    pods.sort|a, b|{a.name <=> b.name}.each |pod|
    {
      typeName := pod.meta["camembert.plugin"]
      type := pod.type(typeName, false)
      if(type == null)
        Sys.log.info("Type $typeName not found for plugin $pod.name !")
      else if( ! type.fits(Plugin#))
        Sys.log.info("Type $typeName of plugin $pod.name doesn't implement Plugin mixin !")
      else
      {
        try
        {
          temp[pod.name] = (Plugin) type.make
          Sys.log.info("Found plugin : ${pod.name}.$typeName")
        }
        catch(Err e)
        {
          Sys.log.info("Failed instanciating $typeName of plugin $pod.name")
          e.trace
        }
        // Fail fast check if space doesn't have the loadSession method
        // it's too easy to forget it and then get runtime errors
        pod.types.each
        {
          if(it.fits(Space#))
            it.slot("loadSession") // will throw an Err if slot missing
        }
      }
    }
    plugins = temp
  }

  internal Void onInit()
  {
    plugins.vals.each |plugin| {plugin.onInit(configDir)}
  }

  internal Void onConfigLoaded(Sys newSys)
  {
    confs := Str:PluginConfig?[:]
    plugins.each |plugin, name|
    {
      confs[plugin.name] = plugin.readConfig(newSys)
    }
    _pluginConfs.val = confs.toImmutable
  }

  internal Void onChangedProjects(Project[] projects)
  {
    plugins.vals.each |plugin|
    {
      plugin.onChangedProjects(projects.findAll{it.plugin == plugin.typeof.pod.name})
    }
  }

  internal Void onFrameReady(Frame f, Bool initial:= true)
  {
    plugins.vals.sort|a, b|{a.name <=> b.name}.each |plugin| {plugin.onFrameReady(f, initial)}
  }

  internal Void onShutdown(Bool isKill := false)
  {
    plugins.vals.each |plugin| {plugin.onShutdown(isKill)}
  }

  override Void onStop()
  {
    onShutdown
  }

  override Void onStart()
  {
    onInit
  }

  static PluginManager cur()
  {
    return (PluginManager) Service.find(PluginManager#)
  }

  Image? iconForFile(File f)
  {
    plugins.vals.eachWhile |Plugin p -> Image?| {p.iconForFile(f)}
  }

  ** Wether any plugins are currenty indexing
  Bool anyIndexing()
  {
    if(plugins.vals.find{it.isIndexing} != null)
      return true
    return false
  }

  ** Config of a named plugin (name is pod type name)
  PluginConfig? conf(Str pluginName)
  {
    confs := ([Str:PluginConfig]?) _pluginConfs.val
    if(confs != null)
      return (PluginConfig?) confs[pluginName]
    return null
  }
}