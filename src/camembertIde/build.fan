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
    depends = [
               "camembert 1.1.6+",

               "camFantomPlugin 1.1.4+",
               "camNodePlugin 1.1.4+",
               "camMavenPlugin 1.1.3+",
               "camPythonPlugin 1.1.6+",
               "camRubyPlugin 1.1.6+",

               "sys 1.0.64+"
               ]
    version = Version("1.1.6") // sync with camembert version
    srcDirs = [`fan/`]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://bitbucket.org/tcolar/camembert"]
  }
}