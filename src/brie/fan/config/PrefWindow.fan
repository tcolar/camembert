// History:
//  Dec 16 13 tcolar Creation
//

using fwt
using gfx
using netColarUtils
using util

**
** PrefWindow
** Preference panel for camembert + plugins
**
** TODO: support multiple envs per plugin
class PrefWindow
{
  TabPane? tabs

  Void open()
  {
    tabs = TabPane
    {
      Tab { text = "General"; InsetPane { Label{it.text="TBD"}, }, },
      //Tab { text = "Run"; InsetPane { Label{it.text="TBD"}, }, },
      //Tab { text = "Shortcuts"; InsetPane { Label{it.text="TBD"}, }, },
    }
    plugins := PluginManager.cur.plugins.vals.sort|a, b|{a.name.lower<=>b.name.lower}
    plugins.each |plugin|
    {
      if(plugin.envType != null && plugin.envType.fits(BasicEnv#))
      {
        tab := Tab { it.text = plugin.name; PluginPref(plugin), }
        tabs.add(tab)
      }
    }
    Window? win
    win = Window
    {
      it.title = "Camembert config"
      it.size = Size(1000, 600)
      it.content = EdgePane
      {
        center = tabs
        bottom = Button
        {
          it.text = "Save and reload config."
          it.onAction.add |Event e| {save; win.close; Sys.reloadConfig}
        }
      }
    }
    win.open
  }

  Void save(){
    plugins := PluginManager.cur.plugins.vals.map |Plugin p, Int i-> Str| {p.name}
    cfgFolder := Sys.cur.optionsFile.parent
    tabs.tabs.each
    {
      p := it.text
      if(plugins.contains(p))
      {
        plugin := PluginManager.cur.plugins.find |v, k| {v.name == p}
        envFile := cfgFolder + `${plugin.name}/env_default.props`
        lines := envFile.readAllLines
        changed := false

        grid := it.children[0].children[0].children[0] as GridPane
        isKey := true
        Str? key
        Str? val
        grid.children.each |child|
        {
          if(isKey)
          {
            key = (child as Label).text
          }
          else
          {
            if(child.typeof.fits(EdgePane#))
            {
              val = ((child as EdgePane).top as Text).text
              idx := lines.findIndex |Str s->Bool| {s.trim.replace(" ","").startsWith("${key}=")}
              if(idx != -1)
              {
                ln := lines[idx]
                if(ln[ln.index("=")+1 .. -1].trim != val.trim)
                {
                  lines[idx] = "$key = $val"
                  changed = true
                }
              }
            }
          }
          isKey = ! isKey
        }
        if(changed)
        {
          out := envFile.out
          lines.each {out.printLine(it)}
          out.close
          echo(envFile.osPath)
        }
      }
    }
  }
}

** Generate Ui view for a plugin
class PluginPref : InsetPane {
  Plugin plugin

  new make(Plugin plugin) : super() {
    this.plugin = plugin

    scrollPane := ScrollPane{}
    pane := GridPane{it.numCols = 2; expandCol = 1; halignCells = Halign.fill}
    conf := PluginManager.cur.conf(plugin.name)
    if(conf != null && conf.typeof.fits(BasicConfig#))
    {
      c := conf as BasicConfig
      cfgFolder := Sys.cur.optionsFile.parent
      envFolder := cfgFolder + `${plugin.name}/`
      envFolder.listFiles.each |f|
      {
        if(f.name.startsWith("env_") && f.ext == "props")
        {
          pane.add(Label{it.text = "Env File:"})
          pane.add(Label{it.text = f.osPath})
          comments := ""
          f.readAllLines.each |l| {
            if(l.startsWith("#"))
            {
              comments += l
              return
            }
            if(! l.contains("="))
            {
              comments = ""
              return
            }
            // ok
            pane.add(Label{it.text = l[0..<l.index("=")].trim})
            pane.add(EdgePane{
              top=Text{it.text = l[l.index("=")+1..-1].trim}
              bottom=Label{it.text=comments}
            })
            comments = ""
          }
        }
      }
    }
    add(scrollPane{pane,})
  }
}

