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
               "camembert 1.1.8+",

               "camFantomPlugin 1.1.8+",
               "camNodePlugin 1.1.8+",
               "camMavenPlugin 1.1.8+",
               "camPythonPlugin 1.1.8+",
               "camRubyPlugin 1.1.8+",
               "camGradlePlugin 1.1.8+",
               "camGoPlugin 1.1.8+",

               "sys 1.0.64+"
               ]
    version = Version("1.1.8") // sync with camembert version
    srcDirs = [`fan/`]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://bitbucket.org/tcolar/camembert"]
  }
}