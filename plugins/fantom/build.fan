// History:
//  Jan 30 13 tcolar Creation
//
using build

**
** build
**
class build : BuildPod
{
 new make()
  {
    podName = "camFantomPlugin"
    summary = "Fantom projects support plugin for camembert."
    depends = ["sys 1.0",
               "concurrent 1.0",
               "gfx 1.0",
               "fwt 1.0",
               "compiler 1.0",
               "compilerDoc 1.0",
               "netColarUtils 1.0.5+",
               "fandoc 1.0",
               "syntax 1.0",
               "web 1.0",
               "wisp 1.0",
               "camembert 1.1.1+",
               ]
    version = Version("1.1.1")
    srcDirs = [`fan/`]
    resDirs = [,]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://bitbucket.org/tcolar/camembert",
                "camembert.plugin" : "FantomPlugin"]
    docSrc  = true
  }
}