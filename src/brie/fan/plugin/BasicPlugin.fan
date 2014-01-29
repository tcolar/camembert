// History:
//  Jan 31 13 tcolar Creation
//

using netColarUtils
using concurrent
using fwt
using gfx

**
** BasicPlugin
** Base support for simple plugins
**
abstract const class BasicPlugin : Plugin
{
  //abstract static const Str _name

  ** Icon for this plugin projects
  abstract Image icon()

  ** Method that decides whether a given dir is a project or not
  abstract Bool isProject(File dir)

  ** Returns a name for the project
  virtual Str prjName(File prjDir) {prjDir.name}

  virtual Type optionsType() {BasicOptions#}

  ** Called upon this plugin env switch
  virtual Void envSwitched(BasicConfig newConf) {}

  virtual File? findProject(File curFile)
  {
    File? f := curFile
    while(f != null && ! isProject(f))
      f = f.parent
    return f
  }

  override PluginConfig? readConfig(Sys sys)
  {
    echo("Reading config of $name $envType")
    return BasicConfig(sys, name, optionsType, envType)
  }

  override Void onFrameReady(Frame frame, Bool initial := true)
  {
    // remove if alreday in
    plugins := (frame.menuBar as MenuBar).plugins
    plugins.remove(plugins.children.find{it->text == name})

    plugins.add(BasicMenu(frame, name, this.typeof))
  }

  override const |Uri -> Project?| projectFinder:= |Uri uri -> Project?|
  {
    f := uri.toFile
    if( ! f.exists || ! f.isDir) return null
    try
    {
      if(isProject(f))
        return projectItem(f)
    }
    catch(Err e){}
    return null
  }

  virtual Project projectItem(File f)
  {
    return Project
    {
      it.dis = prjName(f)
      it.dir = f.uri
      it.icon = this.icon
      it.plugin = this.typeof.pod.name
    }
  }

  override Space createSpace(Project prj)
  {
    return BasicSpace(Sys.cur.frame, prj.dir.toFile,
      this.typeof.pod.name, prj.icon.file.uri)
  }

  override Int spacePriority(Project prj)
  {
    if(prj.plugin != this.typeof.pod.name)
      return 0
    return 50
  }

  static BasicConfig config(Str podName)
  {
    return (BasicConfig) PluginManager.cur.conf(podName)
  }
}

@Serializable
const class BasicConfig : PluginConfig
{
  const BasicOptions options
  const BasicEnv[] envs := [,]

  const AtomicInt curEnvIndex := AtomicInt()

  new make(Sys sys, Str name, Type optionsType, Type envType)
  {
    // load options
    cfgFolder := sys.optionsFile.parent
    optsFile := cfgFolder + `$name/options.props`
    options = (BasicOptions) JsonSettings.load(optsFile, optionsType)

    // load envs
    tmp:= BasicEnv[,]
    folder := cfgFolder + `$name/`
    folder.listFiles.each
    {
      if(it.name.startsWith("env_"))
      {
        try
        {
          env := (BasicEnv) JsonSettings.load(it, envType)
          tmp.add(env)
        }
        catch(Err e) Sys.log.err("Failed to load $it.osPath !", e)
      }
    }
    if(tmp.isEmpty)
    {
      env := envType.make()
      JsonSettings{}.save(env, (cfgFolder + `$name/env_default.props`).out)
      tmp.add(env)
    }
    envs = tmp.sort |a, b| {a.order <=> b.order}
  }

  BasicEnv? envByName (Str name) {envs.find {it.name == name} }

  Void selectEnv(Str name)
  {
    Int? index := envs.eachWhile |env, index -> Int?| {if(env.name == name) return index; return null}
    if(index != null)
      curEnvIndex.val = index
  }

  BasicEnv curEnv() {envs[curEnvIndex.val]}
}

// Subclasses need to be const, serializable and ususally have a |this| constructor as well
@Serializable
const class BasicEnv
{
  @Setting{help = ["Env name"]}
  const Str envName := "default"

  @Setting{help = ["Env order"]}
  const Int envOrder := 10

  virtual Int order() {envOrder}
  virtual Str name() {envName}
  virtual Uri? envHome() {return null}

  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }
}

class BasicMenu : Menu
{
  Menu envs

  new make(Frame frame, Str name, Type pluginType)
  {
    text = name

    envs = Menu
    {
      it.text = "Switch env"
    }

    first := true
    nm := pluginType.field("_name",false)?.get ?: pluginType.pod.name
    config := (BasicConfig) pluginType.method("config").call(nm)
    config.envs.each |env|
    {
      envs.add(MenuItem{
        it.command = BasicSwitchEnvCmd(env.name, pluginType).asCommand;
        it.mode = MenuItemMode.radio
        it.selected = first
      })
      first = false
    }

    add(envs)
  }
}

const class BasicSwitchEnvCmd : Cmd
{
  override const Str name
  const Type pluginType

  override Void invoke(Event event)
  {
    MenuItem mi := event.widget
    if(mi.selected)
    {
      Desktop.callAsync |->|
      {
        frame.curEnv = name
        nm := pluginType.field("_name",false)?.get ?: pluginType.pod.name
        config := (BasicConfig) pluginType.method("config").call(nm)
        config.selectEnv(name)

        // notify plugin of env switch
        plugin := PluginManager.cur.plugins[pluginType.pod.name] as BasicPlugin
        plugin.envSwitched(config)
      }
    }
  }

  new make(Str envName, Type pluginType)
  {
    this.name = envName
    this.pluginType = pluginType
  }
}

@Serializable
const class BasicOptions
{
  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }
}

class BasicSpace : FileSpaceBase
{
  override Str? plugin

  new make(Frame frame, File dir, Str plugin, Uri iconUri)
    : super(frame, dir, 220, Image(iconUri))
  {
    this.plugin = plugin
  }

  override Int match(FileItem item)
  {
    if (!FileUtil.contains(this.dir, item.file)) return 0
    // if project we don't want to open them here but in a proper space
    if (item.isProject) return 0
    return 1000 + this.dir.path.size
  }

  static Space loadSession(Frame frame, Str:Str props)
  {
    make(frame, File(props.getOrThrow("dir").toUri), props.getOrThrow("pluginName"),
         props.getOrThrow("icon").toUri)
  }

  override Str:Str saveSession()
  {
    props := ["dir": dir.uri.toStr, "icon" : icon.file.uri.toStr,
    "pluginName" : plugin]
    return props
  }
}


