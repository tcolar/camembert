#! /usr/bin/env fan
//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using build

**
** Build: brie
**
class Build : BuildPod
{
  new make()
  {
    podName = "brieOld"
    summary = "Brian's Rocking Integrated Environment"
    depends = ["sys 1.0",
               "compiler 1.0",
               "compilerDoc 1.0",
               "concurrent 1.0",
               "fandoc 1.0",
               "syntax 1.0",
               "gfx 1.0",
               "fwt 1.0",
               "bocce 1.0"]
    srcDirs = [`fan/`,
               `fan/console/`,
               `fan/index/`,
               `fan/res/`,
               `fan/view/`,
               `fan/util/`]
    docSrc  = true
  }
}