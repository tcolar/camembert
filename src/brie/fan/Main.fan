//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using concurrent

** Test main
class Main
{
  static Void main()
  {
    options := Options
    {
      indexDirs = [
        `/fan/`,
        `/sidewalk/`,
        `/skyspark/`,
        `/dev/`,
      ]
    }
    App(options).window.open
  }

}

