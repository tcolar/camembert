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
    pluginManager := PluginManager()
    pluginManager.start // will call plugins init

    init

    sys := Sys{options = Options.load}
    sys.start
    Frame().open

    pluginManager.stop // will call plugins shutdown
  }

  static Void init()
  {
    // Create .fan files template
    fan := File(`${Options.standard.parent}/fan.tpl`)
    if(!fan.exists)
    {
      fan.create.out.print("// History:\n//  {date} {user} Creation\n//\n\n**\n** {name}\n**\nclass {name}\n{\n}\n").close
    }
  }
}

