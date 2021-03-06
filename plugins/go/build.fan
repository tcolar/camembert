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
    podName = "camGoPlugin"
    summary = "Go projects support plugin for camembert."
    depends = ["sys 1.0",
               "concurrent 1.0",
               "gfx 1.0",
               "fwt 1.0",
               "xml 1.0",
               "util 1.0+",
               "syntax 1.0+",
               "web 1.0+",
               "concurrent 1.0+",
               "netColarUtils 1.0.5+",
               "camembert 1.1.11+",
               ]
    version = Version("1.2.3")
    srcDirs = [`fan/`]
    resDirs = [`res/`]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://github.com/tcolar/camembert",
                "camembert.plugin" : "GoPlugin"]
    docSrc  = true
  }
}