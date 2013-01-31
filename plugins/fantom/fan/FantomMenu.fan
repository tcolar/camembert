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
      it.text = "Switch config"
    }

    FantomPlugin.config.envs.each |env|
    {
      envs.add(MenuItem{
        it.command = SwitchConfigCmd(env.name).asCommand;
        it.mode = MenuItemMode.radio
      })
    }

    add(envs)
  }
}

