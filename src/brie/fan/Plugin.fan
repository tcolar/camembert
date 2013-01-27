// History:
//   11 8 12 Creation

using gfx

**
** Camemebert Plugin mixin
**
mixin Plugin
{

  ** Called as soon as camembert starts up (before doing anything)
  virtual Void onInit(File configDir) {}

  ** Called once Camembert is ready to use (frame built)
  ** Only called once
  virtual Void onFrameReady(Frame f) {}

  ** Called at the end of shutdown for cleanup purposes
  ** Might be called twice, once a "Soft" shutdown  (isKill = false) and then a gain a hard kill (isKill = true)
  virtual Void onShutdown(Bool isKill := false) {}

  ** Return a space for the project
  abstract Space createSpace(Project project)

  ** If this plugin provides a custom space, return the priority of this space
  ** for a given project. Zero otherwise
  virtual Int spacePriority(Project project) {return 0}

  ** Return an Item if the this plugin has an icon for the file
  ** null otherwise
  virtual Image? iconForFile(File dir) {return null}

  ** Function that return a project item if the given folder
  ** is deemed a project by the plugin
  ** This function will be called a lot, so keep efficient
  abstract |File -> Project?| projectFinder

  ** Returns the setting object for the given plugin
  ** Called any time config is (re)loaded
  virtual PluginConfig? readConfig(Sys newSys) {null}
}

**
** PluginConfig
** Container for a given plugin configuration
**
mixin PluginConfig
{
}


