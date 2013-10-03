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
    podName = "camGradlePlugin"
    summary = "Gradle projects support plugin for camembert."
    depends = ["sys 1.0",
               "concurrent 1.0",
               "gfx 1.0",
               "fwt 1.0",
               "xml 1.0",
               "camembert 1.1.9+",
               "netColarUtils 1.0.5+",
               ]
    version = Version("1.1.9")
    srcDirs = [`fan/`]
    resDirs = [`res/`]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://github.com/tcolar/camembert",
                "camembert.plugin" : "GradlePlugin"]
    docSrc  = true
  }
}