// History:
//  Jan 26 13 tcolar Creation
//

**
** FantomUtils
**
class FantomUtils
{
  ** Try to find a build file of type buildPod
  ** first in dir/build.fan
  ** Then in dir/src/build.fan
  ** Then for a build pod up the directory tree but no further than upTo
  static File? findBuildPod(File? dir, File? upTo)
  {
    if(dir == null)
      return null
    build :=  dir + `build.fan`
    if(isBuildPod(build, "BuildPod"))
     return build
    build = dir + `src/build.fan`
    if(isBuildPod(build, "BuildPod"))
     return build
    while(dir!=null && dir != upTo)
    {
      build = dir + `build.fan`
      if(isBuildPod(build, "BuildPod"))
       return build
      dir = dir.parent
    }
    // not found
    return null
  }

  ** Look for a buildgroup build file
  static File? findBuildGroup(File? dir, File? upTo:=dir)
  {
    build :=  dir + `buildall.fan`
    if(dir.name!="src" && isBuildPod(build, "BuildGroup"))
     return build
    build =  dir + `build.fan`
    if(dir.name!="src" && isBuildPod(build, "BuildGroup"))
     return build
    build =  dir + `src/build.fan`
    if(isBuildPod(build, "BuildGroup"))
     return build
    build =  dir + `src/buildall.fan`
    if(isBuildPod(build, "BuildGroup"))
     return build
    while(dir!=null && dir != upTo)
    {
      build = dir + `build.fan`
      if(isBuildPod(build, "BuildGroup"))
       return build
      build = dir + `buildall.fan`
      if(isBuildPod(build, "BuildGroup"))
       return build
      dir = dir.parent
    }
    return null
  }

  private static Bool isBuildPod(File buildFile, Str type)
  {
    if(! buildFile.exists)
      return false
    try
    {
      in := buildFile.in
      Str? line
      while ((line = in.readLine) != null)
      {
        if (line.contains("class ")) break
      }
      in.close
      return line.contains(type)
    }
    catch (Err e) e.trace
    return false
  }

  ** Relying on dir being == to podName is asking for troublee from build.fan
  ** So trying to lokup the real nam
  static Str getPodName(File buildDir)
  {
    build :=  findBuildPod(buildDir, buildDir)
    if(build == null)
      return buildDir.name
    Str? name
    try
    {
      name = build.readAllLines.eachWhile |Str s -> Str?|
      {
         line := s.trim
         parts := line.split('=')
         if(parts.size != 2) return null
         val := parts[1].trim
         if(val[0]=='"' && val[-1]=='"' && val[1].isAlpha) // (might start with $ or % -> variable)
          return val[1..-2]
         return null
      }
    } catch(Err e) {e.trace}
    if(name == null)
    {
      echo("Didn't find the podName in $build.osPath - Will use $buildDir.name")
    }
    return name ?: buildDir.name
  }
}