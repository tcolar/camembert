// History:
//  Jan 08 13 tcolar Creation
//

using gfx

**
** Manages plugins
**
const class PluginManager : Service
{
  ** Pod name / Plugin implementation instance map
  const Str:Plugin plugins := [:]

  const File configDir

  ** Plugin name(pod) -> PluginConfig of each plugin
  private const Unsafe? _pluginConfs

  new make(File configDir)
  {
    this.configDir = configDir
    pods := Pod.list.findAll {it.meta.containsKey("camembert.plugin")}
    Str:Plugin temp := ["camFantomPlugin": (Plugin)FantomPlugin()]
    pods.each |pod|
    {
      typeName := pod.meta["camembert.plugin"]
      type := pod.type(typeName, false)
      if(type == null)
        echo("Type $typeName not found for plugin $pod.name !")
      else if( ! type.fits(Plugin#))
        echo("Type $typeName of plugin $pod.name doesn't implement Plugin mixin !")
      else
      {
        try
        {
          temp[pod.name] = (Plugin) type.make
          echo("Found plugin : ${pod.name}.$typeName")
        }
        catch(Err e)
        {
          echo("Failed instanciating $typeName of plugin $pod.name")
          e.trace
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
    confs := (Str:PluginConfig?) _pluginConfs?.val
    if(confs == null)
      confs = Str:PluginConfig?[:]
    plugins.each |plugin, name|
    {
      confs[name] = plugin.readConfig(newSys)
    }
    _pluginConfs.val = Unsafe(confs)
  }

  internal Void onFrameReady(Frame f)
  {
    plugins.vals.each |plugin| {plugin.onFrameReady(f)}
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

  internal static PluginManager cur()
  {
    return (PluginManager) Service.find(PluginManager#)
  }

  Image? iconForFile(File f)
  {
    plugins.vals.eachWhile |Plugin p -> Image?| {p.iconForFile(f)}
  }

  FantomConfig? conf(Str pluginName)
  {
    confs := (Str:PluginConfig?) _pluginConfs.val
    if(confs != null)
      return (FantomConfig?) confs[pluginName]
    return null
  }
}