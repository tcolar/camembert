// History:
//  Feb 01 13 tcolar Creation
//

using build

**
** build
**
class build : BuildPod
{
 new make()
  {
    podName = "camembertIde"
    summary = "Metapackage for Camembert and all plugins."
    depends = ["camembert 1.1.0+",

               "camFantomPlugin 1.0.0+",
               "camNodePlugin 1.0.0+",
               "camMavenPlugin 1.0.0+",

               "sys 1.0+"
               ]
    version = Version("1.1.0") // sync with camembert version
    srcDirs = [`fan/`]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://bitbucket.org/tcolar/camembert"]
  }
}