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
using camembert

**
** FantomIndexCrawler
**
internal class FantomIndexCrawler
{
  new make(FantomIndex index) { this.index = index }

  const FantomIndex index

  ** Reindex all given sources / pods
  Duration reindex(File[] srcDirs, File[] podDirs)
  {
    index.setIsIndexing(true)
    try
    {
      t1 := Duration.now
      // we need to index all pods once
      if( ! index.podsIndexed.val)
      {
        podDirs.each |dir| { indexPodDir(dir) }
        index.podsIndexed.val = true
      }
      srcDirs.each |dir| { indexSrcDir(dir) }

      indexTrio(podDirs)

      t2 := Duration.now
      echo("Index all ${(t2-t1).toLocale}")
      return (t2-t1)
    }
    finally index.setIsIndexing(false)
  }

  ** Index trio func / tags if axonPlugin is avail
  ** We only do  it on indexAll and not updating on pod modif (for now)
  Void indexTrio(File[] podDirs)
  {
    axonPlugin := Sys.cur.plugins["camAxonPlugin"]
    if(axonPlugin != null)
    {
      // Dynamic call for this (no proper plugin indexing infrastructure for now)
      Str:TrioInfo info := axonPlugin->trioData(podDirs)
      index.cache.send(Msg("addTrioInfo", info))
    }
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
      indexPodSrcDir(dir, FantomUtils.getPodName(dir))
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
    return FantomUtils.findBuildGroup(dir) != null
  }

  ** Whether this is dir has a pod build file
  private Bool isPodSrcDir(File dir)
  {
    if(dir.name == "src")
      return false
    return FantomUtils.findBuildPod(dir, dir) != null
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
      // look for axon lib
      Str[] libs := [,]
      index := zip.contents[`/index.props`]
      if(index != null)
      {
        // can't use readProps because of duplicated keys sometimes !
        index.readAllLines.findAll
        {
          it.trim.startsWith("skyspark.lib") || //skyspark 1.x
          it.trim.startsWith("proj.lib") // skyspark 2.x
        }.each |line| {libs.add(line[line.index("::")+2..-1].trim )}
      }

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

        isAxonLib := libs.contains(typeName)
        type := TypeInfo(typeName, typeFile, typeLine-1, isAxonLib)
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
}

