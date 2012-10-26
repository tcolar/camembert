#! /usr/bin/env fan
//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Apr 12  Brian Frank  Creation
//

using build

**
** Build: bocce
**
class Build : BuildPod
{
  new make()
  {
    podName = "petanque"
    summary = "Thibaut's customized version of a branch of Brian's Open Canvas Code Editor"
    depends = ["sys 1.0",
               "concurrent 1.0",
               "fandoc 1.0",
               "syntax 1.0",
               "gfx 1.0",
               "fwt 1.0"]
    srcDirs = [`fan/`]
    docSrc  = true
  }
}