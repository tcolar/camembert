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
    summary = "Pure Fantom lightweight IDE - Forked and fermented version of Brie (Brian's Rocking Integrated Environment)"
    depends = ["sys 1.0",
               "compiler 1.0",
               "compilerDoc 1.0",
               "concurrent 1.0",
               "fandoc 1.0",
               "syntax 1.0",
               "gfx 1.0",
               "fwt 1.0",
               "petanque 1.0.1+",
               "netColarUtils 1.0.0+"
    ]
    srcDirs = [`fan/`,
               `fan/space/`,
               `fan/view/`,
               `fan/index/`,
               `fan/util/`,
               `fan/command/`,
               `fan/widget/`]
    resDirs = [`res/`]
    version = Version("1.0.8")
    meta    =  ["license.name"   : "Academic License",
                "vcs.uri"   : "https://bitbucket.org/tcolar/camembert"]
    docSrc  = true
  }
}