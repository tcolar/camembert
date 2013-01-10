// History:
//   11 8 12 Creation

using gfx

**
** Camemebert Plugin mixin
**
mixin Plugin
{

  ** Called as soon as camembert starts up (before doing anything)
  virtual Void onInit() {}

  ** Called was a config is loaded / reloaded
  ** Note that the user can possibly swap config
  virtual Void onConfigLoaded(Sys newSys) {}

  ** Called once Camembert is ready to use (frame built)
  ** Only called once
  virtual Void onFrameReady(Frame f) {}

  ** Called at the end of shutdown for cleanup purposes
  virtual Void onShutdown() {}

  ** If this plugin provides a custom space, return an instance if the project
  ** matches this plugin space type, otherwise null
  virtual Space? createSpace(File file) {return null}

  ** If this plugin provides a custom space, return the priority of this space
  ** for a given project. Zero otherwise
  virtual Int spacePriority(File prjDir) {return 0}

  ** Return an Item if the this plugin has an icon for the file
  ** null otherwise
  virtual Image? iconForFile(File dir) {return null}

  ** Return the list of projects found in the source directories
  ** Implementation should cache this if possible.
  abstract FileItem[] projects(/*File[] srcDirs*/)
}

/*class PluginCommands
{
  Str? menuName
  ** Only valid / enabled for this plugin space
  Command[] spaceCommands := [,]
  ** Always available
  Command[] globalCommands := [,]
}*/


