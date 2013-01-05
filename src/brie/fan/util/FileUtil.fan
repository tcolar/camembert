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
const class FileUtil
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
    if(dir.uri.toStr.size >= x.uri.toStr.size)
      return ``
    return x.uri.toStr[dir.uri.toStr.size..-1].toUri
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
  static File? findBuildGroup(File? dir, File? upTo:=dir)
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

  ** Replace found items with new text
  static Void replaceAll(Item[] items, Str oldText, Str newText, Str delimiter)
  {
    // file currently worked on
    File? curFile
    //  text lines of file currently worked on
    Str[]? lines
    // Index of current line we are working on
    Int curLine
    // current offset in line (because item spans are "off" after mmultiple replaces in same line)
    offset := 0
    step := newText.size - oldText.size

    items.each |a|
    {
      if(! (a is FileItem)) return
      item := a as FileItem
      if(item.file != curFile)
      {
        if(curFile != null)
          saveLines(curFile, lines, delimiter)
        curFile = item.file
        try
          lines = curFile.readAllLines
        catch(Err e) {e.trace; lines=null}
        offset = 0
      }
      if(item.loc.span.start.line != item.loc.span.end.line)
        throw Err("Replace only supported within a single line.")
      line := item.loc.span.start.line
      if(line != curLine)
      {
        offset = 0
        curLine = line
      }
      if(lines != null)
      {
        l := lines[line]
        start :=  item.loc.span.start.col + offset
        end := item.loc.span.end.col + offset
        lines[line] = l[0 ..< start] + newText + l[end .. -1]
        offset += step
      }
    }
    // last file
    if(curFile!=null)
      saveLines(curFile, lines, delimiter)
  }

  static internal Void saveLines(File file, Str[] lines, Str delimiter)
  {
    lastLine := lines.size-1
    out := file.out
    try
    {
      lines.each |Str line, Int i|
      {
        out.print(line)
        if (i != lines.size-1 || line.isEmpty)
          out.print(delimiter)
      }
    }
    catch(Err e)
      e.trace
    finally
      out.close
  }
}