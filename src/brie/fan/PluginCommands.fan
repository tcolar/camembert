// History:
//  Jan 29 13 tcolar Creation
//

using fwt

**
** PluginCommands
** Implements plugin commands
**
const mixin PluginCommands
{
  ** Build the current project
  abstract Cmd? build()

  ** Build the project group (if the project is part of a parent project)
  abstract Cmd? buildGroup()

  ** Run the project
  abstract Cmd? run()

  ** Run the current file/item we are on
  abstract Cmd? runSingle()

  ** Build and run the current project
  abstract Cmd? buildAndRun()

  ** Test the current project
  abstract Cmd? test()

  ** Test the current file/item we are on
  abstract Cmd? testSingle()
}

