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
               "camembert 1.1.11+",

               "camFantomPlugin 1.1.9+",
               "camNodePlugin 1.1.9+",
               "camMavenPlugin 1.1.9+",
               "camPythonPlugin 1.1.9+",
               "camRubyPlugin 1.1.9+",
               "camGradlePlugin 1.1.9+",
               "camGoPlugin 1.2.1+",

               "sys 1.0.64+"
               ]
    version = Version("1.1.11")
    srcDirs = [`fan/`]
    meta    = ["license.name" : "MIT",
                "vcs.uri"   : "https://bitbucket.org/tcolar/camembert"]
  }

  /*@Target { help = "" }
  Void distJars()
  {
    dist := JarDist(this)
    dist.outFile = `../../dist/camembert-${version}.jar`.toFile.normalize
    dist.podNames = Str["inet", "web", "concurrent", "util", "compiler", "compilerDoc",
      "fandoc", "fanr", "syntax", "gfx", "fwt", "wisp", "xml",
      "netColarUtils",
      "petanque",
      "camembert", "camembertIde", "camFantomPlugin","camNodePlugin","camMavenPlugin",
      "camPythonPlugin", "camRubyPlugin", "camGradlePlugin", "camGoPlugin"]
    dist.mainMethod = "camembertIde::Main.main"
    dist.run
  }*/
}