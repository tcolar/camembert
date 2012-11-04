//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 12  Brian Frank  Creation
//

using concurrent

**
** FileUtil
**
internal const class FileUtil
{
  static Str pathDis(File file)
  {
    names := file.path.dup
    if (names.first.endsWith(":")) names.removeAt(0)
    return "/" + names.join("/")
  }

  static Bool contains(File dir, File? x)
  {
    if (x == null) return false
    return x.normalize.uri.toStr.startsWith(dir.normalize.uri.toStr)
  }

  static Uri pathIn(File dir, File x)
  {
    x.uri.toStr[dir.uri.toStr.size..-1].toUri
  }

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
  static File? findBuildGroup(File dir)
  {
    build :=  dir + `buildall.fan`
    if(isBuildPod(build, "BuildGroup"))
     return build
    build =  dir + `build.fan`
    if(isBuildPod(build, "BuildGroup"))
     return build
    build =  dir + `src/build.fan`
    if(isBuildPod(build, "BuildGroup"))
     return build
    build =  dir + `src/buildall.fan`
    if(isBuildPod(build, "BuildGroup"))
     return build
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

}