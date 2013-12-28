// History:
//  Dec 16 13 tcolar Creation
//

using fwt
using gfx
using netColarUtils

**
** PrefWindow
** Preference panel for camembert + plugins
**
class PrefWindow
{
  Void open()
  {
    tabs := TabPane
    {
      Tab { text = "General"; InsetPane { Label{it.text="TBD"}, }, },
      Tab { text = "Shortcuts"; InsetPane { Label{it.text="TBD"}, }, },
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
    win := Window
    {
      it.title = "Camembert config"
      it.size = Size(1000, 600)
      it.content = EdgePane
      {
        center = tabs
        bottom = Button{it.text = "Save"}
      }
    }
    win.open
  }
}

** Generate Ui view for a plugin
class PluginPref : InsetPane {
  Plugin plugin

  new make(Plugin plugin) : super() {
    this.plugin = plugin

    scrollPane := ScrollPane{}
    pane := GridPane{it.numCols = 3}
    conf := PluginManager.cur.conf(plugin.name)
    if(conf != null && conf.typeof.fits(BasicConfig#))
    {
      c := conf as BasicConfig
      c.envs.each |env|
      {
        echo("--- $plugin.name - $env.name")
        env.typeof.fields.each |f|{
          facet := f.facet(Setting#) as Setting
          val := f.get(env)
          echo("$f.name ($f.type) -> $val $facet.help")
          pane.add(Label{it.text = f.name})
          pane.add(Text{it.text = val.toStr})
          pane.add(Label{it.text = facet.help[0]})
        }
      }
    }
    add(scrollPane{pane,})
  }
}

