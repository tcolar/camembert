//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using fwt
using concurrent

**
** Application level commands
**
const class Commands
{
  new make(Sys sys)
  {
    exit        = ExitCmd{}
    reload      = ReloadCmd{key = Key(sys.shortcuts.reloadFile)}
    save        = SaveCmd{key = Key(sys.shortcuts.saveFile)}
    openFolder  = OpenFolderCmd{key = Key(sys.shortcuts.openFolder)}
    consoleToggle=ToggleConsoleCmd{key = Key(sys.shortcuts.consoleToggle)}
    recentToggle= ToggleRecentCmd{key = Key(sys.shortcuts.recentToggle)}
    docsToggle  = ToggleHelpCmd{key = Key(sys.shortcuts.docsToggle)}
    mostRecent  = MostRecentCmd{key = Key(sys.shortcuts.mostRecent)}
    prevMark    = PrevMarkCmd{key = Key(sys.shortcuts.prevMark)}
    nextMark    = NextMarkCmd{key = Key(sys.shortcuts.nextMark)}
    find        = FindCmd{key = Key(sys.shortcuts.find)}
    findInSpace = FindInSpaceCmd{key = Key(sys.shortcuts.findInSpace)}
    goto        = GotoCmd{key = Key(sys.shortcuts.goto)}
    build       = BuildCmd{key = Key(sys.shortcuts.build)}
    buildGroup  = BuildGroupCmd{key = Key(sys.shortcuts.buildGroup)}
    editConfig  = EditConfigCmd{}
    reloadConfig= ReloadConfigCmd{}
    runPod      = RunPodCmd{key = Key(sys.shortcuts.run)}
    runSingle   = RunSingleCmd{key = Key(sys.shortcuts.runSingle)}
    testPod     = TestPodCmd{key = Key(sys.shortcuts.test)}
    testSingle  = TestSingleCmd{key = Key(sys.shortcuts.testSingle)}
    buildAndRun = BuildAndRunCmd{key = Key(sys.shortcuts.buildAndRun)}
    terminate   = TerminateCmd{}
    searchDocs  = HelpCmd{key = Key(sys.shortcuts.searchDocs)}
    newFile     = NewFileCmd{key = Key(sys.shortcuts.newFile)}

    list := Cmd[,]
    typeof.fields.each |field|
    {
      if ( ! field.type.fits(Cmd#)) return
        Cmd cmd := field.get(this)
      list.add(cmd)
    }
    this.list = list
  }

  Cmd? findByKey(Key key) { list.find |cmd| { cmd.key == key } }

  const Cmd[] list
  const Cmd exit
  const Cmd reload
  const Cmd save
  const Cmd consoleToggle
  const Cmd recentToggle
  const Cmd docsToggle
  const Cmd prevMark
  const Cmd nextMark
  const Cmd find
  const Cmd findInSpace
  const Cmd goto
  const Cmd build
  const Cmd editConfig
  const Cmd reloadConfig
  const Cmd runPod
  const Cmd runSingle
  const Cmd testPod
  const Cmd testSingle
  const Cmd buildAndRun
  const Cmd buildGroup
  const Cmd terminate
  const Cmd searchDocs
  const Cmd mostRecent
  const Cmd newFile
  const Cmd openFolder
  const Cmd recent := RecentCmd {}
  const Cmd delete := DeleteFileCmd {}
  const Cmd move := MoveFileCmd {}
  const Cmd about := AboutCmd {}
}

**************************************************************************
** Cmd
**************************************************************************

const abstract class Cmd
{
  abstract Str name()

  abstract Void invoke(Event event)
  const Key? key

  //const AtomicRef sysRef := AtomicRef(null)
  Sys sys() {Sys.cur}

  Options options() { Sys.cur.options }
  Frame frame() { Sys.cur.frame }
  Console console() { frame.console }

  Command asCommand()
  {
    k := key != null ? " ($key)" : ""
    return Command("${name}$k", null, |Event e| {invoke(e)})
  }
}

internal const class EditConfigCmd : Cmd
{
  override const Str name := "Edit config"
  override Void invoke(Event event)
  {
    frame.goto(FileItem.makeFile(Sys.cur.optionsFile))
  }
  new make(|This| f) {f(this)}
}

internal const class ReloadConfigCmd : Cmd
{
  override const Str name := "Reload Config"
  override Void invoke(Event event)
  {
    Sys.loadConfig
  }
  new make(|This| f) {f(this)}
}

internal const class HelpCmd : Cmd
{
  override const Str name := "Quick search on selection"
  override Void invoke(Event event)
  {
    selection := frame.curView?.curSelection ?: ""
    frame.helpPane.render(selection)
  }
  new make(|This| f) {f(this)}
}

internal const class AboutCmd : Cmd
{
  override const Str name := "About"
  override Void invoke(Event event)
  {
    version := Pod.of(this).version.toStr
    Dialog.openInfo(frame, "Camembert is a fork of Brie.\n\nVersion:$version\n\nBy Thibaut Colar.\n\nhttp://www.status302.com/",null)
  }
  new make(|This| f) {f(this)}
}