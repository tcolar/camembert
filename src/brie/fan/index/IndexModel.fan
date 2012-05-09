//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 12  Brian Frank  Creation
//

using compilerDoc
using concurrent

const class PodInfo
{
  new make(Str name, TypeInfo[] types, File? srcDir, File[] srcFiles)
  {
    this.name     = name
    this.srcDir   = srcDir
    this.srcFiles = srcFiles
    this.types    = types
    types.each |t| { t.podRef.val = this }
  }

  const Str name
  override Str toStr() { name }
  const File? srcDir
  const File[] srcFiles
  const TypeInfo[] types

  override Int compare(Obj that) { name <=> ((PodInfo)that).name }
}

const class TypeInfo
{
  new make(Str name, Str file, Int line)
  {
    this.name  = name
    this.file  = file
    this.line  = line
  }

  const Str name
  const Str file
  const Int line   // zero based

  Mark? toMark()
  {
    f := pod.srcFiles.find |f| { f.name == file }
    if (f == null) return null
    return Mark(FileRes(f), line, 0, 0, qname)
  }

  Str qname() { "$pod.name::$name" }

  PodInfo pod() { podRef.val }
  internal const AtomicRef podRef := AtomicRef()

  SlotInfo[] slots() { slotsRef.val }
  internal const AtomicRef slotsRef := AtomicRef()

  override Str toStr() { name }
}

const class SlotInfo
{
  new make(TypeInfo type, Str name, Int line)
  {
    this.type = type
    this.name = name
    this.line = line
  }
  const TypeInfo type
  const Str name
  const Int line    // zero based
  override Str toStr() { name }
}

