#! /usr/bin/env fan
//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Apr 12  Brian Frank  Creation
//

using build

**
** Top level build script
**
class Build : BuildGroup
{

//////////////////////////////////////////////////////////////////////////
// Group
//////////////////////////////////////////////////////////////////////////

  new make()
  {
    childrenScripts =
    [
      `src/bocce/build.fan`,
      `src/brie/build.fan`,
      `plugins/fantom/build.fan`,
      `plugins/maven/build.fan`,
      `plugins/node/build.fan`,
      `src/camembertIde/build.fan`,
    ]
  }

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Clean all, compile all, test all" }
  Void full()
  {
    runOnChildren("clean")
    runOnChildren("compile")
    runOnChildren("test")
  }

}