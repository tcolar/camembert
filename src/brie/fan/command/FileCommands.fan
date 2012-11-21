using fwt
using netColarUtils

**************************************************************************
** ExitCmd
**************************************************************************

internal const class ExitCmd : Cmd
{
  override const Str name := "Exit"

  override Void invoke(Event event)
  {
    r := Dialog.openQuestion(frame, "Exit application?", null, Dialog.okCancel)
    if (r != Dialog.ok)
      return
    frame.saveSession
    Env.cur.exit(0)
  }
  new make(|This| f) {f(this)}
}
**************************************************************************
** ReloadCmd
**************************************************************************

internal const class ReloadCmd : Cmd
{
  override const Str name := "Reload"
  override Void invoke(Event event) { frame.reload }
  new make(|This| f) {f(this)}
}

**************************************************************************
** SaveCmd
**************************************************************************

internal const class SaveCmd : Cmd
{
  override const Str name := "Save"
  override Void invoke(Event event) { frame.save }
  new make(|This| f) {f(this)}
}

**************************************************************************
** New file
**************************************************************************

internal const class NewFileCmd : Cmd
{
  override const Str name := "New File"
  override Void invoke(Event event)
  {
    newFile(frame.curFile?.parent, frame)
  }

  Void newFile(File? dir, Frame frame)
  {
    clazz := File(`${Options.standard.parent}/class.tpl`)
    if(!clazz.exists)
    {
      clazz.create.out.print("// History:\n//   {date} Creation\n\n**\n** {name}\n**\nclass {name}\n{\n}\n").close
    }

    Str:Str tpls := [:] {ordered = true}
    Options.standard.parent.listFiles.findAll |file->Bool|
      {return file.ext == "tpl"}
      .each{tpls[it.basename] = it.readAllStr
    }
    tpls["Empty File"] = ""

    ok := Dialog.ok
    cancel := Dialog.cancel
    name := Text {text = "newfile.fan"; prefCols = 60}
    path := Text
    {
      prefCols = 60
      text = (dir?.osPath ?: Env.cur.workDir.osPath) + "/"
    }

    combo := Combo
    {
      items = tpls.keys
    }

    dialog := Dialog(frame)
    {
      title = "New File"
      commands = [ok, cancel]
      body = GridPane
      {
        Label{ text = "New File Name:" },
        name,
        Label{ text = "Folder: (Any new folders will get created automatically)" },
        path,
        Label{ text = "Template:" },
        combo,
      }
    }
    name.focus

    // open dialog
    if (dialog.open != Dialog.ok) return

    FileUtils.mkDirs(path.text.toUri)

    f := File.os(path.text).createFile(name.text)

    text := tpls[combo.selected]
      .replace("{date}", DateTime.now.toLocale("M D YY"))
      .replace("{name}", f.basename)

    f.out.print(text).close

    frame.goto(Item(f))

    // TODO: contextual create file (from nav item)
  }
  new make(|This| f) {f(this)}
}

internal const class OpenFolderCmd : Cmd
{
  override const Str name := "OpenFolder"
  override Void invoke(Event event)
  {
    File? f := FileDialog
    {
      mode = FileDialogMode.openDir
    }.open(frame)

    if(f!=null)
      frame.goto(Item(f))
  }
  new make(|This| f) {f(this)}
}

