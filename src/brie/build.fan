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
    summary = "Thibaut's customized version of a fork of Brian's Rocking Integrated Environment"
    depends = ["sys 1.0",
               "compiler 1.0",
               "compilerDoc 1.0",
               "concurrent 1.0",
               "fandoc 1.0",
               "syntax 1.0",
               "gfx 1.0",
               "fwt 1.0",
               "petanque 1.0",
               "netColarUtils 0.0.1+"
    ]
    srcDirs = [`fan/`,
               `fan/space/`,
               `fan/view/`,
               `fan/index/`,
               `fan/util/`,
                `fan/command/`]
    resDirs = [`res/`]
    docSrc  = true
  }
}