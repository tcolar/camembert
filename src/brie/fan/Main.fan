//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using concurrent

class Main
{
  static Void main()
  {
    checkConfigFolder
    props := (Env.cur.workDir + `etc/camembert/camembert.props`).readProps
    echo("props: $props")
    configDir := File.os(props["configDir"])
    configVersion := Version(props["version"])

    pluginManager := PluginManager(configDir)
    pluginManager.start // will call plugins init

    sys := Sys{optionsFile = configDir+`options.props`}
    sys.start
    Frame().open

    pluginManager.stop // will call plugins shutdown
  }

  ** Gheck the config folder
  ** If not defined yet, then ask and create it
  static Void checkConfigFolder()
  {
    props := Env.cur.workDir + `etc/camembert/camembert.props`
    path := Text
    {
      prefCols = 60
      text = Env.cur.homeDir.parent.normalize.osPath + "/camembert/"
    }

    if( ! props.exists)
    {
      dialog := Dialog(null)
      {
        title = "Config folder"
        commands = [Dialog.ok]
        body = GridPane
        {
          Label{ text = "Please select or create a folder for the camembert configuration files :" },
          path,
        }
      }
      path.focus

      if(dialog.open != Dialog.ok)
        Env.cur.exit(-1)

      folder := File.os(path.text.trim)
      if( ! folder.exists)
        folder.parent.createDir(folder.name)
    }

    props.writeProps(["configDir" : "$path.text.trim",
                      "version" : Pod.find("camembert").version.toStr
                    ])
  }
}

