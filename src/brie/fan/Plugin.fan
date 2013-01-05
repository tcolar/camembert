// History:
//   11 8 12 Creation

**
** Camemebert Plugin mixin
**
mixin Plugin
{
  ** Called as soon as camembert starts up (before doing anything)
  virtual Void onInit() {}

  ** Called was a config is loaded
  ** Note that the user can possibly swap config
  virtual Void onConfigLoaded(Sys newSys) {}

  ** Called once Camembert is ready to use (frame built)
  ** Only called once
  virtual Void onFrameReady(Frame f) {}

  ** Called at the end of shutdown for cleanup purposes
  virtual Void onShutdown() {}

  ** If this plugin provides a custom space, return an instance if the file matches the space type
  virtual Space? createSpace(File file) {return null}

  ** If this plugin provides a custom space, return thempriority of this space (PosSpace is 50, Filespace is 0)
  virtual Int? spacePriority() {return null}

  ** Return an Item if the dir matches a project for the plugin
  virtual Item? projectItem(File dir, Int indent) {return null}
}

/*class PluginCommands
{
  Str? menuName
  ** Only valid / enabled for this plugin space
  Command[] spaceCommands := [,]
  ** Always available
  Command[] globalCommands := [,]
}*/

**
** Manages plugins
**
const class PluginManager : Service
{
  ** Pod name / Plugin implementation instance map
  const Str:Plugin plugins := [:]

  new make()
  {
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
    plugins.vals.each |plugin| {plugin.onInit}
  }

  internal Void onConfigLoaded(Sys newSys)
  {
    plugins.vals.each |plugin| {plugin.onConfigLoaded(newSys)}
  }

  internal Void onFrameReady(Frame f)
  {
    plugins.vals.each |plugin| {plugin.onFrameReady(f)}
  }

  internal Void onShutdown()
  {
    plugins.vals.each |plugin| {plugin.onShutdown}
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

  ** See if any plugins know of this item
  Item? itemForFile(File f)
  {
    plugins.vals.eachWhile |Plugin p -> Item?| {p.projectItem(f, 0)}
  }
}