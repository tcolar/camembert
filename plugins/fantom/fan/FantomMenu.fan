// History:
//  Jan 25 13 tcolar Creation
//

using fwt
using camembert

**
** FantomMenu
**
class FantomMenu : Menu
{
  Menu envs

  new make(Frame frame)
  {
    text = "Fantom"

    envs = Menu
    {
      it.text = "Switch env"
    }

    first := true
    FantomPlugin.config.envs.each |env|
    {
      envs.add(MenuItem{
        it.command = SwitchConfigCmd(env.name).asCommand
        it.mode = MenuItemMode.radio
        it.selected = first
      })
      first = false
    }

    reindex := MenuItem{
        it.command = ReindexAllCmd().asCommand
    }

    add(envs)
    add(reindex)
  }
}


