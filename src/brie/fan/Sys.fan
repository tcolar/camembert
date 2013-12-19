//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using concurrent
using wisp
using netColarUtils

**
** Sys manages references to system services
**
const class Sys : Service
{
  ** Logger
  static const Log log := Log.get("camembert")

  const ProjectRegistry prjReg

  ** The main options file
  const File optionsFile

  ** Shortcuts config
  const Shortcuts shortcuts

  ** Configuration options
  const Options options

  ** Theme
  const AtomicRef _theme := AtomicRef()

  const Template[] templates

  const LicenseTpl[] licenses

  ** Application level commands
  const Commands commands

  const WispService docServer

  const Unsafe pm

  ** Top-level frame (only in UI thread)
  Frame frame() { Actor.locals["frame"] ?: throw Err("Not on UI thread") }

  ProcessManager processManager() { (ProcessManager) pm.val }

  new make(|This|? f)
  {
    if(f!=null) f(this)
    options = Options.load(optionsFile)
    shortcuts =  Shortcuts.load(optionsFile.parent)
    _theme.val = Theme.load(`${optionsFile.parent}/themes/${options.theme}.props`.toFile)
    commands = Commands(this)
    prjReg = ProjectRegistry(options.srcDirs, optionsFile.parent)
    wPort := NetUtils.findAvailPort(8787)
    docServer = WispService { port = wPort; root = DocWebMod() }.start
    pm = Unsafe(ProcessManager())

    // read the templates
    tpl := Template[,]
    (optionsFile.parent + `templates/`).listFiles.each
    {
      tpl.add(JsonUtils.load(it.in, Template#))
    }
    templates = tpl.sort |a, b| {a.name <=> b.name}

    // read the licenses
    lic := LicenseTpl[,]
    (optionsFile.parent + `licenses/`).listFiles.each
    {
      lic.add(JsonUtils.load(it.in, LicenseTpl#))
    }
    licenses = lic.sort |a, b| {a.name <=> b.name}

  }

  Theme theme()
  {
    return _theme.val
  }

  override Void onStart()
  {
    PluginManager.cur.onConfigLoaded(this)
  }

  override Void onStop()
  {
    PluginManager.cur.onShutdown()

    // TODO: gotta be generalized or moved to Fantom pugin too
    if(docServer.isRunning)
    {
      docServer.stop
      docServer.uninstall
    }
    prjReg.pool.stop

    Actor.sleep(1sec)

    PluginManager.cur.onShutdown(true)
    prjReg.pool.kill

    Sys.log.info("Sys.onStop completed.")
  }

  ** Reload the *whole* config including all plugins
  static Void reloadConfig()
  {
    frame := Sys.cur.frame
    frame.spaces.each {Sys.cur.frame.closeSpace(it)}

    optionsFile := Sys.cur.optionsFile
    // Note : calling manually onStop to make sure it fully stops before we restart
    // because sys.stop calls it asynchronously
    Sys.cur.onStop

    Sys.cur.uninstall

    Sys sys := Sys
    {
      it.optionsFile = optionsFile
    }
    sys.start

    // Update theme menu
    m := (frame.menuBar as MenuBar)
    m.buildThemesMenu
    m.relayout; m.repaint

    // rescan projects after a sys chnage
    ProjectRegistry.scan

    // also update menus
    PluginManager.cur.onFrameReady(Sys.cur.frame, false)
  }

  ** All known plugins
  Str:Plugin plugins() {PluginManager.cur.plugins}

  ** Retrieve a given plugin instance by it's name
  Plugin? plugin(Str name)
  {
    return PluginManager.cur.plugins[name]
  }

  static Sys cur()
  {
    return (Sys) Service.find(Sys#)
  }

  Uri[] srcRoots() {options.srcDirs}

  static File confDir()
  {
    File.os((Env.cur.workDir + `etc/camembert/camembert.props`).readProps["configDir"])
  }
}

