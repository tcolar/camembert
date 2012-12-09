//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 12  Brian Frank  Creation
//

using compilerDoc
using concurrent

** Group is a dir with a BuilGroup type build file
** And might contain multiple child pods (and maybe subgroups)
const class PodGroup
{
  new make(File dir, PodGroup? parent)
  {
    this.srcDir = dir
    this.name = dir.name
    this.parent = parent
  }
  const Str name
  const File srcDir
  const PodGroup? parent
}

const class PodInfo
{
  new make(Str name, File? podFile, TypeInfo[] types,
      File? srcDir, File[] srcFiles, PodGroup? group)
  {
    this.name       = name
    this.podFile    = podFile
    this.podFileMod = podFile?.modified
    this.types      = types
    this.srcDir     = srcDir
    this.srcFiles   = srcFiles
    this.groupRef.val= group
    b := false
    types.each |t|
    {
      t.podRef.val = this
      if(t.isAxonLib) b = true
    }
    this.isAxonPod = b
  }

  const Str name
  override Str toStr() { name }
  const File? podFile
  const DateTime? podFileMod
  const TypeInfo[] types
  const File? srcDir
  const File[] srcFiles
  const Bool isAxonPod // contains axon lib
  PodGroup? group() { groupRef.val }
  internal const AtomicRef groupRef := AtomicRef()
}

const class TypeInfo
{
  new make(Str name, Str file, Int line, Bool isAxonLib)
  {
    this.name  = name
    this.file  = file
    this.line  = line
    this.isAxonLib = isAxonLib
  }

  const Str name
  const Str file
  const Int line   // zero based
  const Bool isAxonLib

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

  Bool isAxonFunc() {return type.isAxonLib}

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


