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
  new make(Str name, File? podFile, TypeInfo[] types, File? srcDir, File[] srcFiles)
  {
    this.name       = name
    this.podFile    = podFile
    this.podFileMod = podFile?.modified
    this.types      = types
    this.srcDir     = srcDir
    this.srcFiles   = srcFiles
    types.each |t| { t.podRef.val = this }
  }

  const Str name
  override Str toStr() { name }
  const File? podFile
  const DateTime? podFileMod
  const TypeInfo[] types
  const File? srcDir
  const File[] srcFiles
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

  File? toFile() { pod.srcFiles.find |f| { f.name == file } }

  Str qname() { "$pod.name::$name" }

  PodInfo pod() { podRef.val }
  internal const AtomicRef podRef := AtomicRef()

  SlotInfo? slot(Str name) { slots.find |s| { s.name == name } }

  SlotInfo[] slots() { slotsRef.val }
  internal const AtomicRef slotsRef := AtomicRef()

  override Int compare(Obj that) { name <=> ((TypeInfo)that).name }

  override Str toStr() { name }
}

const abstract class SlotInfo
{
  new make(TypeInfo type, Str name, Int line)
  {
    this.type = type
    this.name = name
    this.line = line
  }

  Str qname() { "${type.qname}.$name" }

  const TypeInfo type
  const Str name
  const Int line    // zero based
  override Int compare(Obj that) { name <=> ((SlotInfo)that).name }
  override Str toStr() { name }
}

const class FieldInfo : SlotInfo
{
  new make(TypeInfo type, Str name, Int line) : super(type, name, line) {}
}

const class MethodInfo : SlotInfo
{
  new make(TypeInfo type, Str name, Int line) : super(type, name, line) {}
}


