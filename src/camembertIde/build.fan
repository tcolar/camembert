// History:
//  Feb 01 13 tcolar Creation
//

using build
using netColarJar

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
               "camembert 1.1.11+",

               "camFantomPlugin 1.1.9+",
               "camNodePlugin 1.1.9+",
               "camMavenPlugin 1.1.9+",
               "camPythonPlugin 1.1.9+",
               "camRubyPlugin 1.1.9+",
               "camGradlePlugin 1.1.9+",
               "camGoPlugin 1.2.1+",

               "camAxonPlugin 1.1.8+",

               "sys 1.0.64+"
               ]
    version = Version("1.1.11")
    srcDirs = [`fan/`]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://bitbucket.org/tcolar/camembert"]
  }

  @Target { help = "Build platform specific jars." }
  Void jars()
  {
    File(`./swt/`).normalize.listDirs.each |dir| {
      platform := dir.name
      BuildJar(this){
        destFile = `../../dist/camembert-${version}-${platform}.jar`.toFile.normalize
        this.log.info(destFile.osPath)
        appMain = "camembertIde::Main"
        pods = ["camembertIde", "icons"]
        extraFiles = [dir.uri + `swt.jar` : `lib/java/ext/${dir.name}/swt.jar`]
      }.run
    }
  }
}


