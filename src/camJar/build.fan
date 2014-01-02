// History:
//  Feb 01 13 tcolar Creation
//

using build
using netColarJar

**
** Standalone jar installer/ runner for camembert
** Use "fan build.fan & fan build.fan jar" to build the standalone jar
**
class build : BuildPod
{
  new make()
  {
    podName = "camJar"
    summary = "Camembert installer standalone jar."
    depends = [
               "netColarJar 0.1.2+",
               "sys 1.0.64+"
               ]
    version = Version("1.0.0")
    srcDirs = [`fan/`]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://bitbucket.org/tcolar/camembert"]
  }

  @Target { help = "Build installer standalone jar" }
  Void jar()
  {
    BuildJar(this){
      // All standrad fantom jars + camembert installer
      pods = ["camJar"].addAll(STANDARD_PODS)
      destFile = `./dist/camLauncher.jar`.toFile.normalize
      appMain = "camJar::Main"
    }.run
  }
}


