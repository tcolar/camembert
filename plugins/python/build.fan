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
    podName = "camPythonPlugin"
    summary = "Python projects support plugin for camembert."
    depends = ["sys 1.0",
               "concurrent 1.0",
               "gfx 1.0",
               "fwt 1.0",
               "util 1.0+",
               "web 1.0+",
               "concurrent 1.0+",
               "netColarUtils 1.0.6+",
               "camembert 1.1.12+",
               ]
    version = Version("1.1.12")
    srcDirs = [`fan/`]
    resDirs = [`res/`, `python/`]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://github.com/tcolar/camembert",
                "camembert.plugin" : "PythonPlugin"]
    docSrc  = true
  }
}