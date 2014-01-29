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
  virtual Cmd build() {NotImplementedCmd{}}

  ** Build the project group (if the project is part of a parent project)
  virtual Cmd buildGroup() {NotImplementedCmd{}}

  ** Run the project
  virtual Cmd run() {NotImplementedCmd{}}

  ** Run the current file/item we are on
  virtual Cmd runSingle() {NotImplementedCmd{}}

  ** Build and run the current project
  virtual Cmd buildAndRun() {NotImplementedCmd{}}

  ** Build and run the current project
  virtual Cmd buildAndRunSingle() {NotImplementedCmd{}}

  ** Test the current project
  virtual Cmd test() {NotImplementedCmd{}}

  ** Test the current file/item we are on
  virtual Cmd testSingle() {NotImplementedCmd{}}
}

internal const class NotImplementedCmd : Cmd
{
  new make(|This| f) {f(this)}
  override const Str name := "NotImplemented"
  override Void invoke(Event event)
  {
    Desktop.callAsync |->|{
      Dialog.openInfo(frame, "This command is not implemented for this plugin.")
    }
  }
}

