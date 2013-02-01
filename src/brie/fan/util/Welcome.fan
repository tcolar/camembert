// History:
//  Feb 01 13 tcolar Creation
//
using fwt

**
** Welcome
**
class Welcome : Dialog
{
  new make() : super(null)
  {
    title = "Welcome"
    commands = [Dialog.ok]
    body = Label{
      it.text = Welcome.text
    }
  }

  static const Str text :=
"""Hello there, seems like it's your first time running Camembert.
   There is no all-in-one config wizzard at this point, if ever.

   So here are a few simple steps to get started after reading this message:
     - Once Camembert opens up go to Options / Edit config
     - Open options.props and set srcDirs to your projects workspaces then save.
       ex: srcDirs = ["/DEV/perso/","/DEV/work/", "/DEV/node/"]

   While you are in there you might want to configure the plugin environments.
   ie: edit node/env_default.props to set the node "home"

   Once done restart & Enjoy !
   """
}