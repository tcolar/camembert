using netColarUtils

** Keyboard shortcuts configuration
@Serializable
const class Shortcuts
{
  @Setting
  const Str saveFile              := "Ctrl+S"
  @Setting
  const Str newFile               := "Ctrl+N"
  @Setting
  const Str reloadFile            := "Ctrl+R"
  @Setting
  const Str openFolder            := "Ctrl+O"

  @Setting
  const Str build                 := "F4"
  @Setting
  const Str buildGroup            := "Shift+F4"
  @Setting
  const Str run                   := "F5"
  @Setting
  const Str runSingle             := "Shift+F5"
  @Setting
  const Str buildAndRun           := "F6"
  @Setting
  const Str test                  := "F7"
  @Setting
  const Str testSingle            := "Shift+F7"

  @Setting{help = ["Escape (close console / panel)"]}
  const Str consoleToggle         := "Alt+C"

  @Setting{help = ["Insert a comment section(separator)"]}
  const Str insertCommentSection  := "Ctrl+="

  @Setting{help = ["Comment out / Uncomment line(s)"]}
  const Str toggleComment         := "Ctrl+Slash"

  const Str find                  := "Ctrl+F"

  @Setting{help = ["Find in current space"]}
  const Str findInSpace           := "Ctrl+Shift+F"

  @Setting{help = ["Goto: Find/Search for given item (pod/type/slot)"]}
  const Str goto                  := "Ctrl+G"

  @Setting{help = ["Search docs for a pod/type/slot. Opens docc pane"]}
  const Str searchDocs            := "F1"

  @Setting{help = ["Search docs for a pod/type/slot. Opens docc pane"]}
  const Str docsToggle            := "Alt+D"

  @Setting{help = ["Toggle recent files panel"]}
  const Str recentToggle          := "Alt+R"

  @Setting{help = ["Back to most recent file (Equivalent to Ctrl+1)"]}
  const Str mostRecent            := "Ctrl+Space"

  @Setting{help = ["Recent files will be mapped to Modifier + 1 .. 9"]}
  const Str recentModifier := "Ctrl"

  @Setting{help = ["Next mark (next item in console)"]}
  const Str nextMark              := "F8"

  @Setting{help = ["Previous mark"]}
  const Str prevMark              := "Shift+F8"


  ** Reload theme
  static Shortcuts load()
  {
    return (Shortcuts) SettingUtils.load(Env.cur.workDir + `etc/camenbert/shortcuts.props`, Shortcuts#)
  }

  ** Default constructor with it-block
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  @Setting { help =[
  "Other non configurable editor shortcuts:",
  "Home:        Go to line first char",
  "End:         Go to line last char",
  "Ctrl+Left:   Go to previous word",
  "Ctrl+Right:  Go to next word",
  "Ctrl+Home:   Go to document start",
  "Ctrl+End:    Go to document end",
  "Ctrl+D:      Cut whole line",
  "Tab:         Increase indentation",
  "Shift+Tab:   Decrease indentation",
  ]}
  const Str dummy := "help"
}