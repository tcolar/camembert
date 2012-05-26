//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Apr 12  Brian Frank  Creation
//

**
** Treat in-memory string as a file
**
const class StrFile : File
{
  new make(Uri uri, Str str) : super.makeNew(uri) { this.str = str }

  const Str str
  const DateTime ts := DateTime.now

  override Bool exists() { true }
  override Int? size() { str.size }
  override DateTime? modified  { get { ts  } set { } }
  override Str? osPath() { null }
  override File? parent() { null }
  override File[] list() { File[,] }
  override File normalize() { this }
  override InStream in(Int? b := 4096) { str.in }

  override File plus(Uri pa, Bool c := true) { throw UnsupportedErr() }
  override File create() { throw UnsupportedErr() }
  override File moveTo(File t) { throw UnsupportedErr() }
  override Void delete() { throw UnsupportedErr() }
  override File deleteOnExit() { throw UnsupportedErr() }
  override Buf open(Str m := "rw") { throw UnsupportedErr() }
  override Buf mmap(Str m := "rw", Int p := 0, Int? s := null) { throw UnsupportedErr() }
  override OutStream out(Bool a := false, Int? b := 4096) { throw UnsupportedErr() }

}