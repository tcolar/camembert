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

  Duration indexAll()
  {
    index.setIsIndexing(true)
    try
    {
      t1 := Duration.now
      index.dirs.each |dir| { indexDir(dir) }
      t2 := Duration.now
      echo("Index all ${(t2-t1).toLocale}")
      return (t2-t1)
    }
    finally index.setIsIndexing(false)
  }

  Obj? indexPod(PodInfo pod)
  {
    index.setIsIndexing(true)
    try
    {
      t1 := Duration.now
      indexPodSrcDir(pod.srcDir)
      indexPodLib(pod.podFile)
      t2 := Duration.now
      echo("Index pod '$pod.name' ${(t2-t1).toLocale}")
      return null
    }
    finally index.setIsIndexing(false)
  }

  private Void indexDir(File dir)
  {
    // skip these
    if (!dir.isDir) return
    name := dir.name.lower
    if (name.startsWith(".")) return
    if (name == "temp" || name == "tmp" || name == "dist") return

    // if lib/fan check pod files
    if (dir.pathStr.endsWith("lib/fan/")) { indexPodLibDir(dir); return }

    // if build.fan with BuildPod
    if (isPodSrcDir(dir)) { indexPodSrcDir(dir); return }

    // recurse
    dir.listDirs.each |subDir| { indexDir(subDir) }
  }

  private Bool isPodSrcDir(File dir)
  {
    build :=  dir + `build.fan`
    if (!build.exists) return false

    try
    {
      in := build.in
      Str? line
      while ((line = in.readLine) != null)
      {
        if (line.contains("class ")) break
      }
      in.close
      return line.contains("BuildPod")
    }
    catch (Err e) e.trace
    return false
  }

  private Void indexPodSrcDir(File dir)
  {
    files := File[,]
    indexPodSrcFiles(files, dir)
    index.cache.send(Msg("addPodSrc", dir.name, dir, files))
  }

  private Void indexPodSrcFiles(File[] acc, File dir)
  {
    dir.list.each |f|
    {
      if (f.isDir) { indexPodSrcFiles(acc, f); return }
      if (indexExts.containsKey(f.ext ?: "")) acc.add(f)
    }
  }
  private Str:Str indexExts := Str:Str[:].addList(["fan", "props", "fandoc", "css", "js", "java", "cs", "txt"])

  private Void indexPodLibDir(File dir)
  {
    dir.list.each |f| { if (f.ext == "pod") indexPodLib(f) }
  }

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

  Int skipAttrs(InStream in, Str[] names)
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

