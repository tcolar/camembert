#! /usr/bin/env fan

using build

**
** Build: camembert
**
class Build : BuildPod
{
  new make()
  {
    podName = "camembert"
    summary = "Lightweight IDE (Get camembertIde to get all plugins too)"
    depends = ["sys 1.0.64+",
               "concurrent 1.0",
               "compiler 1.0",
               "compilerDoc 1.0",
               "fandoc 1.0",
               "syntax 1.0",
               "gfx 1.0",
               "util 1.0+",
               "fwt 1.0",
               "web 1.0",
               "wisp 1.0",
               "petanque 1.0.3+",
               "netColarUtils 1.0.8+",
               "netColarJar 0.1.2+",
               //"rhino 1.7+"
    ]
    version = Version("1.1.12")
    srcDirs = [`fan/`,
               `fan/space/`,
               `fan/view/`,
               `fan/util/`,
               `fan/command/`,
               `fan/item/`,
               `fan/widget/`,
               `fan/nav/`,
               `fan/config/`,
               `fan/plugin/`,
               `fan/project/`]
    resDirs = [`res/`, `res/themes/`]
    meta    =  ["license.name"   : "Academic License",
                "vcs.uri"   : "https://github.com/tcolar/camembert"]
    docSrc  = true
  }
}