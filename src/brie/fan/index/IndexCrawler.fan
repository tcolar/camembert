//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 12  Brian Frank  Creation
//

using compiler
using compilerDoc
using concurrent

**
** IndexCrawler
**
internal class IndexCrawler
{
  new make(Index index) { this.index = index }

  const Index index

  ** Reindex all pods
  Duration indexAll()
  {
    index.setIsIndexing(true)
    try
    {
      t1 := Duration.now
      index.podDirs.each |dir| { indexPodDir(dir) }
      index.srcDirs.each |dir| { indexSrcDir(dir) }
      t2 := Duration.now
      echo("Index all ${(t2-t1).toLocale}")
      return (t2-t1)
    }
    finally index.setIsIndexing(false)
  }

  ** Index a given pod (ie: after it's rebuilt)
  Obj? indexPod(PodInfo pod)
  {
    index.setIsIndexing(true)
    try
    {
      t1 := Duration.now
      indexPodSrcDir(pod.srcDir, pod.name)
      if(pod.podFile != null)
        indexPodLib(pod.podFile)
      t2 := Duration.now
      echo("Index pod '$pod.name' ${(t2-t1).toLocale}")
      return null
    }
    finally index.setIsIndexing(false)
  }

//////////////////////////////////////////////////////////////////////////
// Private methods
//////////////////////////////////////////////////////////////////////////


  ** Index a folder of sources as provided by the user
  private Void indexSrcDir(File dir, Str? curGroup := null)
  {
    if (!dir.isDir) return
    name := dir.name.lower
    if (name.startsWith(".")) return
    if (name == "temp" || name == "tmp" || name == "dist") return

    // if buildgroup build file
    if(isGroupSrcDir(dir))
    {
      index.cache.send(Msg("addGroup", dir, curGroup)).get
      curGroup = dir.name
    }

    // if build.fan with BuildPod
    if (isPodSrcDir(dir))
    {
      indexPodSrcDir(dir, getPodName(dir))
      //return -> no, we might have sub-pods
    }

    // recurse
    dir.listDirs.each |subDir| { indexSrcDir(subDir, curGroup) }
  }

  ** Index a folder of pods(libraries) as provided by the user
  private Void indexPodDir(File dir)
  {
    if (!dir.isDir) return
    name := dir.name.lower
    if (name.startsWith(".")) return
    if (name == "temp" || name == "tmp" || name == "dist") return

    // if lib/fan check pod files
    if (dir.pathStr.endsWith("lib/fan/"))
    {
      indexPodLibDir(dir)
      return
    }

    // recurse
    dir.listDirs.each |subDir| { indexPodDir(subDir) }
  }


  ** Whether this is dir has a roup build file
  private Bool isGroupSrcDir(File dir)
  {
    if(dir.name == "src")
      return false
    return FileUtil.findBuildGroup(dir) != null
  }

  ** Whether this is dir has a pod build file
  private Bool isPodSrcDir(File dir)
  {
    if(dir.name == "src")
      return false
    return FileUtil.findBuildPod(dir, dir) != null
  }

  ** Relying on dir being == to podName is asking for troublee from build.fan
  ** So trying to lokup the real nam
  private Str getPodName(File buildDir)
  {
    build :=  FileUtil.findBuildPod(buildDir, buildDir)
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

  ** Index the sources of a pod
  private Void indexPodSrcDir(File dir, Str podName)
  {
    files := File[,]
    indexPodSrcFiles(files, dir)
    index.cache.send(Msg("addPodSrc", podName, dir, files))
  }

  private Void indexPodSrcFiles(File[] acc, File dir)
  {
    dir.list.each |f|
    {
      if (f.isDir && ! isPodSrcDir(f)) // if it's a subpod don't deal with it in here
      {
        indexPodSrcFiles(acc, f); return
      }
      if (indexSkipExts.containsKey(f.ext ?: "")) return
      acc.add(f)
    }
  }
  private Str:Str indexSkipExts := Str:Str[:].addList(["class"])

  private Void indexPodLibDir(File dir)
  {
      dir.list.each |f| { if (f.ext == "pod") indexPodLib(f) }
  }

  ** Index a pod file
  private Void indexPodLib(File podFile)
  {
    types := TypeInfo[,]
    try
      types = fcodeReflect(podFile)
    catch (Err e)
      e.trace
    index.cache.send(Msg("addPodLib", podFile.basename, podFile, types))
  }

  private TypeInfo[] fcodeReflect(File file)
  {
    zip := Zip.open(file)
    try
    {
      // read name.defs
      namesDef := zip.contents[`/fcode/names.def`]
      if (namesDef == null) return TypeInfo[,]
      in := namesDef.in
      num := in.readU2
      names := Str[,] { capacity = num }
      for (i:=0; i<num; ++i)
        names.add(in.readUtf)
      in.close

     // read typeRefs
     typeRefs := Str[,]
     in = zip.contents[`/fcode/typeRefs.def`].in
     num = in.readU2
     for (i:=0; i<num; ++i)
     {
       podName := names[in.readU2]
       typeName := names[in.readU2]
       in.readUtf
       typeRefs.add(typeName)
     }

      // read type meta to filter synthetic versus sourced
      in = zip.contents[`/fcode/types.def`].in
      num = in.readU2
      okTypes := Str:Str[:]
      for (i:=0; i<num; ++i)
      {
        self   := typeRefs[in.readU2]
        base   := in.readU2
        mixins := in.readU2
        for (j:=0; j<mixins; ++j) in.readU2
        flags  := in.readU4
        if (flags.and(FConst.Synthetic) == 0)
          okTypes.add(self, self)
      }

      // now read each type
      types := TypeInfo[,]
      zip.contents.each |entry|
      {
        typeName := entry.basename
        if (entry.ext != "fcode") return
        if (okTypes[typeName] == null) return

        in = entry.in
        slotNames := Str[,]
        slotLines := Int[,]

        // fields
        num = in.readU2
        for (i:=0; i<num; ++i)
        {
          slotName := names[in.readU2]
          flags    := in.readU4
          type     := in.readU2
          slotLine := skipAttrs(in, names)
          if (flags.and(FConst.Synthetic) != 0) continue
          slotNames.add(slotName)
          slotLines.add(slotLine)
        }
        methodStartIndex := slotNames.size

        // methods
        num = in.readU2
        for (i:=0; i<num; ++i)
        {
          slotName    := names[in.readU2]
          flags       := in.readU4
          retType     := in.readU2
          inheritType := in.readU2
          maxStack    := in.readU1
          varCount    := in.readU1 + in.readU1
          for (j:=0; j<varCount; ++j)
          {
            varName  := in.readU2
            varType  := in.readU2
            varFlags := in.readU1
            skipAttrs(in, names)
          }
          codeLen := in.readU2
          in.skip(codeLen)
          slotLine := skipAttrs(in, names)
          if (flags.and(FConst.Synthetic) != 0) continue
          slotNames.add(slotName)
          slotLines.add(slotLine)
        }

        // attrs
        num = in.readU2
        typeFile := ""
        typeLine := 0
        for (i:=0; i<num; ++i)
        {
          attrName := names[in.readU2]
          len := in.readU2
          if (attrName == "LineNumber") typeLine= in.readU2
          else if (attrName == "SourceFile") typeFile = in.readUtf
          else in.skip(len)
        }
        in.close

        type := TypeInfo(typeName, typeFile, typeLine-1)
        slots := SlotInfo[,] { capacity = slotNames.size }
        slotNames.each |slotName, i|
        {
          if (i >= methodStartIndex)
            slots.add(MethodInfo(type, slotName, slotLines[i]-1))
          else
            slots.add(FieldInfo(type, slotName, slotLines[i]-1))
        }
        type.slotsRef.val = slots.sort.toImmutable
        types.add(type)
      }

      return types.sort
    }
    finally zip.close
  }

  private Int skipAttrs(InStream in, Str[] names)
  {
    lineNum := 0
    num := in.readU2
    for (i:=0; i<num; ++i)
    {
      name := names[in.readU2]
      len  := in.readU2
      if (name == "LineNumber")
        lineNum = in.readU2
      else
        in.skip(len)
    }
    return lineNum
  }

/*
  Bool include(File f)
  {
    if (f.isDir) return true
    ext := f.ext
    if (ext == null) return true
    if (ext == "class" || ext == "exe") return false
    return true
  }

*/
}

