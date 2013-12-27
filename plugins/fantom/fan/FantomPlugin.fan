// History:
//  Jan 05 13 tcolar Creation
//

using gfx
using netColarUtils
using fwt
using camembert

**
** FantomPlugin
** Builtin plugin for fantom features
**
const class FantomPlugin : BasicPlugin
{
  static const Str _name := "Fantom"
  override const Image icon := Image(`fan://icons/x16/database.png`)
  const FantomDocs docProv
  const FantomCommands cmds := FantomCommands()

  ** FantomIndexing service
  const FantomIndex index

  override PluginCommands? commands() {cmds}
  override PluginDocs? docProvider() {docProv}
  override Str name() {return _name}
  override Type? envType() {return FantomEnv#}

  new make()
  {
    docProv = FantomDocs(this)
    index = FantomIndex()
  }

  override Void onFrameReady(Frame frame, Bool initial := true)
  {
    super.onFrameReady(frame, initial)
    if(initial)
    {
      createTemplates(Sys.cur.optionsFile.parent)
      plugins := (frame.menuBar as MenuBar).plugins
      menu := plugins.children.find{it->text == name}
      menu.add(MenuItem{
          it.command = ReindexAllCmd().asCommand
      })
    }
  }

  override Void onChangedProjects(Project[] projects, Bool clearAll := false)
  {
    File[] srcDirs := (File[])projects.map |proj -> File| {proj.dir.toFile}
    config := PluginManager.cur.conf("Fantom") as BasicConfig
    env := config.curEnv as FantomEnv
    File[] podDirs := env.podDirs.map |uri -> File| {uri.plusSlash.toFile}

    index.reindex(srcDirs, podDirs, clearAll)
  }

  override Bool isIndexing() {index.isIndexing}

  override Bool isProject(File dir)
  {
    if(isCustomPrj(dir, "Fantom")) return true
    buildFile := FantomUtils.findBuildPod(dir, dir)
    if(buildFile != null) return true
    buildFile = FantomUtils.findBuildGroup(dir, dir)
    if(buildFile != null) return true
    return false
  }

  override Project projectItem(File f)
  {
    buildFile := FantomUtils.findBuildGroup(f, f)
    if(buildFile != null)
    {
      return Project{
        it.dis = FantomUtils.getPodName(f)
        it.dir = f.uri
        it.icon = Sys.cur.theme.iconPodGroup
        it.plugin = this.typeof.pod.name
        it.params = ["isGroup" : "true"]
      }
    }
    return Project{
      it.dis = FantomUtils.getPodName(f)
      it.dir = f.uri
      it.icon = Sys.cur.theme.iconPod
      it.plugin = this.typeof.pod.name
    }
  }

  override Space createSpace(Project prj)
  {
    return FantomSpace(Sys.cur.frame, prj.dir.toFile, null)
  }

  override Int spacePriority(Project prj)
  {
    if(prj.plugin != this.typeof.pod.name)
      return 0
    // group
    if(prj.params["isGroup"] == "true")
      return 55
    //pod
    return 50
  }

  override Image? iconForFile(File file)
  {
    if(file.isDir)
    {
      pod := index.isPodDir(file)
      if(pod != null)
        return Sys.cur.theme.iconPod
      group := index.isGroupDir(file)
      if(group != null)
        return Sys.cur.theme.iconPodGroup
    }
    // fantom files handled by standard Theme code
    return null
  }

  // Utilities
  /*static FantomConfig config()
  {
    return (FantomConfig) PluginManager.cur.conf(_name)
  }*/

  static FantomPlugin cur()
  {
    return (FantomPlugin) Sys.cur.plugin(FantomPlugin#.pod.name)
  }

  static File? findBuildFile(File? f)
  {
    return FantomUtils.findBuildPod(f.parent, null)
  }

  static File? findBuildGroup(File? f)
  {
    return FantomUtils.findBuildGroup(f.parent, null)
  }

  static Void warnNoBuildFile(Frame frame)
  {
    Dialog.openErr(frame, "No build.fan BuildPod file found")
  }

  static Void warnNoBuildGroupFile(Frame frame)
  {
    Dialog.openErr(frame, "No build.fan / buildall.fan BuildGroup file found")
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
}